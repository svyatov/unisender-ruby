# frozen_string_literal: true

module Unisender
  # Documented identifier record fields.
  class IdentifierRecord < Record
    def id
      identifier!("id")
    end

    protected

    def normalize
      super
      @values["id"] = id
    end
  end

  # Transport metadata and IdentifierRecord field access.
  class IdentifierRecordResponse < ObjectResponse
    def id
      result.id
    end
  end

  # Documented list fields.
  class List < IdentifierRecord
    def title
      text!("title")
    end

    protected

    def normalize
      super
      @values["title"] = title
    end
  end

  # Transport metadata and List field access.
  class ListResponse < ObjectResponse
    def id
      result.id
    end

    def title
      result.title
    end
  end

  # Documented message fields.
  class Message < IdentifierRecord
    def subject
      text("subject")
    end

    def body
      text("body")
    end

    def sender_name
      text("sender_name")
    end

    def sender_email
      text("sender_email")
    end

    protected

    def normalize
      super
      @values["subject"] = subject if @values.key?("subject")
      @values["body"] = body if @values.key?("body")
      @values["sender_name"] = sender_name if @values.key?("sender_name")
      @values["sender_email"] = sender_email if @values.key?("sender_email")
    end
  end

  # Transport metadata and Message field access.
  class MessageResponse < ObjectResponse
    def id
      result.id
    end

    def subject
      result.subject
    end

    def body
      result.body
    end

    def sender_name
      result.sender_name
    end

    def sender_email
      result.sender_email
    end
  end

  # Documented campaign fields.
  class Campaign < IdentifierRecord
    def status
      text("status")
    end

    def subject
      text("subject")
    end

    protected

    def normalize
      super
      @values["status"] = status if @values.key?("status")
      @values["subject"] = subject if @values.key?("subject")
    end
  end

  # Transport metadata and Campaign field access.
  class CampaignResponse < ObjectResponse
    def id
      result.id
    end

    def status
      result.status
    end

    def subject
      result.subject
    end
  end

  # Documented template fields.
  class Template < IdentifierRecord
    def title
      text("title")
    end

    def subject
      text("subject")
    end

    def body
      text("body")
    end

    protected

    def normalize
      super
      @values["title"] = title if @values.key?("title")
      @values["subject"] = subject if @values.key?("subject")
      @values["body"] = body if @values.key?("body")
    end
  end

  # Transport metadata and Template field access.
  class TemplateResponse < ObjectResponse
    def id
      result.id
    end

    def title
      result.title
    end

    def subject
      result.subject
    end

    def body
      result.body
    end
  end

  # Documented field fields.
  class Field < IdentifierRecord
    def name
      text!("name")
    end

    def type
      text!("type")
    end

    protected

    def normalize
      super
      @values["name"] = name
      @values["type"] = type
    end
  end

  # Transport metadata and Field field access.
  class FieldResponse < ObjectResponse
    def id
      result.id
    end

    def name
      result.name
    end

    def type
      result.type
    end
  end

  # Documented tag fields.
  class Tag < IdentifierRecord
    def name
      text!("name")
    end

    protected

    def normalize
      super
      @values["name"] = name
    end
  end

  # Transport metadata and Tag field access.
  class TagResponse < ObjectResponse
    def id
      result.id
    end

    def name
      result.name
    end
  end

  # Documented note fields.
  class Note < IdentifierRecord
    def content
      text!("content")
    end

    protected

    def normalize
      super
      @values["content"] = content
    end
  end

  # Transport metadata and Note field access.
  class NoteResponse < ObjectResponse
    def id
      result.id
    end

    def content
      result.content
    end
  end

  # Documented message created fields.
  class MessageCreated < Record
    def message_id
      identifier!("message_id")
    end

    protected

    def normalize
      super
      @values["message_id"] = message_id
    end
  end

  # Transport metadata and MessageCreated field access.
  class MessageCreatedResponse < ObjectResponse
    def message_id
      result.message_id
    end
  end

  # Documented subscription fields.
  class Subscription < Record
    def person_id
      identifier!("person_id")
    end

    protected

    def normalize
      super
      @values["person_id"] = person_id
    end
  end

  # Transport metadata and Subscription field access.
  class SubscriptionResponse < ObjectResponse
    def person_id
      result.person_id
    end
  end

  # Documented campaign created fields.
  class CampaignCreated < Record
    def campaign_id
      identifier!("campaign_id")
    end

    def status
      text!("status")
    end

    protected

    def normalize
      super
      @values["campaign_id"] = campaign_id
      @values["status"] = status
    end
  end

  # Transport metadata and CampaignCreated field access.
  class CampaignCreatedResponse < ObjectResponse
    def campaign_id
      result.campaign_id
    end

    def status
      result.status
    end
  end

  # Documented status fields.
  class Status < Record
    def status
      text!("status")
    end

    protected

    def normalize
      super
      @values["status"] = status
    end
  end

  # Transport metadata and Status field access.
  class StatusResponse < ObjectResponse
    def status
      result.status
    end
  end

  # Documented contact count fields.
  class ContactCount < Record
    def count
      integer!("count")
    end

    protected

    def normalize
      super
      @values["count"] = count
    end
  end

  # Transport metadata and ContactCount field access.
  class ContactCountResponse < ObjectResponse
    def count
      result.count
    end
  end

  # Documented total contacts fields.
  class TotalContacts < Record
    def total
      integer!("total")
    end

    protected

    def normalize
      super
      @values["total"] = total
    end
  end

  # Transport metadata and TotalContacts field access.
  class TotalContactsResponse < ObjectResponse
    def total
      result.total
    end
  end

  # Documented message version fields.
  class MessageVersion < Record
    def message_id
      identifier!("message_id")
    end

    def actual_version_id
      identifier!("actual_version_id")
    end

    protected

    def normalize
      super
      @values["message_id"] = message_id
      @values["actual_version_id"] = actual_version_id
    end
  end

  # Transport metadata and MessageVersion field access.
  class MessageVersionResponse < ObjectResponse
    def message_id
      result.message_id
    end

    def actual_version_id
      result.actual_version_id
    end
  end

  # Documented web version fields.
  class WebVersion < Record
    def letter_id
      identifier!("letter_id")
    end

    def web_letter_link
      text!("web_letter_link")
    end

    protected

    def normalize
      super
      @values["letter_id"] = letter_id
      @values["web_letter_link"] = web_letter_link
    end
  end

  # Transport metadata and WebVersion field access.
  class WebVersionResponse < ObjectResponse
    def letter_id
      result.letter_id
    end

    def web_letter_link
      result.web_letter_link
    end
  end

  # Documented task result fields.
  class TaskResult < Record
    def task_uuid
      text("task_uuid")
    end

    def status
      text!("status")
    end

    def file_to_download
      text("file_to_download")
    end

    protected

    def normalize
      super
      @values["task_uuid"] = task_uuid if @values.key?("task_uuid")
      @values["status"] = status
      @values["file_to_download"] = file_to_download if @values.key?("file_to_download")
    end
  end

  # Transport metadata and TaskResult field access.
  class TaskResultResponse < ObjectResponse
    def task_uuid
      result.task_uuid
    end

    def status
      result.status
    end

    def file_to_download
      result.file_to_download
    end
  end
end
