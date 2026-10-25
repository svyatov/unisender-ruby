# frozen_string_literal: true

module Unisender
  # Contacts operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/contacts/createlist/
    def create_list(title:, before_subscribe_url: nil, after_subscribe_url: nil, sub_user_rights: nil)
      params = { title:, before_subscribe_url:, after_subscribe_url:, sub_user_rights: }
      invoke("createList", params, required: %w[title])
    end

    # https://www.unisender.com/ru/support/api/contacts/deletelist/
    def delete_list(list_id:)
      params = { list_id: }
      invoke("deleteList", params, required: %w[list_id])
    end

    # https://www.unisender.com/ru/support/api/contacts/exclude/
    def exclude(contact_type:, contact:, list_ids: nil)
      params = { contact_type:, contact:, list_ids: }
      invoke("exclude", params, required: %w[contact_type contact], comma: %w[list_ids])
    end

    # https://www.unisender.com/ru/support/api/contacts/exportcontacts/
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def export_contacts(notify_url: nil, list_id: nil, field_names: nil, email: nil, phone: nil, tag: nil,
                        email_status: nil, phone_status: nil, contact_status: nil)
      params = { notify_url:, list_id:, field_names:, email:, phone:, tag:, email_status:, phone_status:,
                 contact_status: }
      invoke("async/exportContacts", params)
    end

    # https://www.unisender.com/ru/support/api/contacts/getcontactcount/
    def get_contact_count(list_id:, params:)
      params = { list_id:, params: }
      invoke("getContactCount", params, required: %w[list_id params])
    end

    # https://www.unisender.com/ru/support/api/contacts/getlists/
    # rubocop:disable-next Naming/AccessorMethodName -- Mirrors the documented operation.
    def get_lists
      invoke("getLists", {})
    end

    # https://www.unisender.com/ru/support/api/contacts/gettotalcontactscount/
    def get_total_contacts_count(login:)
      params = { login: }
      invoke("getTotalContactsCount", params, required: %w[login])
    end
  end
end
