# frozen_string_literal: true

module Unisender
  # Result classes for named operations.
  module Results
    # @type var models: Hash[String, [singleton(Record), singleton(ObjectResponse)]]
    models = {
      "createList" => [IdentifierRecord, IdentifierRecordResponse],
      "deleteList" => [Record, ObjectResponse],
      "exclude" => [Record, ObjectResponse],
      "async/exportContacts" => [TaskResult, TaskResultResponse],
      "getContactCount" => [ContactCount, ContactCountResponse],
      "getLists" => [List, ListResponse],
      "getTotalContactsCount" => [TotalContacts, TotalContactsResponse],
      "importContacts" => [ImportResult, ImportResponse],
      "subscribe" => [Subscription, SubscriptionResponse],
      "updateList" => [Record, ObjectResponse],
      "getContact" => [Contact, ContactResponse],
      "unsubscribe" => [Record, ObjectResponse],
      "cancelCampaign" => [Record, ObjectResponse],
      "checkEmail" => [EmailDelivery, ObjectResponse],
      "checkSms" => [Status, StatusResponse],
      "createCampaign" => [CampaignCreated, CampaignCreatedResponse],
      "createEmailMessage" => [MessageCreated, MessageCreatedResponse],
      "createSmsMessage" => [MessageCreated, MessageCreatedResponse],
      "deleteMessage" => [Record, ObjectResponse],
      "getActualMessageVersion" => [MessageVersion, MessageVersionResponse],
      "getWebVersion" => [WebVersion, WebVersionResponse],
      "sendEmail" => [SendResult, SendResponse],
      "sendSms" => [SmsReceipt, SmsReceiptResponse],
      "sendTestEmail" => [Record, ObjectResponse],
      "updateEmailMessage" => [MessageCreated, MessageCreatedResponse],
      "updateOptInEmail" => [Record, ObjectResponse],
      "getSenderDomainList" => [SenderDomainGroup, ObjectResponse],
      "getCampaignCommonStats" => [CampaignStats, CampaignStatsResponse],
      "async/getCampaignDeliveryStats" => [TaskResult, TaskResultResponse],
      "getCampaignStatus" => [Status, StatusResponse],
      "getMessages" => [Message, MessageResponse],
      "getVisitedLinks" => [Record, ObjectResponse],
      "listMessages" => [Message, MessageResponse],
      "getCampaigns" => [Campaign, CampaignResponse],
      "getMessage" => [Message, MessageResponse],
      "async/getTaskResult" => [TaskResult, TaskResultResponse],
      "createEmailTemplate" => [IdentifierRecord, IdentifierRecordResponse],
      "deleteTemplate" => [Record, ObjectResponse],
      "getTemplate" => [Template, TemplateResponse],
      "getTemplates" => [Template, TemplateResponse],
      "listTemplates" => [Template, TemplateResponse],
      "updateEmailTemplate" => [IdentifierRecord, IdentifierRecordResponse],
      "createField" => [IdentifierRecord, IdentifierRecordResponse],
      "deleteField" => [Record, ObjectResponse],
      "deleteTag" => [Record, ObjectResponse],
      "getFields" => [Field, FieldResponse],
      "getTags" => [Tag, TagResponse],
      "updateField" => [Record, ObjectResponse],
      "getContactFieldValues" => [ContactFields, ContactFieldsResponse],
      "createSubscriberNote" => [IdentifierRecord, IdentifierRecordResponse],
      "updateSubscriberNote" => [IdentifierRecord, IdentifierRecordResponse],
      "deleteSubscriberNote" => [Record, ObjectResponse],
      "getSubscriberNote" => [Note, NoteResponse],
      "getSubscriberNotes" => [Note, NoteResponse]
    }
    MODELS = models.freeze
    EMPTY_OPERATIONS = %w[deleteList exclude updateList unsubscribe cancelCampaign deleteMessage
                          sendTestEmail updateField updateOptInEmail deleteTemplate deleteField
                          deleteTag deleteSubscriberNote].freeze
  end
end
