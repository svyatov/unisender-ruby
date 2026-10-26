# frozen_string_literal: true

module Unisender
  # Email details returned by getContact.
  class EmailContact < Record
    def email
      text!("email")
    end

    def status
      text("status")
    end

    def availability
      text("availability")
    end

    protected

    def normalize
      email
      status
      availability
    end
  end

  # Optional account details remain accessible through their original keys.
  class Contact < Record
    def email
      value = self["email"]
      return value if value.nil? || value.is_a?(String)
      return EmailContact.new(value.to_h) if value.is_a?(Record)

      invalid!("email")
    end

    protected

    def normalize
      email
    end
  end

  # Contact details with transport metadata.
  class ContactResponse < ObjectResponse
    def email
      result.email
    end
  end

  # Sender-domain fields retain upstream capitalization in key-based access.
  class SenderDomain < Record
    def domain
      text!("Domain")
    end

    def status
      text("Status")
    end

    def key
      text("key")
    end

    protected

    def normalize
      domain
      status
      key
    end
  end

  # A group is the unit yielded by sender-domain pagination.
  class SenderDomainGroup < Record
    def status
      text("status")
    end

    def domains
      Outcomes.records(self["domains"]).map { |item| SenderDomain.new(item.to_h) }.freeze
    end

    protected

    def normalize
      status
      invalid!("domains") unless self["domains"].is_a?(Array)
      domains
    end
  end

  # Dynamic field IDs remain string keys.
  class ContactFields < Record
    def field_values
      value = self["fieldValues"]
      return value if value.is_a?(Record)

      invalid!("fieldValues")
    end

    protected

    def normalize
      field_values
    end
  end

  # Dynamic contact values with transport metadata.
  class ContactFieldsResponse < ObjectResponse
    def field_values
      result.field_values
    end
  end
end
