# API reference

Contract audit: 2026-10-25. The [official UniSender documentation](https://www.unisender.com/ru/support/category/api/) is the source of truth. Tests use deterministic, artificial responses and do not establish live account compatibility.

All methods return `Unisender::Response`; named operations declare their result type as `Response[Result]`. Required arguments are Ruby keywords. Optional keywords default to omission, preserving the service's defaults. RBS signatures ship with the gem. Identifiers accept integers or strings; flags accept booleans or 0/1. Dates remain strings in the format and time zone documented for each method.

Arrays supplied to comma-separated fields are joined only by named methods. For other array or hash arguments, the form encoder emits explicit bracket indices. `request(method, params: {})` accepts the exact wire method and parameters; it does not perform method-specific conversions or validation.

## Implemented operations

The offline contract cases are in `test/fixtures/operations.json` and run through `test/operations_test.rb` in the source checkout. Every entry verifies the path, authentication body, required arguments, a successful result, and API failure propagation.

| Ruby method | Wire method and documentation | Required keywords | Optional keywords |
| --- | --- | --- | --- |
| [`create_list`](#create_list) | [`createList`](https://www.unisender.com/ru/support/api/contacts/createlist/) | `title` | `before_subscribe_url`, `after_subscribe_url`, `sub_user_rights` |
| [`delete_list`](#delete_list) | [`deleteList`](https://www.unisender.com/ru/support/api/contacts/deletelist/) | `list_id` | None |
| [`exclude`](#exclude) | [`exclude`](https://www.unisender.com/ru/support/api/contacts/exclude/) | `contact_type`, `contact` | `list_ids` |
| [`export_contacts`](#export_contacts) | [`async/exportContacts`](https://www.unisender.com/ru/support/api/contacts/exportcontacts/) | None | `notify_url`, `list_id`, `field_names`, `email`, `phone`, `tag`, `email_status`, `phone_status`, `contact_status` |
| [`get_contact_count`](#get_contact_count) | [`getContactCount`](https://www.unisender.com/ru/support/api/contacts/getcontactcount/) | `list_id`, `params` | None |
| [`get_lists`](#get_lists) | [`getLists`](https://www.unisender.com/ru/support/api/contacts/getlists/) | None | None |
| [`get_total_contacts_count`](#get_total_contacts_count) | [`getTotalContactsCount`](https://www.unisender.com/ru/support/api/contacts/gettotalcontactscount/) | `login` | None |
| [`import_contacts`](#import_contacts) | [`importContacts`](https://www.unisender.com/ru/support/api/contacts/importcontacts/) | `field_names`, `data` | `overwrite_tags`, `overwrite_lists`, `telegram_bot_channel_id` |
| [`subscribe`](#subscribe) | [`subscribe`](https://www.unisender.com/ru/support/api/contacts/subscribe/) | `list_ids`, `fields` | `tags`, `double_optin`, `overwrite` |
| [`update_list`](#update_list) | [`updateList`](https://www.unisender.com/ru/support/api/contacts/updatelist/) | `list_id`, `title` | `before_subscribe_url`, `after_subscribe_url`, `sub_user_rights` |
| [`is_contact_in_lists`](#is_contact_in_lists) | [`isContactInLists`](https://www.unisender.com/ru/support/api/contacts/iscontactinlists/) | `email`, `list_ids`, `condition` | None |
| [`get_contact`](#get_contact) | [`getContact`](https://www.unisender.com/ru/support/api/contacts/getcontact/) | `email` | `include_lists`, `include_fields`, `include_details` |
| [`unsubscribe`](#unsubscribe) | [`unsubscribe`](https://www.unisender.com/ru/support/api/contacts/unsubscribe/) | `contact_type`, `contact` | `list_ids` |
| [`cancel_campaign`](#cancel_campaign) | [`cancelCampaign`](https://www.unisender.com/ru/support/api/messages/cancel-campaign/) | `campaign_id` | None |
| [`check_email`](#check_email) | [`checkEmail`](https://www.unisender.com/ru/support/api/messages/check-email/) | `email_id` | None |
| [`check_sms`](#check_sms) | [`checkSms`](https://www.unisender.com/ru/support/api/messages/check-sms/) | `sms_id` | None |
| [`create_campaign`](#create_campaign) | [`createCampaign`](https://www.unisender.com/ru/support/api/messages/createcampaign/) | `message_id` | `start_time`, `timezone`, `track_read`, `track_links`, `contacts`, `contacts_url`, `track_ga`, `payment_limit`, `payment_currency`, `ga_medium`, `ga_source`, `ga_campaign`, `ga_content`, `ga_term` |
| [`create_email_message`](#create_email_message) | [`createEmailMessage`](https://www.unisender.com/ru/support/api/messages/createemailmessage/) | `sender_name`, `sender_email`, `list_id` | `subject`, `body`, `text_body`, `generate_text`, `tag`, `attachments`, `lang`, `template_id`, `system_template_id`, `wrap_type`, `categories` |
| [`create_sms_message`](#create_sms_message) | [`createSmsMessage`](https://www.unisender.com/ru/support/api/messages/createsmsmessage/) | `sender`, `body`, `list_id` | `tag` |
| [`delete_message`](#delete_message) | [`deleteMessage`](https://www.unisender.com/ru/support/api/messages/deletemessage/) | `message_id` | None |
| [`get_actual_message_version`](#get_actual_message_version) | [`getActualMessageVersion`](https://www.unisender.com/ru/support/api/messages/get-actual-message-version/) | `message_id` | None |
| [`get_web_version`](#get_web_version) | [`getWebVersion`](https://www.unisender.com/ru/support/api/messages/getwebversion/) | `campaign_id` | None |
| [`send_email`](#send_email) | [`sendEmail`](https://www.unisender.com/ru/support/api/messages/sendemail/) | `email`, `sender_name`, `sender_email`, `subject`, `body`, `list_id` | `attachments`, `lang`, `track_read`, `track_links`, `cc`, `headers`, `images_as`, `ref_key`, `error_checking`, `metadata` |
| [`send_sms`](#send_sms) | [`sendSms`](https://www.unisender.com/ru/support/api/messages/sendsms/) | `phone`, `sender`, `text` | None |
| [`send_test_email`](#send_test_email) | [`sendTestEmail`](https://www.unisender.com/ru/support/api/messages/sendtestemail/) | `email`, `id` | None |
| [`update_email_message`](#update_email_message) | [`updateEmailMessage`](https://www.unisender.com/ru/support/api/messages/updateemailmessage/) | `id` | `sender_name`, `sender_email`, `subject`, `body`, `list_id`, `text_body`, `lang`, `categories` |
| [`update_opt_in_email`](#update_opt_in_email) | [`updateOptInEmail`](https://www.unisender.com/ru/support/api/messages/updateoptinemail/) | `sender_name`, `sender_email`, `subject`, `body`, `list_id` | None |
| [`get_sender_domain_list`](#get_sender_domain_list) | [`getSenderDomainList`](https://www.unisender.com/ru/support/api/messages/getsenderdomainlist/) | `username` | `domain`, `limit`, `offset` |
| [`get_campaign_common_stats`](#get_campaign_common_stats) | [`getCampaignCommonStats`](https://www.unisender.com/ru/support/api/statistics/get-campaign-common-stats/) | `campaign_id` | None |
| [`get_campaign_delivery_stats`](#get_campaign_delivery_stats) | [`async/getCampaignDeliveryStats`](https://www.unisender.com/ru/support/api/statistics/getcampaigndeliverystats/) | `campaign_id` | `notify_url`, `changed_since`, `field_ids` |
| [`get_campaign_status`](#get_campaign_status) | [`getCampaignStatus`](https://www.unisender.com/ru/support/api/statistics/getcampaignstatus/) | `campaign_id` | None |
| [`get_messages`](#get_messages) | [`getMessages`](https://www.unisender.com/ru/support/api/statistics/getmessages/) | `date_from`, `date_to` | `limit`, `offset` |
| [`get_visited_links`](#get_visited_links) | [`getVisitedLinks`](https://www.unisender.com/ru/support/api/statistics/getvisitedlinks/) | `campaign_id` | `group` |
| [`list_messages`](#list_messages) | [`listMessages`](https://www.unisender.com/ru/support/api/statistics/listmessages/) | `date_from`, `date_to` | `limit`, `offset` |
| [`get_campaigns`](#get_campaigns) | [`getCampaigns`](https://www.unisender.com/ru/support/api/statistics/getcampaigns/) | `from` | `to`, `limit`, `offset` |
| [`get_message`](#get_message) | [`getMessage`](https://www.unisender.com/ru/support/api/statistics/getmessage/) | `id` | None |
| [`get_task_result`](#get_task_result) | [`async/getTaskResult`](https://www.unisender.com/ru/support/api/statistics/../contacts/exportcontacts/) | `task_uuid` | None |
| [`create_email_template`](#create_email_template) | [`createEmailTemplate`](https://www.unisender.com/ru/support/api/templates/createemailtemplate/) | `title`, `subject`, `body` | `description`, `text_body`, `lang` |
| [`delete_template`](#delete_template) | [`deleteTemplate`](https://www.unisender.com/ru/support/api/templates/deletetemplate/) | `template_id` | None |
| [`get_template`](#get_template) | [`getTemplate`](https://www.unisender.com/ru/support/api/templates/gettemplate/) | None | `template_id`, `system_template_id` |
| [`get_templates`](#get_templates) | [`getTemplates`](https://www.unisender.com/ru/support/api/templates/gettemplates/) | None | `type`, `date_from`, `date_to`, `limit`, `offset` |
| [`list_templates`](#list_templates) | [`listTemplates`](https://www.unisender.com/ru/support/api/templates/listtemplates/) | None | `type`, `date_from`, `date_to`, `limit`, `offset` |
| [`update_email_template`](#update_email_template) | [`updateEmailTemplate`](https://www.unisender.com/ru/support/api/templates/updateemailtemplate/) | `template_id` | `title`, `description`, `subject`, `body`, `text_body`, `lang` |
| [`create_field`](#create_field) | [`createField`](https://www.unisender.com/ru/support/api/inputs/createfield/) | `name`, `type` | `public_name` |
| [`delete_field`](#delete_field) | [`deleteField`](https://www.unisender.com/ru/support/api/inputs/deletefield/) | `id` | None |
| [`delete_tag`](#delete_tag) | [`deleteTag`](https://www.unisender.com/ru/support/api/inputs/deletetag/) | `id` | None |
| [`get_fields`](#get_fields) | [`getFields`](https://www.unisender.com/ru/support/api/inputs/getfields/) | None | None |
| [`get_tags`](#get_tags) | [`getTags`](https://www.unisender.com/ru/support/api/inputs/gettags/) | None | None |
| [`update_field`](#update_field) | [`updateField`](https://www.unisender.com/ru/support/api/inputs/updatefield/) | `id`, `name` | `public_name` |
| [`get_contact_field_values`](#get_contact_field_values) | [`getContactFieldValues`](https://www.unisender.com/ru/support/api/inputs/getcontactfieldvalues/) | `email`, `field_ids` | None |
| [`create_subscriber_note`](#create_subscriber_note) | [`createSubscriberNote`](https://www.unisender.com/ru/support/api/notes/createsubscibernote/) | `subscriber_id`, `content` | None |
| [`update_subscriber_note`](#update_subscriber_note) | [`updateSubscriberNote`](https://www.unisender.com/ru/support/api/notes/updatesubcribernote/) | `id`, `content` | None |
| [`delete_subscriber_note`](#delete_subscriber_note) | [`deleteSubscriberNote`](https://www.unisender.com/ru/support/api/notes/deletesubscribernote/) | `id` | None |
| [`get_subscriber_note`](#get_subscriber_note) | [`getSubscriberNote`](https://www.unisender.com/ru/support/api/notes/getsubscribernote/) | `id` | None |
| [`get_subscriber_notes`](#get_subscriber_notes) | [`getSubscriberNotes`](https://www.unisender.com/ru/support/api/notes/getsubscribernotes/) | `subscriber_id` | `limit`, `offset`, `order_type`, `order_by`, `is_pinned` |
| `track_events` | [Event Tracking](https://www.unisender.com/ru/support/api/event-tracking-api/) | `events` | None |

## Reading the contracts

Expand an operation below for its accepted Ruby types and result shape. `id` means String or Integer; `flag` means `true`, `false`, `0`, or `1`; `params` means a Hash with String/Symbol keys and form-compatible values. `json` is a JSON value; `object` is a string-keyed Hash and `objects` is an Array of those Hashes. Optional keywords default to `nil` and are omitted on the wire, not sent as null.

Named methods accept Arrays for the documented comma-separated fields and join them before encoding. Other nested arrays and hashes retain bracket indices. An empty String/Array/Hash is rejected for a required value. Method-specific constraints beyond the structural checks are validated by the service; refer to the linked official page for account permissions, current limits, and additional response fields.

Named-operation results are immutable typed records or collections. The wire shapes below describe `response.data`; records expose documented fields and string-key lookup. HTTP metadata uses `response.http_status`. See [the migration guide](migration-0.2.md). Unknown fields remain in `response.data`, even when a result type lists only its guaranteed fields. API errors raise `APIError`, HTTP errors raise `HTTPError`, malformed successful responses raise `InvalidResponseError`, and connection failures raise `TransportError`; none should be interpreted as an empty success. Import and send operations can also return per-record failures inside a successful result.

## Operation contracts

<a id="create_list"></a>
<details>
<summary><code>create_list</code></summary>

[Official `createList` contract](https://www.unisender.com/ru/support/api/contacts/createlist/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `title` | `String` | Required |
| `before_subscribe_url` | `String` | Optional, omitted |
| `after_subscribe_url` | `String` | Optional, omitted |
| `sub_user_rights` | `params` | Optional, omitted |

**Result:** Object with `id`, the new list identifier.

The title must be unique within the account. `sub_user_rights` maps user IDs to rights: `access` uses `view_stats`, `view`, `manage`, or `none`; `send_email` and `send_sms` use flags. A maximum of ten additional users can be configured per call.

</details>

<a id="delete_list"></a>
<details>
<summary><code>delete_list</code></summary>

[Official `deleteList` contract](https://www.unisender.com/ru/support/api/contacts/deletelist/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `list_id` | `id` | Required |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization. Deletes the list; review the upstream consequences before use.

</details>

<a id="exclude"></a>
<details>
<summary><code>exclude</code></summary>

[Official `exclude` contract](https://www.unisender.com/ru/support/api/contacts/exclude/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `contact_type` | `String` | Required |
| `contact` | `String` | Required |
| `list_ids` | `String \| Array[id]` | Optional, omitted |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization. Removes membership in the selected lists.

`contact_type` is `"email"` or `"phone"`. Omitted `list_ids` applies the upstream account-wide behavior; provide explicit IDs when intending to affect selected lists only.

</details>

<a id="export_contacts"></a>
<details>
<summary><code>export_contacts</code></summary>

[Official `async/exportContacts` contract](https://www.unisender.com/ru/support/api/contacts/exportcontacts/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `notify_url` | `String` | Optional, omitted |
| `list_id` | `id` | Optional, omitted |
| `field_names` | `Array[String]` | Optional, omitted |
| `email` | `String` | Optional, omitted |
| `phone` | `String` | Optional, omitted |
| `tag` | `String` | Optional, omitted |
| `email_status` | `String` | Optional, omitted |
| `phone_status` | `String` | Optional, omitted |
| `contact_status` | `String` | Optional, omitted |

**Result:** Object with `task_uuid` and initial `status`. Poll `get_task_result`, or use `wait_for_task`; a completed job provides `file_to_download`.

</details>

<a id="get_contact_count"></a>
<details>
<summary><code>get_contact_count</code></summary>

[Official `getContactCount` contract](https://www.unisender.com/ru/support/api/contacts/getcontactcount/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `list_id` | `id` | Required |
| `params` | `params` | Required |

**Result:** Object with `listId`, `searchParams`, and `count`. The documented `count` is a String, not an Integer.

`params` must contain at least one filter. Use `tagId`, `type` (`"address"` or `"phone"`), and optionally `search`; `search` requires `type`.

</details>

<a id="get_lists"></a>
<details>
<summary><code>get_lists</code></summary>

[Official `getLists` contract](https://www.unisender.com/ru/support/api/contacts/getlists/).

No operation arguments.

**Result:** Array of objects containing `id` and `title`. An account with no lists returns an empty array.

</details>

<a id="get_total_contacts_count"></a>
<details>
<summary><code>get_total_contacts_count</code></summary>

[Official `getTotalContactsCount` contract](https://www.unisender.com/ru/support/api/contacts/gettotalcontactscount/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `login` | `String` | Required |

**Result:** Object with Integer `total`.

</details>

<a id="import_contacts"></a>
<details>
<summary><code>import_contacts</code></summary>

[Official `importContacts` contract](https://www.unisender.com/ru/support/api/contacts/importcontacts/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `field_names` | `Array[String]` | Required |
| `data` | `Array[Array[parameter]]` | Required |
| `overwrite_tags` | `flag` | Optional, omitted |
| `overwrite_lists` | `flag` | Optional, omitted |
| `telegram_bot_channel_id` | `String` | Optional, omitted |

**Result:** Object with Integer counters `total`, `inserted`, `updated`, `deleted`, `new_emails`, and `invalid`; `log` contains per-row `index`, `code`, and `message`. A successful response can include rejected rows. Inspect `invalid` and `log`.

`field_names` must be unique and include `"email"`. Supply 1 to 500 rows with exactly one cell per column. `overwrite_tags` and `overwrite_lists` default to 0; setting them to 1 replaces existing associations. `email_list_ids` is a comma-separated cell, not an Array. `telegram_bot_channel_id` is required upstream when a row contains `telegram_user_id`.

</details>

<a id="subscribe"></a>
<details>
<summary><code>subscribe</code></summary>

[Official `subscribe` contract](https://www.unisender.com/ru/support/api/contacts/subscribe/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `list_ids` | `String \| Array[id]` | Required |
| `fields` | `params` | Required |
| `tags` | `String \| Array[id]` | Optional, omitted |
| `double_optin` | `Integer` | Optional, omitted |
| `overwrite` | `Integer` | Optional, omitted |

**Result:** Object with `person_id`, the contact identifier. Success does not mean the contact has confirmed subscription.

`fields` must include `email`; custom names are case-sensitive. `double_optin` accepts 0 (confirmation email), 3 (prior consent, no confirmation email), or 4 (reuse an already-confirmed contact, otherwise send confirmation). `overwrite` accepts 0 (preserve existing), 1 (replace fields, tags, and list membership), or 2 (update supplied fields). Up to ten tags are allowed.

</details>

<a id="update_list"></a>
<details>
<summary><code>update_list</code></summary>

[Official `updateList` contract](https://www.unisender.com/ru/support/api/contacts/updatelist/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `list_id` | `id` | Required |
| `title` | `String` | Required |
| `before_subscribe_url` | `String` | Optional, omitted |
| `after_subscribe_url` | `String` | Optional, omitted |
| `sub_user_rights` | `params` | Optional, omitted |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization.

</details>

<a id="is_contact_in_lists"></a>
<details>
<summary><code>is_contact_in_lists</code></summary>

[Official `isContactInLists` contract](https://www.unisender.com/ru/support/api/contacts/iscontactinlists/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `email` | `String` | Required |
| `list_ids` | `String \| Array[id]` | Required |
| `condition` | `String` | Required |

**Result:** Boolean `true` or `false`, according to the requested membership condition.

`condition` is `"or"` for any selected list or `"and"` for every selected list.

</details>

<a id="get_contact"></a>
<details>
<summary><code>get_contact</code></summary>

[Official `getContact` contract](https://www.unisender.com/ru/support/api/contacts/getcontact/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `email` | `String` | Required |
| `include_lists` | `flag` | Optional, omitted |
| `include_fields` | `flag` | Optional, omitted |
| `include_details` | `flag` | Optional, omitted |

**Result:** Object with nested `email` contact details. `phone`, `lists`, and custom `fields` depend on the contact and include options. Access the address as `result.fetch("email").fetch("email")`, not `result.fetch("email")` alone.

</details>

<a id="unsubscribe"></a>
<details>
<summary><code>unsubscribe</code></summary>

[Official `unsubscribe` contract](https://www.unisender.com/ru/support/api/contacts/unsubscribe/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `contact_type` | `String` | Required |
| `contact` | `String` | Required |
| `list_ids` | `String \| Array[id]` | Optional, omitted |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization. Unsubscribes the specified contact from the selected lists.

`contact_type` is `"email"` or `"phone"`. Omitted `list_ids` applies the upstream account-wide behavior; provide explicit IDs when intending to affect selected lists only.

</details>

<a id="cancel_campaign"></a>
<details>
<summary><code>cancel_campaign</code></summary>

[Official `cancelCampaign` contract](https://www.unisender.com/ru/support/api/messages/cancel-campaign/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `campaign_id` | `id` | Required |

**Result:** Empty array on success. Cancels a campaign that has not finished sending.

</details>

<a id="check_email"></a>
<details>
<summary><code>check_email</code></summary>

[Official `checkEmail` contract](https://www.unisender.com/ru/support/api/messages/check-email/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `email_id` | `String \| Array[id]` | Required |

**Result:** Array of recipient delivery objects. Each entry can contain `id`, `email`, `status`, and `status_time`. Inspect all recipients.

</details>

<a id="check_sms"></a>
<details>
<summary><code>check_sms</code></summary>

[Official `checkSms` contract](https://www.unisender.com/ru/support/api/messages/check-sms/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `sms_id` | `id` | Required |

**Result:** Object with String `status`. `not_sent` is pending, `ok_sent` means delivery is not confirmed, and `ok_delivered` is delivered; `err_` statuses indicate failures.

</details>

<a id="create_campaign"></a>
<details>
<summary><code>create_campaign</code></summary>

[Official `createCampaign` contract](https://www.unisender.com/ru/support/api/messages/createcampaign/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `message_id` | `id` | Required |
| `start_time` | `String` | Optional, omitted |
| `timezone` | `String` | Optional, omitted |
| `track_read` | `flag` | Optional, omitted |
| `track_links` | `flag` | Optional, omitted |
| `contacts` | `String \| Array[id]` | Optional, omitted |
| `contacts_url` | `String` | Optional, omitted |
| `track_ga` | `flag` | Optional, omitted |
| `payment_limit` | `Integer \| Float` | Optional, omitted |
| `payment_currency` | `String` | Optional, omitted |
| `ga_medium` | `String` | Optional, omitted |
| `ga_source` | `String` | Optional, omitted |
| `ga_campaign` | `String` | Optional, omitted |
| `ga_content` | `String` | Optional, omitted |
| `ga_term` | `String` | Optional, omitted |

**Result:** Object with `campaign_id` and String `status`, such as `scheduled` or `waits_censor`. `count` is deprecated and documented as zero. Accepted does not mean delivered.

`contacts` and `contacts_url` are mutually exclusive. Omitting a schedule starts sending as soon as the service permits. A timeout leaves the send outcome uncertain; this method is never automatically retried.

</details>

<a id="create_email_message"></a>
<details>
<summary><code>create_email_message</code></summary>

[Official `createEmailMessage` contract](https://www.unisender.com/ru/support/api/messages/createemailmessage/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `sender_name` | `String` | Required |
| `sender_email` | `String` | Required |
| `list_id` | `id` | Required |
| `subject` | `String` | Optional, omitted |
| `body` | `String` | Optional, omitted |
| `text_body` | `String` | Optional, omitted |
| `generate_text` | `flag` | Optional, omitted |
| `tag` | `String` | Optional, omitted |
| `attachments` | `Hash[String, String]` | Optional, omitted |
| `lang` | `String` | Optional, omitted |
| `template_id` | `id` | Optional, omitted |
| `system_template_id` | `id` | Optional, omitted |
| `wrap_type` | `String` | Optional, omitted |
| `categories` | `String \| Array[id]` | Optional, omitted |

**Result:** Object with `message_id`. Creates a message without sending it. Pass the identifier to `create_campaign` to send.

Supply nonempty `subject` and `body`, or select `template_id` / `system_template_id` so the template supplies them. Use a verified sender. `attachments` maps filenames to raw file bytes, not file paths or pre-encoded Base64. `lang` controls the unsubscribe text, separately from the client API language.

</details>

<a id="create_sms_message"></a>
<details>
<summary><code>create_sms_message</code></summary>

[Official `createSmsMessage` contract](https://www.unisender.com/ru/support/api/messages/createsmsmessage/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `sender` | `String` | Required |
| `body` | `String` | Required |
| `list_id` | `id` | Required |
| `tag` | `String` | Optional, omitted |

**Result:** Object with `message_id`. Creates a message without sending it.

</details>

<a id="delete_message"></a>
<details>
<summary><code>delete_message</code></summary>

[Official `deleteMessage` contract](https://www.unisender.com/ru/support/api/messages/deletemessage/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `message_id` | `id` | Required |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization.

</details>

<a id="get_actual_message_version"></a>
<details>
<summary><code>get_actual_message_version</code></summary>

[Official `getActualMessageVersion` contract](https://www.unisender.com/ru/support/api/messages/get-actual-message-version/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `message_id` | `id` | Required |

**Result:** Object with `message_id` and `actual_version_id`. Use the latter when a message has a newer active version.

</details>

<a id="get_web_version"></a>
<details>
<summary><code>get_web_version</code></summary>

[Official `getWebVersion` contract](https://www.unisender.com/ru/support/api/messages/getwebversion/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `campaign_id` | `id` | Required |

**Result:** Object with `letter_id` and `web_letter_link`.

</details>

<a id="send_email"></a>
<details>
<summary><code>send_email</code></summary>

[Official `sendEmail` contract](https://www.unisender.com/ru/support/api/messages/sendemail/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `email` | `String` | Required |
| `sender_name` | `String` | Required |
| `sender_email` | `String` | Required |
| `subject` | `String` | Required |
| `body` | `String` | Required |
| `list_id` | `id` | Required |
| `attachments` | `Hash[String, String]` | Optional, omitted |
| `lang` | `String` | Optional, omitted |
| `track_read` | `flag` | Optional, omitted |
| `track_links` | `flag` | Optional, omitted |
| `cc` | `String` | Optional, omitted |
| `headers` | `String \| params` | Optional, omitted |
| `images_as` | `String` | Optional, omitted |
| `ref_key` | `String` | Optional, omitted |
| `error_checking` | `flag` | Optional, omitted |
| `metadata` | `params` | Optional, omitted |

**Result:** With `error_checking: 1` or `cc`, an Array of per-recipient results containing `index`, `email`, and accepted message `id`. Without either, the legacy result is an Object with `email_id`. With `error_checking: 1`, also inspect recipient `errors`; the top-level success envelope alone is insufficient.

Use a verified sender and consenting recipients. `attachments` maps filenames to raw bytes. Set `error_checking: 1` to receive per-recipient errors. Sending is never automatically retried.

</details>

<a id="send_sms"></a>
<details>
<summary><code>send_sms</code></summary>

[Official `sendSms` contract](https://www.unisender.com/ru/support/api/messages/sendsms/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `phone` | `String` | Required |
| `sender` | `String` | Required |
| `text` | `String` | Required |

**Result:** Object containing `sms_id`, `price`, and `currency`. Retain `sms_id` for `check_sms`.

Use the international phone format and an approved sender. Sending is never automatically retried.

</details>

<a id="send_test_email"></a>
<details>
<summary><code>send_test_email</code></summary>

[Official `sendTestEmail` contract](https://www.unisender.com/ru/support/api/messages/sendtestemail/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `email` | `String \| Array[id]` | Required |
| `id` | `id` | Required |

**Result:** The documented top-level Object contains `message`. Sends the test immediately. Legacy `result` envelopes are also accepted.

</details>

<a id="update_email_message"></a>
<details>
<summary><code>update_email_message</code></summary>

[Official `updateEmailMessage` contract](https://www.unisender.com/ru/support/api/messages/updateemailmessage/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |
| `sender_name` | `String` | Optional, omitted |
| `sender_email` | `String` | Optional, omitted |
| `subject` | `String` | Optional, omitted |
| `body` | `String` | Optional, omitted |
| `list_id` | `id` | Optional, omitted |
| `text_body` | `String` | Optional, omitted |
| `lang` | `String` | Optional, omitted |
| `categories` | `String \| Array[id]` | Optional, omitted |

**Result:** Object with `message_id`. Retain the returned identifier because editing an already-sent message can create a new version.

</details>

<a id="update_opt_in_email"></a>
<details>
<summary><code>update_opt_in_email</code></summary>

[Official `updateOptInEmail` contract](https://www.unisender.com/ru/support/api/messages/updateoptinemail/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `sender_name` | `String` | Required |
| `sender_email` | `String` | Required |
| `subject` | `String` | Required |
| `body` | `String` | Required |
| `list_id` | `id` | Required |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization. Updates the list confirmation message.

</details>

<a id="get_sender_domain_list"></a>
<details>
<summary><code>get_sender_domain_list</code></summary>

[Official `getSenderDomainList` contract](https://www.unisender.com/ru/support/api/messages/getsenderdomainlist/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `username` | `String` | Required |
| `domain` | `String` | Optional, omitted |
| `limit` | `Integer` | Optional, omitted |
| `offset` | `Integer` | Optional, omitted |

**Result:** Array of groups containing `status` and `domains`; each domain has fields such as `Domain` and `Status`. Preserve the upstream capitalization. Pagination counts domains, not groups.

</details>

<a id="get_campaign_common_stats"></a>
<details>
<summary><code>get_campaign_common_stats</code></summary>

[Official `getCampaignCommonStats` contract](https://www.unisender.com/ru/support/api/statistics/get-campaign-common-stats/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `campaign_id` | `id` | Required |

**Result:** Object of campaign counters such as `total` and `sent`. Additional fields depend on campaign type.

</details>

<a id="get_campaign_delivery_stats"></a>
<details>
<summary><code>get_campaign_delivery_stats</code></summary>

[Official `async/getCampaignDeliveryStats` contract](https://www.unisender.com/ru/support/api/statistics/getcampaigndeliverystats/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `campaign_id` | `id` | Required |
| `notify_url` | `String` | Optional, omitted |
| `changed_since` | `String` | Optional, omitted |
| `field_ids` | `Array[id]` | Optional, omitted |

**Result:** Object with `task_uuid` and initial `status`, followed by a download URL when the asynchronous report completes.

</details>

<a id="get_campaign_status"></a>
<details>
<summary><code>get_campaign_status</code></summary>

[Official `getCampaignStatus` contract](https://www.unisender.com/ru/support/api/statistics/getcampaignstatus/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `campaign_id` | `id` | Required |

**Result:** Object with String `status`. The full set of campaign states is documented upstream.

</details>

<a id="get_messages"></a>
<details>
<summary><code>get_messages</code></summary>

[Official `getMessages` contract](https://www.unisender.com/ru/support/api/statistics/getmessages/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `date_from` | `String` | Required |
| `date_to` | `String` | Required |
| `limit` | `Integer` | Optional, omitted |
| `offset` | `Integer` | Optional, omitted |

**Result:** Array of message objects, including identifiers, content, sender information, and version metadata. Field availability depends on email versus SMS.

Date filters use UTC `YYYY-MM-DD HH:MM:SS`. `limit` is 1 to 100 (default 50), and `offset` starts at zero.

</details>

<a id="get_visited_links"></a>
<details>
<summary><code>get_visited_links</code></summary>

[Official `getVisitedLinks` contract](https://www.unisender.com/ru/support/api/statistics/getvisitedlinks/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `campaign_id` | `id` | Required |
| `group` | `flag` | Optional, omitted |

**Result:** Object with `fields` (column names) and `data` (rows). Interpret each row using the matching column index.

</details>

<a id="list_messages"></a>
<details>
<summary><code>list_messages</code></summary>

[Official `listMessages` contract](https://www.unisender.com/ru/support/api/statistics/listmessages/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `date_from` | `String` | Required |
| `date_to` | `String` | Required |
| `limit` | `Integer` | Optional, omitted |
| `offset` | `Integer` | Optional, omitted |

**Result:** Array of message summary objects. Use `get_message` when message content is needed.

`limit` is 1 to 100; `offset` starts at zero. See the upstream page for the date range format.

</details>

<a id="get_campaigns"></a>
<details>
<summary><code>get_campaigns</code></summary>

[Official `getCampaigns` contract](https://www.unisender.com/ru/support/api/statistics/getcampaigns/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `from` | `String` | Required |
| `to` | `String` | Optional, omitted |
| `limit` | `Integer` | Optional, omitted |
| `offset` | `Integer` | Optional, omitted |

**Result:** Array of campaign objects with identifiers and campaign metadata. Supports offset pagination.

`from` is required even when paginating. Supply `from` and `to` in UTC as `YYYY-MM-DD HH:MM:SS`, including seconds, for example `"2026-10-01 00:00:00"`. Omitting seconds can produce an `unspecified` API error. `limit` is at most 10,000; `offset` starts at zero.

</details>

<a id="get_message"></a>
<details>
<summary><code>get_message</code></summary>

[Official `getMessage` contract](https://www.unisender.com/ru/support/api/statistics/getmessage/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |

**Result:** Array of message objects, including content and metadata. The upstream example wraps even a single requested message in an Array.

</details>

<a id="get_task_result"></a>
<details>
<summary><code>get_task_result</code></summary>

[Official `async/getTaskResult` contract](https://www.unisender.com/ru/support/api/statistics/../contacts/exportcontacts/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `task_uuid` | `String` | Required |

**Result:** Object whose `status` is `new`, `processing`, or `completed`. A completed export/report contains `file_to_download`. Other task states cause `wait_for_task` to raise `TaskError` with its response.

</details>

<a id="create_email_template"></a>
<details>
<summary><code>create_email_template</code></summary>

[Official `createEmailTemplate` contract](https://www.unisender.com/ru/support/api/templates/createemailtemplate/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `title` | `String` | Required |
| `subject` | `String` | Required |
| `body` | `String` | Required |
| `description` | `String` | Optional, omitted |
| `text_body` | `String` | Optional, omitted |
| `lang` | `String` | Optional, omitted |

**Result:** Object with the new template `id`.

</details>

<a id="delete_template"></a>
<details>
<summary><code>delete_template</code></summary>

[Official `deleteTemplate` contract](https://www.unisender.com/ru/support/api/templates/deletetemplate/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `template_id` | `id` | Required |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization.

</details>

<a id="get_template"></a>
<details>
<summary><code>get_template</code></summary>

[Official `getTemplate` contract](https://www.unisender.com/ru/support/api/templates/gettemplate/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `template_id` | `id` | Optional, omitted |
| `system_template_id` | `id` | Optional, omitted |

**Result:** Object describing the selected template. User and system templates can have different fields; content fields include `subject`, `body`, and `lang_code` where applicable.

Provide `template_id` or `system_template_id`; neither is required individually, but at least one is required.

</details>

<a id="get_templates"></a>
<details>
<summary><code>get_templates</code></summary>

[Official `getTemplates` contract](https://www.unisender.com/ru/support/api/templates/gettemplates/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `type` | `String` | Optional, omitted |
| `date_from` | `String` | Optional, omitted |
| `date_to` | `String` | Optional, omitted |
| `limit` | `Integer` | Optional, omitted |
| `offset` | `Integer` | Optional, omitted |

**Result:** Array of template objects with identifiers, titles, content, and metadata. User-only fields include `body`; system templates can provide preview URLs instead.

`type` is `"user"` (default) or `"system"`. Date filters use UTC `YYYY-MM-DD HH:MM`; system templates ignore them. `limit` is 1 to 100 (default 50), and `offset` starts at zero.

</details>

<a id="list_templates"></a>
<details>
<summary><code>list_templates</code></summary>

[Official `listTemplates` contract](https://www.unisender.com/ru/support/api/templates/listtemplates/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `type` | `String` | Optional, omitted |
| `date_from` | `String` | Optional, omitted |
| `date_to` | `String` | Optional, omitted |
| `limit` | `Integer` | Optional, omitted |
| `offset` | `Integer` | Optional, omitted |

**Result:** Array of template summary objects. Use `get_template` for a selected template.

`type` is `"user"` or `"system"`. Date filters use UTC `YYYY-MM-DD HH:MM`; system templates ignore them. `limit` is 1 to 100 (default 50), and `offset` starts at zero.

</details>

<a id="update_email_template"></a>
<details>
<summary><code>update_email_template</code></summary>

[Official `updateEmailTemplate` contract](https://www.unisender.com/ru/support/api/templates/updateemailtemplate/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `template_id` | `id` | Required |
| `title` | `String` | Optional, omitted |
| `description` | `String` | Optional, omitted |
| `subject` | `String` | Optional, omitted |
| `body` | `String` | Optional, omitted |
| `text_body` | `String` | Optional, omitted |
| `lang` | `String` | Optional, omitted |

**Result:** Object with the updated template `id`.

</details>

<a id="create_field"></a>
<details>
<summary><code>create_field</code></summary>

[Official `createField` contract](https://www.unisender.com/ru/support/api/inputs/createfield/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `name` | `String` | Required |
| `type` | `String` | Required |
| `public_name` | `String` | Optional, omitted |

**Result:** Object with the new field `id`.

</details>

<a id="delete_field"></a>
<details>
<summary><code>delete_field</code></summary>

[Official `deleteField` contract](https://www.unisender.com/ru/support/api/inputs/deletefield/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization.

</details>

<a id="delete_tag"></a>
<details>
<summary><code>delete_tag</code></summary>

[Official `deleteTag` contract](https://www.unisender.com/ru/support/api/inputs/deletetag/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization.

</details>

<a id="get_fields"></a>
<details>
<summary><code>get_fields</code></summary>

[Official `getFields` contract](https://www.unisender.com/ru/support/api/inputs/getfields/).

No operation arguments.

**Result:** Array of custom-field objects with fields such as `id`, `name`, and `type`.

</details>

<a id="get_tags"></a>
<details>
<summary><code>get_tags</code></summary>

[Official `getTags` contract](https://www.unisender.com/ru/support/api/inputs/gettags/).

No operation arguments.

**Result:** Array of tag objects with `id` and `name`.

</details>

<a id="update_field"></a>
<details>
<summary><code>update_field</code></summary>

[Official `updateField` contract](https://www.unisender.com/ru/support/api/inputs/updatefield/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |
| `name` | `String` | Required |
| `public_name` | `String` | Optional, omitted |

**Result:** The documented top-level Object contains the updated field `id`. Legacy `result` envelopes are also accepted.

</details>

<a id="get_contact_field_values"></a>
<details>
<summary><code>get_contact_field_values</code></summary>

[Official `getContactFieldValues` contract](https://www.unisender.com/ru/support/api/inputs/getcontactfieldvalues/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `email` | `String` | Required |
| `field_ids` | `String \| Array[id]` | Required |

**Result:** Object with `fieldValues`, a mapping from string field IDs to their values.

</details>

<a id="create_subscriber_note"></a>
<details>
<summary><code>create_subscriber_note</code></summary>

[Official `createSubscriberNote` contract](https://www.unisender.com/ru/support/api/notes/createsubscibernote/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `subscriber_id` | `id` | Required |
| `content` | `String` | Required |

**Result:** Object with the new note `id`.

</details>

<a id="update_subscriber_note"></a>
<details>
<summary><code>update_subscriber_note</code></summary>

[Official `updateSubscriberNote` contract](https://www.unisender.com/ru/support/api/notes/updatesubcribernote/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |
| `content` | `String` | Required |

**Result:** Object with the edited note `id`.

</details>

<a id="delete_subscriber_note"></a>
<details>
<summary><code>delete_subscriber_note</code></summary>

[Official `deleteSubscriberNote` contract](https://www.unisender.com/ru/support/api/notes/deletesubscribernote/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |

**Result:** Empty JSON result on success. The documented object shape and legacy array responses are preserved without normalization.

</details>

<a id="get_subscriber_note"></a>
<details>
<summary><code>get_subscriber_note</code></summary>

[Official `getSubscriberNote` contract](https://www.unisender.com/ru/support/api/notes/getsubscribernote/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `id` | `id` | Required |

**Result:** Object with `id`, `content`, subscriber/account IDs, origin, pinning information, and timestamps.

</details>

<a id="get_subscriber_notes"></a>
<details>
<summary><code>get_subscriber_notes</code></summary>

[Official `getSubscriberNotes` contract](https://www.unisender.com/ru/support/api/notes/getsubscribernotes/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `subscriber_id` | `id` | Required |
| `limit` | `Integer` | Optional, omitted |
| `offset` | `Integer` | Optional, omitted |
| `order_type` | `String` | Optional, omitted |
| `order_by` | `String` | Optional, omitted |
| `is_pinned` | `flag` | Optional, omitted |

**Result:** Array of note objects for the subscriber. Supports offset pagination.

</details>

<a id="track_events"></a>
<details>
<summary><code>track_events</code></summary>

[Official Event Tracking contract](https://www.unisender.com/ru/support/api/event-tracking-api/).

| Keyword | Ruby type | Presence |
| --- | --- | --- |
| `events` | `Array[Hash]` | Required |

Supply 1 to 25 events. Each event requires a `name` of 1 to 40 characters and an ASCII `email` address, and can contain at most 25 fields including those two. Additional fields must be JSON-compatible values. The encoded request must fit within 130 KiB. Use `track_events_in_batches` for larger collections, or reduce the batch size for large individual events.

**Result:** `{"success" => true}`. Event Tracking uses its own JSON endpoint and bearer authentication. HTTP 400 can mean that valid events were accepted while others failed; inspect `EventError#details` and `possibly_partially_accepted?`. Neither direct calls nor the batch helper automatically retries events. Recording an event can trigger account automation.

</details>

## Documentation decisions

Successful `sendTestEmail` and `updateField` examples omit the `result` envelope. These two operations also accept their documented top-level success fields. Other operations still require `result`, and `error` always takes precedence.


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
