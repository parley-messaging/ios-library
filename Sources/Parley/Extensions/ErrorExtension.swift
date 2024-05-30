import Foundation

extension Error {

    func getFormattedMessage() -> String {
        guard
            let parleyResponse = self as? ParleyErrorResponse,
            let parleyMessage = parleyResponse.notifications.first?.message else
        {
            return localizedDescription
        }
        return parleyMessage
    }
}
