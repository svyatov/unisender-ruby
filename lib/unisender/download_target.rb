# frozen_string_literal: true

require "ipaddr"
require "socket"
require "timeout"

module Unisender
  # Resolves once and returns a public address for a verified HTTPS connection.
  class DownloadTarget
    BLOCKED = %w[
      0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12
      192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24
      224.0.0.0/4 240.0.0.0/4 ::/128 ::1/128 fc00::/7 fe80::/10 ff00::/8 2001:db8::/32
    ].map { |range| IPAddr.new(range) }.freeze

    def initialize(timeout:, resolver: nil)
      @timeout = timeout
      @resolver = resolver || ->(host) { Addrinfo.getaddrinfo(host, 443, nil, :STREAM).map(&:ip_address).uniq }
    end

    def resolve(url)
      uri = validated_uri(url)
      addresses = resolved_addresses(uri.hostname.to_s)
      [uri, addresses.fetch(0)]
    rescue URI::InvalidURIError, IPAddr::InvalidAddressError
      raise DownloadError.new(reason: :invalid_url), cause: nil
    end

    private

    def validated_uri(url)
      uri = URI(url)
      unless uri.scheme == "https" && uri.port == 443 && uri.hostname && !uri.userinfo
        raise DownloadError.new(reason: :invalid_url)
      end

      uri
    end

    def resolved_addresses(host)
      addresses = Timeout.timeout(@timeout) { @resolver.call(host) }
      if addresses.empty? || addresses.any? { |address| blocked?(address) }
        raise DownloadError.new(reason: :blocked_destination)
      end

      addresses
    end

    def blocked?(address)
      ip = IPAddr.new(address).native
      BLOCKED.any? { |range| range.include?(ip) }
    end
  end
end
