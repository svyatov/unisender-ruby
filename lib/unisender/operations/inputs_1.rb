# frozen_string_literal: true

module Unisender
  # Inputs operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/inputs/createfield/
    def create_field(name:, type:, public_name: nil)
      params = { name:, type:, public_name: }
      invoke("createField", params, required: %w[name type])
    end

    # https://www.unisender.com/ru/support/api/inputs/deletefield/
    def delete_field(id:)
      params = { id: }
      invoke("deleteField", params, required: %w[id])
    end

    # https://www.unisender.com/ru/support/api/inputs/deletetag/
    def delete_tag(id:)
      params = { id: }
      invoke("deleteTag", params, required: %w[id])
    end

    # https://www.unisender.com/ru/support/api/inputs/getfields/
    # rubocop:disable-next Naming/AccessorMethodName -- Mirrors the documented operation.
    def get_fields
      invoke("getFields", {})
    end

    # https://www.unisender.com/ru/support/api/inputs/gettags/
    # rubocop:disable-next Naming/AccessorMethodName -- Mirrors the documented operation.
    def get_tags
      invoke("getTags", {})
    end

    # https://www.unisender.com/ru/support/api/inputs/updatefield/
    def update_field(id:, name:, public_name: nil)
      params = { id:, name:, public_name: }
      invoke("updateField", params, required: %w[id name])
    end

    # https://www.unisender.com/ru/support/api/inputs/getcontactfieldvalues/
    def get_contact_field_values(email:, field_ids:)
      params = { email:, field_ids: }
      invoke("getContactFieldValues", params, required: %w[email field_ids], comma: %w[field_ids])
    end
  end
end
