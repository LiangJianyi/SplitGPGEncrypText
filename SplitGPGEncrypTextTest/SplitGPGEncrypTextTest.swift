import XCTest
@testable import SplitGPGEncrypText

final class SplitGPGEncrypTextTest: XCTestCase {
    func testSplitGPGEncrypTextRun() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText", "/Users/jianyiliang/Desktop/demo.txt", "/Users/jianyiliang/Desktop/tmp/", "printlog", "3"])
        XCTAssertNoThrow(splitGpg.run())
    }
    
    /*
     检测那些目录属于Desktop下的子目录
     */
    let invalidPaths = ["/Applications",
                        "/System",
                        "/System/Library",
                        "/bin",
                        "/bin/cp",
                        "/bin/dd",
                        "/bin/pwd",
                        "/bin/rm",
                        "/bin/zsh",
                        "/aa/bb/cc/dd/ee/ff/gg/123/456/789/",
    ]
    let validPaths = ["/Users/\(NSUserName())/Desktop/abc",
                      "/Users/\(NSUserName())/Desktop/123",
                      "/Users/\(NSUserName())/Desktop/456/",
                      "/Users/\(NSUserName())/Desktop/aa2dbc",
                      "/Users/\(NSUserName())/Desktop/Desktop/",
    ]
    
    func testCreateDirectory() {
        for item in invalidPaths {
            XCTAssertThrowsError(try SplitGPGEncrypText.createDirectory(path: item))
        }
        for item in validPaths {
            XCTAssertNoThrow(try SplitGPGEncrypText.createDirectory(path: item))
        }
        for item in validPaths {
            XCTAssertTrue(FileManager.default.fileExists(atPath: item))
            XCTAssertNoThrow(try FileManager.default.removeItem(at: URL(fileURLWithPath: item)))
        }
    }

    func testFuck() {
        print("fuck you")
        XCTAssertFalse(1 == 2)
    }

}
