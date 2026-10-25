# frozen_string_literal: true

class ScriptedTransport
  attr_reader :requests

  def initialize(*replies)
    @replies = replies
    @requests = []
  end

  def post(uri, headers:, body:)
    @requests << { uri:, headers:, body: }
    reply = @replies.shift or raise "Unexpected HTTP request"
    raise reply if reply.is_a?(Exception)

    reply
  end

  def self.reply(data = { "result" => [] }, status: 200, headers: {})
    Unisender::HTTPResponse.new(status:, headers:, body: JSON.generate(data))
  end
end
