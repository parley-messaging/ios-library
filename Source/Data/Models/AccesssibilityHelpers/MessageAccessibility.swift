import Foundation

// MARK: - Accessibility - Accessibility Label
extension Message {

    internal struct Accessibility {
     
        static internal func getAccessibilityLabelDescription(_ message: Message) -> String {
            return [
                createAccessibilityMessageLabelIntroduction(message),
                createAccessibilityMessageLabelBody(message),
                createAccessibilityMessageLabelEnding(message)
            ].reduce("") { partialResult, nextString in
                var nextResult = partialResult
                nextResult.appendWithCorrectSpacing(nextString)
                return nextResult
            }
        }
        
        // MARK: Accessibility Label - Introduction
        static private func createAccessibilityMessageLabelIntroduction(_ message: Message) -> String {
            createAccessibilityLabelForMessageType(message)
        }
        
        static private func createAccessibilityLabelForMessageType(_ message: Message) -> String {
            switch message.type {
            case .agent:
                if let agentName = message.agent?.name {
                    let format = "parley_voice_over_message_from_agent_name".localized
                    return .localizedStringWithFormat(format, agentName)
                } else {
                    return "parley_voice_over_message_from_agent".localized
                }
            case .user:
                return "parley_voice_over_message_from_you".localized
            default:
                // TODO: Handle other cases.
                return "message".localized
            }
        }
        
        // MARK: Accessibility Label - Body
        static private func createAccessibilityMessageLabelBody(_ message: Message) -> String {
            return [
                createMessageTextualContentLabelIfAvailable(message),
                createMediumAttachedLabelIfAvailable(message)
            ].compactMap({$0}).joined(separator: " ")
        }
        
        static private func createMessageTextualContentLabelIfAvailable(_ message: Message) -> String? {
            let textualContent = [message.title, message.message]
                .compactMap { $0 }
                .joined(separator: " ")
            
            guard !textualContent.isEmpty else { return nil }
            return textualContent
        }
        
        static private func createMediumAttachedLabelIfAvailable(_ message: Message) -> String? {
            guard message.hasMedium else { return nil }
            return "parley_voice_over_message_media_attached".localized
        }
        
        // MARK: Accessibility Label - Ending
        static private func createAccessibilityMessageLabelEnding(_ message: Message) -> String {
           return [
                createStatusLabelIfNeeded(message),
                createTimeLabelIfAvailable(message)
           ].compactMap { $0 }
            .joined(separator: " ")
        }
        
        static private func createStatusLabelIfNeeded(_ message: Message) -> String? {
            switch message.status {
            case .failed:
                return "parley_voice_over_message_failed".localized
            case .pending:
                return "parley_voice_over_message_pending".localized
            case .success:
                return nil
            }
        }
        
        static private func createTimeLabelIfAvailable(_ message: Message) -> String? {
            guard let time = message.time else { return nil }
            let format = "parley_voice_over_message_time".localized
            return .localizedStringWithFormat(format, time.asTime())
        }
    }
}

// MARK: - Accessibility - Custom Actions
extension Message.Accessibility {
    
    @available(iOS 13, *)
    /// Gets accessibility custom actions for buttons of the message, and provides a action handler when a button is activated.
    /// - Parameter actionHandler: action handler for when a button has been activated.
    /// - Returns: An array of custom actions, nil if the message has no buttons.
    static internal func getAccessibilityCustomActions(
        for message: Message,
        actionHandler: @escaping ((_ message: Message, _ button: MessageButton) -> Void)
    ) -> [UIAccessibilityCustomAction]? {
        guard let buttons = message.buttons, !buttons.isEmpty else { return nil }
        
        var actions = [UIAccessibilityCustomAction]()
        for button in buttons {
            let action = UIAccessibilityCustomAction(name: button.title, actionHandler: { [weak message] action in
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
