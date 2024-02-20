import Foundation

public protocol ParleyImageDataSource: AnyObject {

    func all() -> [ParleyLocalImage]?
    
    func image(id: ParleyLocalImage.ID) -> ParleyLocalImage?

    func save(_ images: [ParleyLocalImage])

    func save(_ image: ParleyLocalImage)
    
    func delete(id: ParleyLocalImage.ID)
}
