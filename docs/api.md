# API reference

Contract audit: 2026-10-25. The [official UniSender documentation](https://www.unisender.com/ru/support/category/api/) is the source of truth. Tests use deterministic, artificial responses and do not establish live account compatibility.

All methods return `Unisender::Response`. Required arguments are Ruby keywords. Optional keywords default to omission, preserving the service's defaults. RBS signatures ship with the gem. Identifiers accept integers or strings; flags accept booleans or 0/1. Dates remain strings in the format and time zone documented for each method.

Arrays supplied to comma-separated fields are joined only by named methods. For other array or hash arguments, the form encoder emits explicit bracket indices. `request(method, params: {})` accepts the exact wire method and parameters; it does not perform method-specific conversions or validation.

## Implemented operations

The offline contract cases are in [operations.json](../test/fixtures/operations.json) and run through [operations_test.rb](../test/operations_test.rb). Every entry verifies the path, authentication body, required arguments, a successful result, and API failure propagation.

| Ruby method | Wire method and documentation | Required keywords | Optional keywords |
| --- | --- | --- | --- |
| `create_list` | [`createList`](https://www.unisender.com/ru/support/api/contacts/createlist/) | `title` | `before_subscribe_url`, `after_subscribe_url`, `sub_user_rights` |
| `delete_list` | [`deleteList`](https://www.unisender.com/ru/support/api/contacts/deletelist/) | `list_id` | None |
| `exclude` | [`exclude`](https://www.unisender.com/ru/support/api/contacts/exclude/) | `contact_type`, `contact` | `list_ids` |
| `export_contacts` | [`async/exportContacts`](https://www.unisender.com/ru/support/api/contacts/exportcontacts/) | None | `notify_url`, `list_id`, `field_names`, `email`, `phone`, `tag`, `email_status`, `phone_status`, `contact_status` |
| `get_contact_count` | [`getContactCount`](https://www.unisender.com/ru/support/api/contacts/getcontactcount/) | `list_id`, `params` | None |
| `get_lists` | [`getLists`](https://www.unisender.com/ru/support/api/contacts/getlists/) | None | None |
| `get_total_contacts_count` | [`getTotalContactsCount`](https://www.unisender.com/ru/support/api/contacts/gettotalcontactscount/) | `login` | None |
| `import_contacts` | [`importContacts`](https://www.unisender.com/ru/support/api/contacts/importcontacts/) | `field_names`, `data` | `overwrite_tags`, `overwrite_lists`, `telegram_bot_channel_id` |
| `subscribe` | [`subscribe`](https://www.unisender.com/ru/support/api/contacts/subscribe/) | `list_ids`, `fields` | `tags`, `double_optin`, `overwrite` |
| `update_list` | [`updateList`](https://www.unisender.com/ru/support/api/contacts/updatelist/) | `list_id`, `title` | `before_subscribe_url`, `after_subscribe_url`, `sub_user_rights` |
| `is_contact_in_lists` | [`isContactInLists`](https://www.unisender.com/ru/support/api/contacts/iscontactinlists/) | `email`, `list_ids`, `condition` | None |
| `get_contact` | [`getContact`](https://www.unisender.com/ru/support/api/contacts/getcontact/) | `email` | `include_lists`, `include_fields`, `include_details` |
| `unsubscribe` | [`unsubscribe`](https://www.unisender.com/ru/support/api/contacts/unsubscribe/) | `contact_type`, `contact` | `list_ids` |
| `cancel_campaign` | [`cancelCampaign`](https://www.unisender.com/ru/support/api/messages/cancel-campaign/) | `campaign_id` | None |
| `check_email` | [`checkEmail`](https://www.unisender.com/ru/support/api/messages/check-email/) | `email_id` | None |
| `check_sms` | [`checkSms`](https://www.unisender.com/ru/support/api/messages/check-sms/) | `sms_id` | None |
| `create_campaign` | [`createCampaign`](https://www.unisender.com/ru/support/api/messages/createcampaign/) | `message_id` | `start_time`, `timezone`, `track_read`, `track_links`, `contacts`, `contacts_url`, `track_ga`, `payment_limit`, `payment_currency`, `ga_medium`, `ga_source`, `ga_campaign`, `ga_content`, `ga_term` |
| `create_email_message` | [`createEmailMessage`](https://www.unisender.com/ru/support/api/messages/createemailmessage/) | `sender_name`, `sender_email`, `list_id` | `subject`, `body`, `text_body`, `generate_text`, `tag`, `attachments`, `lang`, `template_id`, `system_template_id`, `wrap_type`, `categories` |
| `create_sms_message` | [`createSmsMessage`](https://www.unisender.com/ru/support/api/messages/createsmsmessage/) | `sender`, `body`, `list_id` | `tag` |
| `delete_message` | [`deleteMessage`](https://www.unisender.com/ru/support/api/messages/deletemessage/) | `message_id` | None |
| `get_actual_message_version` | [`getActualMessageVersion`](https://www.unisender.com/ru/support/api/messages/get-actual-message-version/) | `message_id` | None |
| `get_web_version` | [`getWebVersion`](https://www.unisender.com/ru/support/api/messages/getwebversion/) | `campaign_id` | None |
| `send_email` | [`sendEmail`](https://www.unisender.com/ru/support/api/messages/sendemail/) | `email`, `sender_name`, `sender_email`, `subject`, `body`, `list_id` | `attachments`, `lang`, `track_read`, `track_links`, `cc`, `headers`, `images_as`, `ref_key`, `error_checking`, `metadata` |
| `send_sms` | [`sendSms`](https://www.unisender.com/ru/support/api/messages/sendsms/) | `phone`, `sender`, `text` | None |
| `send_test_email` | [`sendTestEmail`](https://www.unisender.com/ru/support/api/messages/sendtestemail/) | `email`, `id` | None |
| `update_email_message` | [`updateEmailMessage`](https://www.unisender.com/ru/support/api/messages/updateemailmessage/) | `id` | `sender_name`, `sender_email`, `subject`, `body`, `list_id`, `text_body`, `lang`, `categories` |
| `update_opt_in_email` | [`updateOptInEmail`](https://www.unisender.com/ru/support/api/messages/updateoptinemail/) | `sender_name`, `sender_email`, `subject`, `body`, `list_id` | None |
| `get_sender_domain_list` | [`getSenderDomainList`](https://www.unisender.com/ru/support/api/messages/getsenderdomainlist/) | `username` | `domain`, `limit`, `offset` |
| `get_campaign_common_stats` | [`getCampaignCommonStats`](https://www.unisender.com/ru/support/api/statistics/get-campaign-common-stats/) | `campaign_id` | None |
| `get_campaign_delivery_stats` | [`async/getCampaignDeliveryStats`](https://www.unisender.com/ru/support/api/statistics/getcampaigndeliverystats/) | `campaign_id` | `notify_url`, `changed_since`, `field_ids` |
| `get_campaign_status` | [`getCampaignStatus`](https://www.unisender.com/ru/support/api/statistics/getcampaignstatus/) | `campaign_id` | None |
| `get_messages` | [`getMessages`](https://www.unisender.com/ru/support/api/statistics/getmessages/) | `date_from`, `date_to` | `limit`, `offset` |
| `get_visited_links` | [`getVisitedLinks`](https://www.unisender.com/ru/support/api/statistics/getvisitedlinks/) | `campaign_id` | `group` |
| `list_messages` | [`listMessages`](https://www.unisender.com/ru/support/api/statistics/listmessages/) | `date_from`, `date_to` | `limit`, `offset` |
| `get_campaigns` | [`getCampaigns`](https://www.unisender.com/ru/support/api/statistics/getcampaigns/) | `from` | `to`, `limit`, `offset` |
| `get_message` | [`getMessage`](https://www.unisender.com/ru/support/api/statistics/getmessage/) | `id` | None |
| `get_task_result` | [`async/getTaskResult`](https://www.unisender.com/ru/support/api/statistics/../contacts/exportcontacts/) | `task_uuid` | None |
| `create_email_template` | [`createEmailTemplate`](https://www.unisender.com/ru/support/api/templates/createemailtemplate/) | `title`, `subject`, `body` | `description`, `text_body`, `lang` |
| `delete_template` | [`deleteTemplate`](https://www.unisender.com/ru/support/api/templates/deletetemplate/) | `template_id` | None |
| `get_template` | [`getTemplate`](https://www.unisender.com/ru/support/api/templates/gettemplate/) | None | `template_id`, `system_template_id` |
| `get_templates` | [`getTemplates`](https://www.unisender.com/ru/support/api/templates/gettemplates/) | None | `type`, `date_from`, `date_to`, `limit`, `offset` |
| `list_templates` | [`listTemplates`](https://www.unisender.com/ru/support/api/templates/listtemplates/) | None | `type`, `date_from`, `date_to`, `limit`, `offset` |
| `update_email_template` | [`updateEmailTemplate`](https://www.unisender.com/ru/support/api/templates/updateemailtemplate/) | `template_id` | `title`, `description`, `subject`, `body`, `text_body`, `lang` |
| `create_field` | [`createField`](https://www.unisender.com/ru/support/api/inputs/createfield/) | `name`, `type` | `public_name` |
| `delete_field` | [`deleteField`](https://www.unisender.com/ru/support/api/inputs/deletefield/) | `id` | None |
| `delete_tag` | [`deleteTag`](https://www.unisender.com/ru/support/api/inputs/deletetag/) | `id` | None |
| `get_fields` | [`getFields`](https://www.unisender.com/ru/support/api/inputs/getfields/) | None | None |
| `get_tags` | [`getTags`](https://www.unisender.com/ru/support/api/inputs/gettags/) | None | None |
| `update_field` | [`updateField`](https://www.unisender.com/ru/support/api/inputs/updatefield/) | `id`, `name` | `public_name` |
| `get_contact_field_values` | [`getContactFieldValues`](https://www.unisender.com/ru/support/api/inputs/getcontactfieldvalues/) | `email`, `field_ids` | None |
| `create_subscriber_note` | [`createSubscriberNote`](https://www.unisender.com/ru/support/api/notes/createsubscibernote/) | `subscriber_id`, `content` | None |
| `update_subscriber_note` | [`updateSubscriberNote`](https://www.unisender.com/ru/support/api/notes/updatesubcribernote/) | `id`, `content` | None |
| `delete_subscriber_note` | [`deleteSubscriberNote`](https://www.unisender.com/ru/support/api/notes/deletesubscribernote/) | `id` | None |
| `get_subscriber_note` | [`getSubscriberNote`](https://www.unisender.com/ru/support/api/notes/getsubscribernote/) | `id` | None |
| `get_subscriber_notes` | [`getSubscriberNotes`](https://www.unisender.com/ru/support/api/notes/getsubscribernotes/) | `subscriber_id` | `limit`, `offset`, `order_type`, `order_by`, `is_pinned` |
| `track_events` | [Event Tracking](https://www.unisender.com/ru/support/api/event-tracking-api/) | `events` | None |

## Documentation decisions

1. **D1:** The supplied [OpenAPI repository](https://gitflic.ru/project/unisender/unigo-openapi) targets UniSender Go, which has a different host and protocol. This gem does not use that specification.
2. **D2:** Contact exports and delivery reports use `async/exportContacts` and `async/getCampaignDeliveryStats`. Both share `async/getTaskResult`. The gem returns the download URL without requesting it or forwarding credentials to it.
3. **D3:** Note page titles misspell create and update operations. Their request examples use `createSubscriberNote` and `updateSubscriberNote`; the gem follows those request URLs.
4. **D4:** Event Tracking's endpoint definition specifies `https://event.unisender.com/v1/events/`, but its examples omit `/v1`. The gem follows the endpoint definition. The page also shows both a string `error` and structured `details`; `EventError#details` accepts either representation. HTTP 400 can mean partial acceptance.
5. **D5:** The create-email page allows templates to supply subject and body. Both template selectors satisfy this alternative; the gem does not invent precedence if both are supplied. Its syntax lists `categories`, although its argument table omits it; the gem accepts that documented keyword.

`format` is always JSON and cannot be overridden. All request bodies use UTF-8 text except raw attachment bytes. The service can change documented limits and validation rules; account permissions, consent, deliverability, and account-specific limits remain server decisions.

## Convenience operations

| Helper | Behavior |
| --- | --- |
| `each_page(method, page_size: 100, max_pages: 1000, **params)` | Lazy Enumerator of responses for `get_campaigns`, `get_messages`, `list_messages`, `get_templates`, `list_templates`, `get_sender_domain_list`, and `get_subscriber_notes`. An optional `offset` starts iteration. Stops at a short or empty page; raises at the page bound. Offset pagination is not a server snapshot. |
| `import_contacts_in_batches(field_names:, data:, batch_size: 500, ...)` | Lazy sequential import of an Enumerable of rows. Accepts `overwrite_tags`, `overwrite_lists`, and `telegram_bot_channel_id`. Stops on request failures or a nonzero `invalid` count. |
| `track_events_in_batches(events:, batch_size: 25)` | Lazy sequential event batches. Each request must also meet the 130 KiB payload limit. Use a smaller batch size for large events. |
| `wait_for_task(task_uuid:, interval: 1, timeout: 60)` | Polls existing tasks until completion, with a monotonic deadline. Raises on an unknown task state. Deadlines are checked between requests; an in-flight request remains bounded by transport timeouts. |

`each_page` accepts the same operation keywords as the corresponding named method, except that `page_size` replaces `limit`. Unknown keywords, non-symbol keys, and missing or empty required values raise `ArgumentError` when enumeration starts, before any request. Direct named calls reject invalid arguments immediately. The low-level `request` method retains its existing parameter handling.

Pagination additionally requires a positive integer page size within the method's documented limit, a positive integer `max_pages`, and a nonnegative integer `offset`. These are helper controls; direct named calls retain the service's validation of their `limit` and `offset` values. Each yielded response preserves its warnings and metadata.

Batch helper failures raise `BatchError`. Its `completed_responses` contains earlier successful batches, `failed_range` is the zero-based, end-exclusive input range with an uncertain or failed outcome, and `error` contains the original failure. A failed batch can still contain accepted records. Helpers do not replay batches or roll back earlier changes.
