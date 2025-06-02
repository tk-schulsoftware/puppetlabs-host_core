require 'puppet/property/ordered_list'
require 'ipaddr'

Puppet::Type.newtype(:hostentry) do
  @doc = "@summary Installs and manages host entries.

      For most systems, these entries will just be in `/etc/hosts`, but some
      systems (notably OS X) will have different solutions."

  ensurable

  newproperty(:ip) do
    desc "The host's IP address, IPv4 or IPv6."

    def valid_v4?(addr)
      ip = IPAddr.new(addr)
      ip.ipv4?
    rescue IPAddr::InvalidAddressError
      false
    end

    def valid_v6?(addr)
      ip = IPAddr.new(addr)
      ip.ipv6?
    rescue IPAddr::InvalidAddressError
      false
    end

    validate do |value|
      return true if valid_v4?(value) || valid_v6?(value)
      raise Puppet::Error, _('Invalid IP address %{value}') % { value: value.inspect }
    end
  end

  newproperty(:host_aliases) do
    desc "Any aliases the host might have.  Multiple values must be
        specified as an array."

    def value
      @value ||= []
    end

    def value=(val)
      @value = Array(val)
    end

    validate do |value|
      raise Puppet::Error, _('Host aliases cannot include whitespace') if %r{\s}.match?(value)
      raise Puppet::Error, _('Host aliases cannot include newline') if value.include?("\n") || value.include?("\r")
      raise Puppet::Error, _('Host aliases cannot be an empty string. Use an empty array to delete all host_aliases') if %r{^\s*$}.match?(value)
    end
  end

  newproperty(:comment) do
    desc 'A comment that will be attached to the line with a # character.'
    validate do |value|
      if value.include?("\n") || value.include?("\r")
        raise Puppet::Error, _('Comment cannot include newline')
      end
    end
  end

  newproperty(:target) do
    desc "The file in which to store service information. Only used by
        those providers that write to disk. On most systems this defaults to `/etc/hosts`."

    defaultto '/etc/hosts'

    validate do |value|
      raise ArgumentError, 'The target must be a string' unless value.is_a?(String)
      raise ArgumentError, 'The target must be an absolute path' unless Puppet::Util.absolute_path?(value)    
    end
  end

  newparam(:name) do
    desc 'An internal unique title for the host entry.'
    isnamevar
  end

  newparam(:name_as_host) do
    desc "Add the resource name as a host alias."
    newvalues(:true, :false)
    defaultto :true
  end
end
