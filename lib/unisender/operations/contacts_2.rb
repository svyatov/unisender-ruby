# frozen_string_literal: true

module Unisender
  # Contacts operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/contacts/importcontacts/
    # rubocop:disable-next Metrics/ParameterLists -- Accepts either records or the documented matrix form.
    def import_contacts(field_names: nil, data: nil, records: nil, overwrite_tags: nil, overwrite_lists: nil,
                        telegram_bot_channel_id: nil)
      if records
        if field_names || data
          raise ValidationError.new(field: "records", code: :conflicting_input, operation: "importContacts")
        end

        rows = RecordRows.bounded(records)
        data = rows.to_a
        field_names = rows.field_names
      end
      params = { field_names:, data:, overwrite_tags:, overwrite_lists:, telegram_bot_channel_id: }
      invoke("importContacts", params, required: %w[field_names data])
    end

    # https://www.unisender.com/ru/support/api/contacts/subscribe/
    # rubocop:disable-next Metrics/ParameterLists -- Adds email to the documented subscription options.
    def subscribe(list_ids:, fields: nil, email: nil, tags: nil, double_optin: nil, overwrite: nil)
      fields = Inputs.contact_fields(fields, email)
      params = { list_ids:, fields:, tags:, double_optin:, overwrite: }
      invoke("subscribe", params, required: %w[list_ids fields], comma: %w[list_ids tags])
    end

    # https://www.unisender.com/ru/support/api/contacts/updatelist/
    def update_list(list_id:, title:, before_subscribe_url: nil, after_subscribe_url: nil, sub_user_rights: nil)
      params = { list_id:, title:, before_subscribe_url:, after_subscribe_url:, sub_user_rights: }
      invoke("updateList", params, required: %w[list_id title])
    end

    # https://www.unisender.com/ru/support/api/contacts/iscontactinlists/
    # rubocop:disable-next Naming/PredicatePrefix -- Mirrors the documented operation.
    def is_contact_in_lists(email:, list_ids:, condition:)
      params = { email:, list_ids:, condition: }
      invoke("isContactInLists", params, required: %w[email list_ids condition], comma: %w[list_ids])
    end

    def contact_in_lists?(email:, list_ids:, condition:)
      wire = { any: "or", all: "and" }.fetch(condition) do
        raise ValidationError.new(field: "condition", code: :invalid_choice, operation: "isContactInLists")
      end
      is_contact_in_lists(email:, list_ids:, condition: wire).result
    end

    # https://www.unisender.com/ru/support/api/contacts/getcontact/
    def get_contact(email:, include_lists: nil, include_fields: nil, include_details: nil)
      params = { email:, include_lists:, include_fields:, include_details: }
      invoke("getContact", params, required: %w[email])
    end

    # https://www.unisender.com/ru/support/api/contacts/unsubscribe/
    def unsubscribe(contact_type: nil, contact: nil, email: nil, phone: nil, list_ids: nil)
      params = ContactInputs.contact_selector({ contact_type:, contact:, email:, phone:, list_ids: }, "unsubscribe")
      invoke("unsubscribe", params, required: %w[contact_type contact], comma: %w[list_ids])
    end
  end
end
