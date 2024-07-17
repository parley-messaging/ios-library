import UIKit

struct ImageDisplayModel: Hashable {
    
    let image: UIImage
    let type: ParleyImageType

    init?(data: Data, type: ParleyImageType) {
        self.type = type

        if type == .imageGif {
            guard let image = UIImage.gif(data: data) else { return nil }
            self.image = image
        } else {
            guard let image = UIImage(data: data) else { return nil }
            self.image = image
        }
    }
}
