import Foundation

enum MediaUploadNotificationErrorKind: String, Error, CaseIterable, Codable {
    case invalidMediaType = "invalid_media_type"
    case missingMedia = "missing_media"
    case mediaTooLarge = "media_too_large"
    case couldNotSaveMedia = "could_not_save_media"
    
    var message: String { rawValue }
    
    var formattedMessage: String {
        switch self {
        case .invalidMediaType, .missingMedia, .couldNotSaveMedia:
            return NSLocalizedString("parley_message_meta_failed_to_send", bundle: .current, comment: "")
        case .mediaTooLarge:
            return NSLocalizedString("parley_message_meta_media_too_large", bundle: .current, comment: "")
        }
    }
}
