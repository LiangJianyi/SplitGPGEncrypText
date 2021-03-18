import XCTest
import SplitGPGEncrypText

class SplitGPGEncrypTextTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRun() throws {
        let splitGpg = try SplitGPGEncrypText(arguments: ["SplitGPGEncrypText", "/Users/jianyiliang/Desktop/demo.txt", "/Users/jianyiliang/Desktop/tmp/", "printlog", "3"])
        splitGpg.run()
    }
    
    func testParsePath() throws {
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
        let validPaths = [
            "/Users/\(NSUserName())/Desktop/abc",
            "/Users/\(NSUserName())/Desktop/123",
            "/Users/\(NSUserName())/Desktop/456/",
            "/Users/\(NSUserName())/Desktop/aa2dbc",
            "/Users/\(NSUserName())/Desktop/Desktop/",
        ]
        
        for item in invalidPaths {
            XCTAssertThrowsError(try SplitGPGEncrypText.parsePath(path: item))
        }
        for item in validPaths {
            XCTAssertNoThrow(try SplitGPGEncrypText.parsePath(path: item))
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
