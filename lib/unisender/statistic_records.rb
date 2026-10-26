# frozen_string_literal: true

module Unisender
  # Documented campaign stats values.
  class CampaignStats < Record
    COUNTERS = %w[total sent delivered read_unique read_all clicked_unique clicked_all unsubscribed spam].freeze
    def total
      integer("total")
    end

    def sent
      integer("sent")
    end

    def delivered
      integer("delivered")
    end

    def read_unique
      integer("read_unique")
    end

    def read_all
      integer("read_all")
    end

    def clicked_unique
      integer("clicked_unique")
    end

    def clicked_all
      integer("clicked_all")
    end

    def unsubscribed
      integer("unsubscribed")
    end

    def spam
      integer("spam")
    end

    protected

    def normalize
      COUNTERS.each { |name| @values[name] = integer(name) if @values.key?(name) }
    end
  end

  # Transport metadata and CampaignStats readers.
  class CampaignStatsResponse < ObjectResponse
    def total
      result.total
    end

    def sent
      result.sent
    end

    def delivered
      result.delivered
    end

    def read_unique
      result.read_unique
    end

    def read_all
      result.read_all
    end

    def clicked_unique
      result.clicked_unique
    end

    def clicked_all
      result.clicked_all
    end

    def unsubscribed
      result.unsubscribed
    end

    def spam
      result.spam
    end
  end

  # Documented sms receipt values.
  class SmsReceipt < Record
    def sms_id
      identifier!("sms_id")
    end

    def price
      number("price")
    end

    def currency
      text("currency")
    end

    protected

    def normalize
      @values["sms_id"] = sms_id
      @values["price"] = price if @values.key?("price")
      @values["currency"] = currency if @values.key?("currency")
    end
  end

  # Documented email delivery values.
  class EmailDelivery < Record
    def id
      self["id"].nil? ? nil : identifier!("id")
    end

    def status
      text("status")
    end

    protected

    def normalize
      @values["id"] = id if @values.key?("id")
      @values["status"] = status if @values.key?("status")
    end
  end
end
