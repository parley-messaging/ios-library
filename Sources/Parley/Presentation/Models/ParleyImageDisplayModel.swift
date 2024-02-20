import UIKit

struct ParleyImageDisplayModel: Hashable {
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
    
    static func from(local image: ParleyLocalImage) -> Self? {
        ParleyImageDisplayModel(data: image.data, type: image.type)
    }
    
    static func from(remote image: ParleyImageNetworkModel) -> Self? {
        ParleyImageDisplayModel(data: image.data, type: image.type)
    }
}
