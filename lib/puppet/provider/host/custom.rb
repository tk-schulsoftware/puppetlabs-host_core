require 'ipaddr'

Puppet::Type.type(:host).provide(:custom) do
  desc "Custom provider to manage host entries in target"

  def exists?
    target = resource[:target]
    if !File.exist?(target)
      return false

    if !ip_exists?
      return false

    get_all_hosts.each do |host|
      if !host_exists?(host)
        return false
    end

    return true
  end

  def create
    # Eintrag anlegen
  end

  def destroy
    # Eintrag löschen
  end

  def ip_equal?(ip1, ip2)
    IPAddr.new(ip1).to_s == IPAddr.new(ip2).to_s
  end

  def ip_exists?
    target = resource[:target]
    desired_ip = resource[:ip]

    File.foreach(target) do |line|
      line = line.strip
      if !line.empty? && !line.start_with?('#')
        tokens = line.split(/\s+/)
        if ip_equal?(tokens.first, ip)
          return true
        end
    end
    return false
  end

  def get_all_hosts
    if resource[:name_as_host]
      return [resource[:name]] + resource[:host_aliases]
    else
      return resource[:host_aliases]
    end
  end

  def host_exists?(host)
    target = resource[:target]
    File.foreach(target) do |line|
      line = line.strip
      line = line.split('#').first.strip
      if !line.empty?
        tokens = line.split(/\s+/)
        if tokens.include?(host)
          return true
        end
    end
  
    return false
  end
end