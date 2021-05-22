import XCTest
@testable import SplitGPGEncrypText

// 给 String 添加下标访问
extension String {
    public subscript(_ i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
}

struct FilenameId: Comparable {
    public var filename: String
    public var id: UInt
    public init(dirPath: String) {
        let url = URL(fileURLWithPath: dirPath)
        let filename = url.lastPathComponent
        if filename[0] == "e" {
            if filename[1] == "n" {
                if filename[2] == "_" {
                    let (id, lastIndex) = FilenameId.checkDigital(text: filename, startIndex: 3)
                    if let n = id {
                        if FilenameId.checkSuffix(text: filename, index: lastIndex, expectSuffix: ".txt") {
                            self.filename = filename
                            self.id = n
                            return
                        }
                    }
                }
            }
        }
        fatalError("\(dirPath) 不是个合法的文件。")
    }
    
    public static func < (lhs: FilenameId, rhs: FilenameId) -> Bool {
        return lhs.id < rhs.id
    }
    
    private static func checkDigital(text: String, startIndex: Int) -> (id: UInt?, lastIndex: Int) {
        let digitSymbols: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        var idText = ""
        var i = startIndex
        while startIndex < text.count {
            if digitSymbols.contains(text[i]) {
                idText += String(text[i])
            } else {
                break
            }
            i += 1
        }
        return (UInt(idText), i)
    }

    private static func checkSuffix(text: String, index: Int, expectSuffix: String) -> Bool {
        var suffix = ""
        for i in index..<text.count {
            suffix.append(text[i])
        }
        return suffix == expectSuffix
    }
}

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

    let inputFilePath = "/Users/jianyiliang/Desktop/demo.txt"
    let outputDirPath = "/Users/jianyiliang/Desktop/tmp/"
    
    private func sortContentOfDirectory(dirPath: String) -> [String] {
        var arr = try! FileManager.default.contentsOfDirectory(atPath: dirPath)
        arr = arr.map{ e in
            var res = URL(fileURLWithPath: dirPath).appendingPathComponent(e).absoluteString
            res.removeFirst(7)
            return res
        }
        arr.sort { (e1, e2) in
            let fid1 = FilenameId(dirPath: e1)
            let fid2 = FilenameId(dirPath: e2)
            return fid1 < fid2
        }
        return arr
    }
    
    private func combineEncrypText() -> String {
        let encrypFilePaths = self.sortContentOfDirectory(dirPath: self.outputDirPath)
        var text = ""
        for path in encrypFilePaths {
            let s = try! String(contentsOf: URL(fileURLWithPath: path), encoding: .ascii)
            text += s
        }
        return text
    }
    
    // 把切割开来的加密文本重新组合与原始文本进行对比
    private func compareText() {
        // 提取原始文本并去除换行符
        let sourceFileText = try! String(contentsOf: URL(fileURLWithPath: self.inputFilePath), encoding: .ascii).filter { $0 != "\n" }
        // 把切割开来的加密文本重新组合为 encrypText，然后去除换行符，再与 sourceFileText 进行对比
        let encrypText = self.combineEncrypText().filter { $0 != "\n" }
        // 检查一下字符编码，是不是编码引起的不相等
        XCTAssertTrue(sourceFileText == encrypText)
    }

    func testSplitGPGEncrypTextRun1() {
        let splitLineNumber = 3
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           inputFilePath,
                                                           outputDirPath,
                                                           String(describing: splitLineNumber)])
        XCTAssertNoThrow(splitGpg.run())
        self.compareText()
    }
    
    func testSplitGPGEncrypTextRun2() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           inputFilePath,
                                                           outputDirPath,
                                                           "printlog",
                                                           "10"])
        XCTAssertNoThrow(splitGpg.run())
        self.compareText()
    }
    
    func testSplitGPGEncrypTextRun3() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           inputFilePath,
                                                           outputDirPath,
                                                           "printlog",
                                                           "100"])
        XCTAssertNoThrow(splitGpg.run())
        self.compareText()
    }
}
