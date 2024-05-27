import SnapshotTesting
import XCTest
@testable import Parley

final class ParleyTextViewTest: XCTestCase {
    
    func testNormalTextWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)
        sut.backgroundColor = .lightGray

        sut.markdownText = "Hello World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testBoldTextWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)
        sut.backgroundColor = .lightGray
        
        sut.markdownText = "Hello **Bold** World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testItalicTextWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)
        sut.backgroundColor = .lightGray
        
        sut.markdownText = "Hello *Italic* World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testTextWithLinkWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)
        sut.backgroundColor = .lightGray
        
        sut.markdownText = "Hello [Link](https://www.parley.io/) World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testCombinationOfBoldAndItalicAndLinkStyleWithNonDefaultStyle() throws {
        let sut = ParleyTextView(frame: .zero)
        sut.backgroundColor = .lightGray
        
        let appearance = ParleyTextViewAppearance()
        
        appearance.regularFont = try XCTUnwrap(UIFont(name: "Times New Roman", size: 13))
        appearance.italicFont = .italicSystemFont(ofSize: 5)
        appearance.boldFont = .systemFont(ofSize: 20, weight: .bold)
        appearance.linkTintColor = .red
        appearance.linkFont = .italicSystemFont(ofSize: 10)

        sut.appearance = appearance
        
        sut.markdownText = "Hello *Italic* and **Bold** and [Link](https://www.parley.io/) World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testDynamicFontScalingDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)
        sut.backgroundColor = .lightGray
        
        let appearance = ParleyTextViewAppearance()
        
        appearance.regularFont = .systemFont(ofSize: 14)
        appearance.italicFont = .italicSystemFont(ofSize: 5)
        appearance.boldFont = .systemFont(ofSize: 20, weight: .bold)
        appearance.linkTintColor = .red
        appearance.linkFont = .italicSystemFont(ofSize: 10)

        sut.appearance = appearance
        
        sut.markdownText = "Hello *Italic* and **Bold** and [Link](https://www.parley.io/) World!"

        assertSnapshot(
            matching: sut,
            as: .image(traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        )
    }

    func testTextIsMultining() {
        let sut = ParleyTextView(frame: .zero)
        sut.backgroundColor = .lightGray
        
        sut.markdownText = "Hello World!"

        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 50).isActive = true

        assertSnapshot(matching: sut, as: .image)
    }
}
