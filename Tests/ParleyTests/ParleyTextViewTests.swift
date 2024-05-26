import SnapshotTesting
import XCTest
@testable import Parley

final class ParleyTextViewTest: XCTestCase {
    
    func testNormalTextWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)

        sut.markdownText = "Hello World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testBoldTextWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)
        
        sut.markdownText = "Hello **Bold** World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testItalicTextWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)
        
        sut.markdownText = "Hello *Italic* World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testTextWithLinkWithDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)

        sut.markdownText = "Hello [Link](https://www.parley.io/) World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testCombinationOfBoldAndItalicAndLinkStyleWithNonDefaultStyle() throws {
        let sut = ParleyTextView(frame: .zero)

        sut.regularFont = try XCTUnwrap(UIFont(name: "Times New Roman", size: 13))
        sut.italicFont = .italicSystemFont(ofSize: 5)
        sut.boldFont = .systemFont(ofSize: 20, weight: .bold)
        sut.tintColor = .red
        sut.linkFont = .italicSystemFont(ofSize: 10)

        sut.markdownText = "Hello *Italic* and **Bold** and [Link](https://www.parley.io/) World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testDynamicFontScalingDefaultStyle() {
        let sut = ParleyTextView(frame: .zero)

        sut.regularFont = .systemFont(ofSize: 14)
        sut.italicFont = .italicSystemFont(ofSize: 5)
        sut.boldFont = .systemFont(ofSize: 20, weight: .bold)
        sut.tintColor = .red
        sut.linkFont = .italicSystemFont(ofSize: 10)

        sut.markdownText = "Hello *Italic* and **Bold** and [Link](https://www.parley.io/) World!"

        assertSnapshot(
            matching: sut,
            as: .image(traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        )
    }

    func testTextIsMultining() {
        let sut = ParleyTextView(frame: .zero)

        sut.markdownText = "Hello World!"

        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 50).isActive = true

        assertSnapshot(matching: sut, as: .image)
    }
}
