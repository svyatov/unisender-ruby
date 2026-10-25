# frozen_string_literal: true

module Unisender
  # Statistics operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/statistics/getmessage/
    def get_message(id:)
      params = { id: }
      invoke("getMessage", params, required: %w[id])
    end

    # https://www.unisender.com/ru/support/api/statistics/../contacts/exportcontacts/
    def get_task_result(task_uuid:)
      params = { task_uuid: }
      invoke("async/getTaskResult", params, required: %w[task_uuid])
    end
  end
end
