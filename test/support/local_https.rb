# frozen_string_literal: true

require "openssl"
require "socket"

# A single-request TLS server with a locally trusted, ephemeral certificate.
class LocalHTTPS
  attr_reader :port, :store, :requests

  def initialize
    key = OpenSSL::PKey::RSA.new(2048)
    cert = certificate(key)
    @store = OpenSSL::X509::Store.new
    @store.add_cert(cert)
    @requests = Queue.new
    @listener = TCPServer.new("127.0.0.1", 0)
    @port = @listener.addr[1]
    start(key, cert)
  end

  def close
    @worker.kill
    @worker.join(2)
    @listener.close
  end

  private

  def certificate(key)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=localhost")
    cert.public_key = key
    validity(cert)
    add_extensions(cert)
    cert.sign(key, OpenSSL::Digest.new("SHA256"))
    cert
  end

  def validity(cert)
    cert.not_before = Time.now - 60
    cert.not_after = Time.now + 3600
  end

  def add_extensions(cert)
    factory = OpenSSL::X509::ExtensionFactory.new
    factory.subject_certificate = factory.issuer_certificate = cert
    cert.add_extension(factory.create_extension("subjectAltName", "DNS:localhost"))
  end

  def start(key, cert)
    context = OpenSSL::SSL::SSLContext.new
    context.cert = cert
    context.key = key
    server = OpenSSL::SSL::SSLServer.new(@listener, context)
    @worker = Thread.new { handle(server.accept) }
  end

  def handle(socket)
    lines = []
    lines << socket.gets until lines.last == "\r\n"
    length = lines.grep(/Content-Length:/i).first.split(":", 2).last.to_i
    @requests << [lines.first, socket.read(length)]
    body = '{"result":{"id":12}}'
    socket.write("HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
  ensure
    socket.close
  end
end
