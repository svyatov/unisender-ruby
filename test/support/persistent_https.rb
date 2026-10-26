# frozen_string_literal: true

require_relative "local_https"

class PersistentHTTPS < LocalHTTPS
  attr_reader :connections

  def initialize(requests:, keep_alive:, fail_at: nil)
    @remaining = requests
    @keep_alive = keep_alive
    @fail_at = fail_at
    @received = 0
    @connections = 0
    super()
  end

  private

  def start(key, cert)
    context = OpenSSL::SSL::SSLContext.new
    context.cert = cert
    context.key = key
    server = OpenSSL::SSL::SSLServer.new(@listener, context)
    @worker = Thread.new { accept_requests(server) }
  end

  def accept_requests(server)
    while @remaining.positive?
      socket = server.accept
      @connections += 1
      serve(socket)
    end
  end

  def serve(socket)
    while @remaining.positive?
      lines = read_headers(socket)
      break if lines.empty?

      record_request(socket, lines)
      break if @received == @fail_at

      break unless reply(socket, @keep_alive && @remaining.positive?)
    end
  ensure
    socket.close
  end

  def record_request(socket, lines)
    length = lines.grep(/Content-Length:/i).first.split(":", 2).last.to_i
    @requests << [lines.first, socket.read(length)]
    @received += 1
    @remaining -= 1
  end

  def read_headers(socket)
    lines = []
    while (line = socket.gets)
      lines << line
      break if line == "\r\n"
    end
    lines
  end

  def reply(socket, keep)
    body = '{"result":[]}'
    connection = keep ? "keep-alive" : "close"
    socket.write("HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\nConnection: #{connection}\r\n\r\n#{body}")
    keep
  end
end
