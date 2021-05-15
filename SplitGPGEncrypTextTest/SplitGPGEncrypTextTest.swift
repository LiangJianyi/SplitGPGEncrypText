import XCTest
@testable import SplitGPGEncrypText

final class SplitGPGEncrypTextTest: XCTestCase {
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
    
    private func sortContentOfDirectory(dirPath: String) -> [String] {
        var arr = try! FileManager.default.contentsOfDirectory(atPath: dirPath)
        arr.sort()
        arr = arr.map{ e in
            var res = URL(fileURLWithPath: dirPath).appendingPathComponent(e).absoluteString
            res.removeFirst(7)
            return res
        }
        return arr
    }
    
    private func combineEncrypText() {
        
    }

    let inputFilePath = "/Users/jianyiliang/Desktop/demo.txt"
    let outputDirPath = "/Users/jianyiliang/Desktop/tmp/"
    
    func testSplitGPGEncrypTextRun1() {
        let splitLineNumber = 3
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           inputFilePath,
                                                           outputDirPath,
                                                           "printlog",
                                                           String(describing: splitLineNumber)])
        XCTAssertNoThrow(splitGpg.run())
    }
    
    func testSplitGPGEncrypTextRun2() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText", inputFilePath, outputDirPath, "printlog", "10"])
        XCTAssertNoThrow(splitGpg.run())
    }
    
    func testSplitGPGEncrypTextRun3() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText", inputFilePath, outputDirPath, "printlog", "100"])
        XCTAssertNoThrow(splitGpg.run())
    }
}
