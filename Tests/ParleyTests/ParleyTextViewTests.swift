import SnapshotTesting
import XCTest
@testable import Parley

final class ParleyTextViewTest: XCTestCase {

    func testNormalTextWithDefaultStyle() {
        let sut = makeSut()

        sut.markdownText = "Hello World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testBoldTextWithDefaultStyle() {
        let sut = makeSut()

        sut.markdownText = "Hello **Bold** World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testItalicTextWithDefaultStyle() {
        let sut = makeSut()

        sut.markdownText = "Hello *Italic* World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testTextWithLinkWithDefaultStyle() {
        let sut = makeSut()

        sut.markdownText = "Hello [Link](https://www.parley.io/) World!"

        assertSnapshot(matching: sut, as: .image)
    }

    func testCombinationOfBoldAndItalicAndLinkStyleWithNonDefaultStyle() throws {
        let sut = makeSut()

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
        let sut = makeSut()

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
        let sut = makeSut()

        sut.markdownText = "Hello World!"

        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 50).isActive = true

        assertSnapshot(matching: sut, as: .image)
    }

    private func makeSut(backgroundColor: UIColor = .lightGray) -> ParleyTextView {
        let sut = ParleyTextView(frame: .zero)
        
        sut.backgroundColor = backgroundColor
        
        return sut
    }
}
