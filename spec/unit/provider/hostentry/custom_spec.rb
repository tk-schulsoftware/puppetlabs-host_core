require 'spec_helper'

describe Puppet::Type.type(:hostentry).provider(:custom) do
  let(:resource) do
    Puppet::Type.type(:hostentry).new(
      name: 'test.local',
      ip: '192.168.1.100',
      host_aliases: ['alias1', 'alias2'],
      comment: 'Testeintrag',
      provider: described_class.name
    )
  end

  let(:provider) { resource.provider }

  let(:hosts_path) { '/etc/hosts' }

  before :each do
    allow(File).to receive(:readlines).with(hosts_path).and_return(existing_lines)
    allow(File).to receive(:write)
    allow(File).to receive(:open).with(hosts_path, 'a')
  end

  context 'when host does not exist' do
    let(:existing_lines) { ["127.0.0.1 localhost\n"] }

    it 'does not find the host' do
      expect(provider.exists?).to be false
    end

    it 'adds a new host entry' do
      file = double('file')
      expect(File).to receive(:open).with(hosts_path, 'a').and_yield(file)
      expect(file).to receive(:puts).with("192.168.1.100 test.local alias1 alias2 # Testeintrag")

      provider.create
    end
  end

  context 'when host exists' do
    let(:existing_lines) { ["192.168.1.100 test.local alias1 alias2 # Testeintrag\n"] }

    it 'finds the host' do
      expect(provider.exists?).to be true
    end

    it 'removes the host entry' do
      expect(File).to receive(:write).with(hosts_path, "127.0.0.1 localhost\n")

      allow(File).to receive(:readlines).with(hosts_path).and_return(
        ["192.168.1.100 test.local alias1 alias2 # Testeintrag\n", "127.0.0.1 localhost\n"]
      )
      provider.destroy
    end

    it 'returns the correct IP' do
      expect(provider.ip).to eq('192.168.1.100')
    end

    it 'updates the IP' do
      allow(File).to receive(:readlines).with(hosts_path).and_return(
        ["192.168.1.100 test.local alias1 alias2 # Testeintrag\n"]
      )
      expect(File).to receive(:write).with(
        hosts_path,
        "192.168.1.200 test.local alias1 alias2 # Testeintrag\n"
      )
      provider.ip = '192.168.1.200'
    end
  end
end
