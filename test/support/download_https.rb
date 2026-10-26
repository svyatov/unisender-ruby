# frozen_string_literal: true

require_relative "local_https"

class DownloadHTTPS < LocalHTTPS
  def initialize(body: "file data", status: 200, length: nil)
    @download_body = body
    @download_status = status
    @download_length = length || body.bytesize
    super()
  end

  private

  def handle(socket)
    lines = []
    lines << socket.gets until lines.last == "\r\n"
    @requests << lines
    headers = "HTTP/1.1 #{@download_status} Test\r\nContent-Length: #{@download_length}\r\n"
    socket.write("#{headers}Connection: close\r\n\r\n")
    socket.write(@download_body)
  ensure
    socket.close
  end
end
