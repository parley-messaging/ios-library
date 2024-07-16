import UIKit

struct ImageDisplayModel: Hashable { // TODO: Rename to Media Display Model
    
    let image: UIImage
    let type: ParleyImageType

    init?(data: Data, type: ParleyImageType) {
        self.type = type

        switch type {
        case .imagePng, .imageJPeg, .applicationPdf, .other: // TODO: Determine where this is used and how to display the other types of files
            guard let image = UIImage(data: data) else { return nil }
            self.image = image
        case .imageGif:
            guard let image = UIImage.gif(data: data) else { return nil }
            self.image = image
        }
    }
}
