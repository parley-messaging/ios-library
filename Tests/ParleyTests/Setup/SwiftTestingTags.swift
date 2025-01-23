import Testing
import SnapshotTesting

extension Tag {
    @Tag static var userInterface: Self
}

extension SnapshotTestingConfiguration.DiffTool {
    
    static let compareSideBySide = Self {
        "convert \"\($0)\" \"\($1)\" +append png:- | open -f -a Preview.app"
    }
    
    static let compareStackedVertically = Self {
        "convert \"\($0)\" \"\($1)\" -append png:- | open -f -a Preview.app"
    }
    
    static let compareDifferenceOverlay = Self {
        "compare -compose src \"\($0)\" \"\($1)\" png:- | open -f -a Preview.app"
    }
}
