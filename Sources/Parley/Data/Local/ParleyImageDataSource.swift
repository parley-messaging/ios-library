import Foundation

public protocol ParleyImageDataSource: AnyObject, ParleyDataSource {

    func all() -> [ParleyLocalImage]
    
    func image(id: ParleyLocalImage.ID) -> ParleyLocalImage?

    func save(images: [ParleyLocalImage])

    func save(image: ParleyLocalImage)
    
    func delete(id: ParleyLocalImage.ID) -> Bool
}
