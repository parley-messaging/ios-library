import Foundation

public enum ParleyLocalizationKey: String {
    case cancel = "parley_cancel"
    case ok = "parley_ok"
    case stateFailed = "parley_state_failed"
    case stateUnconfigured = "parley_state_unconfigured"
    case close = "parley_close"

    // MARK: Notifications
    case pushDisabled = "parley_push_disabled"
    case notificationOffline = "parley_notification_offline"

    // MARK: Photos
    case photo = "parley_photo"
    case selectPhoto = "parley_select_photo"
    case takePhoto = "parley_take_photo"
    case photoAccessDeniedTitle = "parley_photo_access_denied_title"
    case photoAccessDeniedBody = "parley_photo_access_denied_body"

    case messageMetaFailedToSend = "parley_message_meta_failed_to_send"
    case messageMetaMediaTooLarge = "parley_message_meta_media_too_large"

    case sendFailedTitle = "parley_send_failed_title"
    case sendFailedBodySelectingImage = "parley_send_failed_body_selecting_image"
    case sendFailedBodyMediaInvalid = "parley_send_failed_body_media_invalid"
    case sendFailedBodyMediaTooLarge = "parley_send_failed_body_media_too_large"

    // MARK: Message Compose View
    case typeMessage = "parley_type_message"

    // MARK: - Accessibility - Voice Over
    // MARK: Message Compose View
    case voiceOverCameraButtonLabel = "parley_voice_over_camera_button_label"
    case voiceOverSendButtonLabel = "parley_voice_over_send_button_label"
    case voiceOverSendButtonDisabledHint = "parley_voice_over_send_button_disabled_hint"
    case voiceOverDismissKeyboardAction = "parley_voice_over_dismiss_keyboard_action"

    // MARK: Message
    case voiceOverMessageFromAgentName = "parley_voice_over_message_from_agent_name"
    case voiceOverMessageFromAgent = "parley_voice_over_message_from_agent"
    case voiceOverMessageFromYou = "parley_voice_over_message_from_you"
    case voiceOverMessageMediaAttached = "parley_voice_over_message_media_attached"
    case voiceOverMessageFailed = "parley_voice_over_message_failed"
    case voiceOverMessagePending = "parley_voice_over_message_pending"
    case voiceOverMessageTime = "parley_voice_over_message_time"
    case voiceOverMessageAgentIsTyping = "parley_voice_over_message_agent_is_typing"
    case voiceOverMessageInformational = "parley_voice_over_message_informational"
    case voiceOverMessageLoading = "parley_voice_over_message_loading"
    case voiceOverMessageActionsAttached = "parley_voice_over_message_actions_attached"

    // MARK: Announcements
    case voiceOverAnnouncementSentMessage = "parley_voice_over_announcement_sent_message"
    case voiceOverAnnouncementAgentTyping = "parley_voice_over_announcement_agent_typing"
    case voiceOverAnnouncementMessageReceived = "parley_voice_over_announcement_message_received"
    case voiceOverAnnouncementInfoMessageReceived = "parley_voice_over_announcement_info_message_received"
    case voiceOverAnnouncementQuickRepliesReceived = "parley_voice_over_announcement_quick_replies_received"
}
