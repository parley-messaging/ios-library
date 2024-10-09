import Foundation
import UIKit

// MARK: - Accessibility - Accessibility Label
extension Message {

    enum Accessibility {

        static func getAccessibilityLabelDescription(for message: Message) -> String? {
            guard message.type != .date else { return nil }
            return [
                createAccessibilityLabelForMessageType(message),
                createAccessibilityMessageLabelBody(message),
                createAccessibilityMessageLabelEnding(message),
            ].compactMap({ $0 }).reduce("") { partialResult, nextString in
                var nextResult = partialResult
                nextResult.appendWithCorrectSpacing(nextString)
                return nextResult
            }
        }

        private static func createAccessibilityLabelForMessageType(_ message: Message) -> String? {
            switch message.type {
            case .agent, .systemMessageAgent:
                if let agentName = message.agent?.name {
                    ParleyLocalizationKey.voiceOverMessageFromAgentName.localized(arguments: agentName)
                } else {
                    ParleyLocalizationKey.voiceOverMessageFromAgent.localized()
                }
            case .user, .systemMessageUser:
                ParleyLocalizationKey.voiceOverMessageFromYou.localized()
            case .loading:
                ParleyLocalizationKey.voiceOverMessageLoading.localized()
            case .agentTyping:
                ParleyLocalizationKey.voiceOverMessageAgentIsTyping.localized()
            case .info, .auto:
                ParleyLocalizationKey.voiceOverMessageInformational.localized()
            default:
                nil
            }
        }

        // MARK: Accessibility Label - Body
        private static func createAccessibilityMessageLabelBody(_ message: Message) -> String {
            var body = [
                createMessageTextualContentLabelIfAvailable(message),
                createMediumAttachedLabelIfAvailable(message),
            ].compactMap({ $0 }).joined(separator: " ")

            switch body.last {
            case ".", "?", "!":
                return body
            default:
                body.append(".")
                return body
            }
        }

        private static func createMessageTextualContentLabelIfAvailable(_ message: Message) -> String? {
            let textualContent = [message.title, message.message]
                .compactMap { $0 }
                .joined(separator: ". ")

            guard !textualContent.isEmpty else { return nil }
            return textualContent
        }

        private static func createMediumAttachedLabelIfAvailable(_ message: Message) -> String? {
            guard message.hasMedium else { return nil }
            return ParleyLocalizationKey.voiceOverMessageMediaAttached.localized()
        }

        // MARK: Accessibility Label - Ending
        private static func createAccessibilityMessageLabelEnding(_ message: Message) -> String {
            [
                createStatusLabelIfNeeded(message),
                createTimeLabelIfAvailable(message),
            ].compactMap { $0 }
                .joined(separator: " ")
        }

        private static func createStatusLabelIfNeeded(_ message: Message) -> String? {
            switch message.status {
            case .failed:
                ParleyLocalizationKey.voiceOverMessageFailed.localized()
            case .pending:
                ParleyLocalizationKey.voiceOverMessagePending.localized()
            case .success:
                nil
            }
        }

        private static func createTimeLabelIfAvailable(_ message: Message) -> String? {
            guard let time = message.time else { return nil }
            return ParleyLocalizationKey.voiceOverMessageTime.localized(arguments: time.asTime())
        }
    }
}

// MARK: - Accessibility - Accessibility Announcement
extension Message.Accessibility {

    static func getAccessibilityAnnouncement(for message: Message) -> String? {
        let messageArray: [String?]

        switch message.type {
        case .agent, .systemMessageAgent:
            if message.quickReplies?.isEmpty == false {
                return ParleyLocalizationKey.voiceOverAnnouncementQuickRepliesReceived.localized()
            } else {
                messageArray = [
                    ParleyLocalizationKey.voiceOverAnnouncementMessageReceived.localized(),
                    Self.getAccessibilityLabelDescription(for: message),
                    Self.createActionsAttachedLabelIfAvailable(message),
                ]
            }
        case .info, .auto:
            messageArray = [
                ParleyLocalizationKey.voiceOverAnnouncementInfoMessageReceived.localized(),
                message.message,
            ]
        default:
            return nil
        }

        return messageArray
            .compactMap({ $0 }).reduce("") { partialResult, nextString in
                var nextResult = partialResult
                nextResult.appendWithCorrectSpacing(nextString)
                return nextResult
            }
    }

    private static func createActionsAttachedLabelIfAvailable(_ message: Message) -> String? {
        guard message.hasButtons else { return nil }
        return ParleyLocalizationKey.voiceOverMessageActionsAttached.localized()
    }
}

// MARK: - Accessibility - Custom Actions
extension Message.Accessibility {

    /// Gets accessibility custom actions for buttons of the message, and provides a action handler when a button is
    /// activated.
    /// - Parameters:
    ///  - message: A chat message to base the custom accessibility actions on.
    ///  - actionHandler: action handler for when a button has been activated.
    /// - Returns: An array of custom actions, nil if the message has no buttons.
    static func getAccessibilityCustomActions(
        for message: Message,
        actionHandler: @escaping ((_ message: Message, _ button: MessageButton) -> Void)
    ) -> [UIAccessibilityCustomAction]? {
        guard let buttons = message.buttons, !buttons.isEmpty else { return nil }

        var actions = [UIAccessibilityCustomAction]()
        for button in buttons {
            let action = UIAccessibilityCustomAction(name: button.title, actionHandler: { [weak message] _ in
                guard let message else { return false }
                actionHandler(message, button)
                return true
            })

            action.accessibilityTraits = [.button]
            actions.append(action)
        }

        return actions
    }
}
