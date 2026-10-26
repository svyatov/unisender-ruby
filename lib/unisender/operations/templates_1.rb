# frozen_string_literal: true

module Unisender
  # Templates operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/templates/createemailtemplate/
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def create_email_template(title:, subject:, body:, description: nil, text_body: nil, lang: nil)
      params = { title:, subject:, body:, description:, text_body:, lang: }
      invoke("createEmailTemplate", params, required: %w[title subject body])
    end

    # https://www.unisender.com/ru/support/api/templates/deletetemplate/
    def delete_template(template_id:)
      params = { template_id: }
      invoke("deleteTemplate", params, required: %w[template_id])
    end

    # https://www.unisender.com/ru/support/api/templates/gettemplate/
    def get_template(template_id: nil, system_template_id: nil)
      params = { template_id:, system_template_id: }
      invoke("getTemplate", params)
    end

    # https://www.unisender.com/ru/support/api/templates/gettemplates/
    def get_templates(type: nil, date_from: nil, date_to: nil, limit: nil, offset: nil)
      params = { type:, date_from:, date_to:, limit:, offset: }
      PaginatedOperations.call(self, :get_templates, params) # : PageResponse[Template]
    end

    # https://www.unisender.com/ru/support/api/templates/listtemplates/
    def list_templates(type: nil, date_from: nil, date_to: nil, limit: nil, offset: nil)
      params = { type:, date_from:, date_to:, limit:, offset: }
      PaginatedOperations.call(self, :list_templates, params) # : PageResponse[Template]
    end

    # https://www.unisender.com/ru/support/api/templates/updateemailtemplate/
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def update_email_template(template_id:, title: nil, description: nil, subject: nil, body: nil,
                              text_body: nil, lang: nil)
      params = { template_id:, title:, description:, subject:, body:, text_body:, lang: }
      invoke("updateEmailTemplate", params, required: %w[template_id])
    end
  end
end
