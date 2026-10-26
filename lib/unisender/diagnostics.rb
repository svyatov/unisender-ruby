# frozen_string_literal: true

module Unisender
  # Safe error metadata excludes payload values and arbitrary exception text.
  module Diagnostics
    # @type var types: Hash[Module, String]
    types = { String => "String", Integer => "Integer", Float => "Float", Symbol => "Symbol",
              Array => "Array", Hash => "Hash", NilClass => "NilClass",
              TrueClass => "Boolean", FalseClass => "Boolean" }
    TYPES = types.freeze
    FIELDS = (OperationContracts::DEFINITIONS.values.flat_map { |definition| definition.last.keys } +
              %w[parameters max_bytes batch_size retention filename email_list_ids phone_list_ids
                 email_subscribe_times phone_subscribe_times tags]).uniq.freeze

    def self.input_path(path)
      root = path.split(/[.\[]/, 2).first.to_s
      return "parameters" unless FIELDS.include?(root)

      suffix = path.delete_prefix(root).gsub(/\[[^\]]*\]/) { |part| part.match?(/\A\[\d+\]\z/) ? part : "[*]" }
      suffix = suffix.gsub(/\.[^.\[]+/) { |part| FIELDS.include?(part.delete_prefix(".")) ? part : ".*" }
      root + suffix
    end

    def self.type_name(value)
      TYPES.each { |type, name| return name if value.is_a?(type) }
      "Object"
    end

    def self.for_error(error)
      values = common_fields(error)
      values.merge!(error.is_a?(ValidationError) ? validation_fields(error) : error_fields(error))
      cause = underlying(error) if error.is_a?(Error)
      values = for_error(cause).merge(values) if cause
      values.compact.freeze
    end

    def self.common_fields(error)
      { operation: error.operation, category: error.category.to_s,
        documentation_url: URLS[error.operation.to_s] }.compact
    end

    def self.validation_fields(error)
      { path: error.path, code: error.code.to_s, expected_type: error.expected_type, actual_type: error.actual_type }
    end

    def self.error_fields(error)
      values = context_fields(error)
      values[:code] = error.safe_code if error.is_a?(APIError)
      values.merge!(batch_fields(error)) if error.is_a?(BatchError)
      if error.is_a?(InvalidResponseError)
        values.merge!(path: error.path, expected_type: error.expected_type, actual_type: error.actual_type)
      end
      values.compact
    end

    def self.context_fields(error)
      { http_status: error.http_status, request_id: error.request_id, task_uuid: error.task_uuid,
        next_offset: error.next_offset, completed_pages: error.completed_pages, bytes_written: error.bytes_written }
    end

    def self.batch_fields(error)
      { completed_batches: error.completed_responses.size,
        failed_from: error.failed_range.begin, failed_to: error.failed_range.end }
    end

    def self.underlying(error)
      case error
      when BatchError, CampaignWorkflowError
        cause = error.error
        cause if cause.is_a?(Error) || cause.is_a?(ValidationError)
      end
    end
  end
end
