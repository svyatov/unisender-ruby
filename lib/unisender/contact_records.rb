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

    def added_at
      text("added_at")
    end

    def last_send_datetime
      text("last_send_datetime")
    end

    def last_delivery_datetime
      text("last_delivery_datetime")
    end

    def last_read_datetime
      text("last_read_datetime")
    end

    def last_click_datetime
      text("last_click_datetime")
    end

    def rating
      number("rating")
    end

    protected

    def normalize
      email
      status
      availability
      added_at
      last_send_datetime
      last_delivery_datetime
      last_read_datetime
      last_click_datetime
      rating
    end
  end

  # Optional phone details returned by getContact.
  class PhoneContact < Record
    def phone
      text!("phone")
    end

    def status
      text("status")
    end

    def availability
      text("availability")
    end

    def added_at
      text("added_at")
    end

    protected

    def normalize
      phone
      status
      availability
      added_at
    end
  end

  # A contact's membership in one list.
  class ContactList < IdentifierRecord
    def status
      text("status")
    end

    def added_at
      text("added_at")
    end

    protected

    def normalize
      super
      status
      added_at
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

    def email_address
      value = email
      value.is_a?(EmailContact) ? value.email : value
    end

    def phone
      value = self["phone"]
      return value if value.nil? || value.is_a?(String)
      return PhoneContact.new(value.to_h) if value.is_a?(Record)

      invalid!("phone")
    end

    def phone_number
      value = phone
      value.is_a?(PhoneContact) ? value.phone : value
    end

    def lists
      value = self["lists"]
      return nil if value.nil?

      Outcomes.records(value).map { |item| ContactList.new(item.to_h) }.freeze
    end

    def fields
      value = self["fields"]
      return value if value.nil? || value.is_a?(Record)

      invalid!("fields")
    end

    protected

    def normalize
      email
      phone
      lists
      fields
    end
  end

  # Contact details with transport metadata.
  class ContactResponse < ObjectResponse
    def email
      result.email
    end

    def email_address
      result.email_address
    end

    def phone
      result.phone
    end

    def phone_number
      result.phone_number
    end

    def lists
      result.lists
    end

    def fields
      result.fields
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
