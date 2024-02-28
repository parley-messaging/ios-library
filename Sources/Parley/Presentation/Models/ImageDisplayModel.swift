import UIKit

struct ImageDisplayModel: Hashable {
    let image: UIImage
    let type: ParleyImageType
    
    init?(data: Data, type: ParleyImageType) {
        self.type = type
        
        switch type {
        case .png, .jpg:
            guard let image = UIImage(data: data) else { return nil }
            self.image = image
        case .gif:
            guard let image = UIImage.gif(data: data) else { return nil }
            self.image = image
        }
    }
    
    static func from(stored image: ParleyStoredImage) -> Self? {
        ImageDisplayModel(data: image.data, type: image.type)
    }
    
    static func from(remote image: ParleyImageNetworkModel) -> Self? {
        ImageDisplayModel(data: image.data, type: image.type)
    }
}
