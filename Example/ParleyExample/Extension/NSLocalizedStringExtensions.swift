import UIKit

func NSLocalizedString(
    _ key: String,
    tableName: String? = nil,
    bundle: Bundle = Bundle.main,
    value: String = ""
) -> String {
    NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: "")
}
