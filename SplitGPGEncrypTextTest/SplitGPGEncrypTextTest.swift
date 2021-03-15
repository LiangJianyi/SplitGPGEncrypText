import XCTest

class SplitGPGEncrypTextTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let splitGpg = try SplitGPGEncrypText()
        let fileText = try splitGpg.readTextFromFile(url: "/Users/jianyiliang/Desktop/demo.txt")
        try splitGpg.splitTextWriteToFiles(text: fileText, separator: "\n", splitLineNumber: 3, baseDirPath: "/Users/jianyiliang/Desktop")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
