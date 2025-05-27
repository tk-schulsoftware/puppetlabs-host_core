require 'ipaddr'

Puppet::Type.type(:host).provide(:custom) do
  desc "Custom provider to manage host entries in target"

  def exists?
    target = resource[:target]
    if !File.exist?(target)
      return false
    end

    if !ip_exists?
      return false
    end

    resource_ip = resource[:ip]

    get_all_hosts.each do |host|
      if !host_exists?(host)
        return false
      end
      ips_from_host = get_host_ips(host)
      ips_from_host.each do |ip_from_host|
        if same_ip_version?(resource_ip, ip_from_host)
          if !ip_equal?(resource_ip, ip_from_host)
            return false
          else
            if !has_comment?(host, resource_ip)
              return false
            end
          end
        end
      end
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
        if ip_equal?(tokens.first, desired_ip)
          return true
        end
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
    end  
    return false
  end

  def get_host_ips(host)
    target = resource[:target]
    ips = []

    File.foreach(target) do |line|
      line = line.strip

      if !(line.empty? || line.start_with?('#'))
        line = line.split('#').first.strip
        tokens = line.split(/\s+/)

        if tokens.include?(host)
          ips << tokens.first
        end
      end
    end

    ips.uniq
  end

  def same_ip_version?(ip1, ip2)
    begin
      ip1_obj = IPAddr.new(ip1)
      ip2_obj = IPAddr.new(ip2)
      return ip1_obj.ipv4? == ip2_obj.ipv4?
    rescue IPAddr::InvalidAddressError
      return false
    end
  end

  def get_comment
    if resource[:name_as_host]
      return resource[:comment]
    else
      return resource[:name] + " - " + resource[:comment]
    end
  end

  def has_comment?(host, ip)
    expected_comment = get_comment&.strip
    return true if expected_comment.nil? || expected_comment.empty?

    target = resource[:target]

    File.foreach(target) do |line|
      stripped_line = line.strip
      next if stripped_line.empty? || stripped_line.start_with?('#')

      content, comment = stripped_line.split('#', 2).map(&:strip)
      tokens = content.split(/\s+/)

      # Wenn IP und Host in der Zeile sind
      if tokens.include?(host) && ip_equal?(tokens.first, ip)
        return comment.gsub(/\s+/, '') == expected_comment.gsub(/\s+/, '')
      end
    end

    return false
  end
end