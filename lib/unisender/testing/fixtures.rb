# frozen_string_literal: true

module Unisender
  module Testing
    # Wire-shaped values for common application tests, without a response envelope.
    module Fixtures
      def self.list(id:, title:)
        { "id" => id, "title" => title }
      end

      def self.import_result(total:, invalid: 0, log: [])
        { "total" => total, "invalid" => invalid, "log" => log }
      end

      def self.task(status:, task_uuid:, file_to_download: nil)
        { "status" => status, "task_uuid" => task_uuid, "file_to_download" => file_to_download }.compact
      end

      def self.recipient(index:, email:, id: nil, errors: [])
        { "index" => index, "email" => email, "id" => id, "errors" => errors }.compact
      end
    end
  end
end
