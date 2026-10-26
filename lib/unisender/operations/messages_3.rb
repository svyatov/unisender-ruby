# frozen_string_literal: true

module Unisender
  # Messages operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/messages/getsenderdomainlist/
    def get_sender_domain_list(username:, domain: nil, limit: nil, offset: nil)
      params = { username:, domain:, limit:, offset: }
      PaginatedOperations.call(self, :get_sender_domain_list, params) # : PageResponse[Record]
    end
  end
end
