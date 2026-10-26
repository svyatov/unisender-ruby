# frozen_string_literal: true

module Unisender
  # Statistics operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/statistics/get-campaign-common-stats/
    def get_campaign_common_stats(campaign_id:)
      params = { campaign_id: }
      invoke("getCampaignCommonStats", params, required: %w[campaign_id])
    end

    # https://www.unisender.com/ru/support/api/statistics/getcampaigndeliverystats/
    def get_campaign_delivery_stats(campaign_id:, notify_url: nil, changed_since: nil, field_ids: nil)
      params = { campaign_id:, notify_url:, changed_since:, field_ids: }
      invoke("async/getCampaignDeliveryStats", params, required: %w[campaign_id])
    end

    # https://www.unisender.com/ru/support/api/statistics/getcampaignstatus/
    def get_campaign_status(campaign_id:)
      params = { campaign_id: }
      invoke("getCampaignStatus", params, required: %w[campaign_id])
    end

    # https://www.unisender.com/ru/support/api/statistics/getmessages/
    def get_messages(date_from:, date_to:, limit: nil, offset: nil)
      params = { date_from:, date_to:, limit:, offset: }
      PaginatedOperations.call(self, :get_messages, params) # : PageResponse[Message]
    end

    # https://www.unisender.com/ru/support/api/statistics/getvisitedlinks/
    def get_visited_links(campaign_id:, group: nil)
      params = { campaign_id:, group: }
      invoke("getVisitedLinks", params, required: %w[campaign_id])
    end

    # https://www.unisender.com/ru/support/api/statistics/listmessages/
    def list_messages(date_from:, date_to:, limit: nil, offset: nil)
      params = { date_from:, date_to:, limit:, offset: }
      PaginatedOperations.call(self, :list_messages, params) # : PageResponse[Message]
    end

    # https://www.unisender.com/ru/support/api/statistics/getcampaigns/
    def get_campaigns(from:, to: nil, limit: nil, offset: nil)
      params = { from:, to:, limit:, offset: }
      PaginatedOperations.call(self, :get_campaigns, params) # : PageResponse[Campaign]
    end
  end
end
