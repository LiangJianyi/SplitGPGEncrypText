import XCTest
@testable import SplitGPGEncrypText

private struct FilenameId: Comparable {
    var filename: String
    var id: UInt
    init(dirPath: String) {
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
                      "~/Desktop/qaq",
                      "~/Desktop/onetwothre",
                      "~/Desktop/四五六/",
                      "~/Desktop/✈️💥",
                      "~/Desktop/🪜☁️/",
    ]
    
    func testCreateDirectory() {
        for item in invalidPaths {
            XCTAssertThrowsError(try SplitGPGEncrypText.createDirectory(path: item))
        }
        for item in validPaths {
            XCTAssertNoThrow(try SplitGPGEncrypText.createDirectory(path: item))
        }
        func relativePathToAbsolutePath(atPath: inout String) {
            if atPath[0] == "~" {
                atPath.replaceSubrange(atPath.utf8.startIndex...atPath.utf8.startIndex, with: "/Users/\(NSUserName())")
            }
        }
        for item in validPaths {
            var path = item
            relativePathToAbsolutePath(atPath: &path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path))
            XCTAssertNoThrow(try FileManager.default.removeItem(at: URL(fileURLWithPath: path)))
        }
    }

    let demoFilePath = "/Users/\(NSUserName())/Documents/Xcode/Swift/SplitGPGEncrypText/demo.txt"
    let enFilePath = "/Users/\(NSUserName())/Documents/Xcode/Swift/SplitGPGEncrypText/en.txt"
    let outputDirPath = "/Users/\(NSUserName())/Desktop/tmp2/"
    
    private func sortContentOfDirectory(dirPath: String) -> [String] {
        var filesArray = try! FileManager.default.contentsOfDirectory(atPath: dirPath)
        filesArray = filesArray.map{ filename in
            var res = URL(fileURLWithPath: dirPath).appendingPathComponent(filename).absoluteString
            res.removeFirst(7)
            return res
        }
        filesArray.sort { (e1, e2) in
            let fid1 = FilenameId(dirPath: e1)
            let fid2 = FilenameId(dirPath: e2)
            return fid1 < fid2
        }
        return filesArray
    }
    
    private func combineEncrypText(isChinese: Bool) -> String {
        let encrypFilePaths = self.sortContentOfDirectory(dirPath: self.outputDirPath)
        var text = ""
        for path in encrypFilePaths {
            let s = try! String(
                contentsOf: URL(fileURLWithPath: path),
                encoding: isChinese ? .utf8 : .ascii
            )
            text += s
        }
        return text
    }
    
    // 把切割开来的加密文本重新组合与原始文本进行对比
    private func compareText(sourceFilePath: String, isChinese: Bool = false) -> Bool {
        // 提取原始文本并去除换行符
        let sourceFileText = try! String(contentsOf: URL(fileURLWithPath: sourceFilePath), encoding: .ascii).filter { $0 != "\n" }
        // 把切割开来的加密文本重新组合为 encrypText，然后去除换行符，再与 sourceFileText 进行对比
        var encrypText = ""
        if isChinese {
            // 中文密文转换为PGP密文
            encrypText = String(
                self.combineEncrypText(isChinese: true)
                    .filter { $0 != "\n" }
                    .map { alaphabetConvertor($0, ConvertMode.chineseToEnglish) }
            )
        } else {
            encrypText = self.combineEncrypText(isChinese: false).filter { $0 != "\n" }
        }
        return sourceFileText == encrypText
    }

    func testSplitGPGEncrypTextRun1() {
        let splitLineNumber = 3
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           demoFilePath,
                                                           outputDirPath,
                                                           String(describing: splitLineNumber)])
        XCTAssertNoThrow(splitGpg.run())
        XCTAssertTrue(self.compareText(sourceFilePath: demoFilePath))
    }
    
    func testSplitGPGEncrypTextRun2() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           demoFilePath,
                                                           outputDirPath,
                                                           "printlog",
                                                           "10"])
        XCTAssertNoThrow(splitGpg.run())
        XCTAssertTrue(self.compareText(sourceFilePath: demoFilePath))
    }
    
    func testSplitGPGEncrypTextRun3() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           demoFilePath,
                                                           outputDirPath,
                                                           "printlog",
                                                           "100"])
        XCTAssertNoThrow(splitGpg.run())
        XCTAssertTrue(self.compareText(sourceFilePath: demoFilePath))
    }
    
    func testSplitGPGEncrypTextRun4() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           enFilePath,
                                                           "~/Desktop/tmp2",
                                                           "printlog",
                                                           "10000"])
        XCTAssertNoThrow(splitGpg.run())
        XCTAssertTrue(self.compareText(sourceFilePath: enFilePath))
    }
    
    func testSplitGPGEncrypTextRun5() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           enFilePath,
                                                           outputDirPath,
                                                           "printlog",
                                                           "3000",
                                                           "cn"])
        XCTAssertNoThrow(splitGpg.run())
        XCTAssertTrue(self.compareText(sourceFilePath: enFilePath, isChinese: true))
    }
    
    func testSplitGPGEncrypTextRun6() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           enFilePath,
                                                           outputDirPath,
                                                           "cn",
                                                           "3000"])
        XCTAssertNoThrow(splitGpg.run())
        XCTAssertTrue(self.compareText(sourceFilePath: enFilePath, isChinese: true))
    }
    
    func testSplitGPGEncrypTextRun7() {
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           enFilePath,
                                                           outputDirPath,
                                                           "15300",
                                                           "cn"])
        XCTAssertNoThrow(splitGpg.run())
        XCTAssertTrue(self.compareText(sourceFilePath: enFilePath, isChinese: true))
    }
    
    func testReadFileLineByLineAndSplitTextWriteToFiles() {
        let en = "/Users/\(NSUserName())/Documents/Xcode/Swift/SplitGPGEncrypText/test2.txt"
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           en,
                                                           outputDirPath,
                                                           "20300"])
        XCTAssertNoThrow(try! splitGpg.readFileLineByLineAndSplitTextWriteToFiles())
        XCTAssertTrue(self.compareText(sourceFilePath: en, isChinese: false))
    }
    
    func testReadFileLineByLineAndSplitTextWriteToFiles2() {
        let en = "/Users/\(NSUserName())/Documents/Xcode/Swift/SplitGPGEncrypText/test2.txt"
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           en,
                                                           outputDirPath])
        XCTAssertNoThrow(try! splitGpg.readFileLineByLineAndSplitTextWriteToFiles())
        XCTAssertTrue(self.compareText(sourceFilePath: en, isChinese: false))
    }
    
    func testReadFileLineByLineAndSplitTextWriteToFiles3() {
        let en = "/Users/\(NSUserName())/Documents/Xcode/Swift/SplitGPGEncrypText/test2.txt"
        let splitGpg = try! SplitGPGEncrypText(arguments: ["SplitGPGEncrypText",
                                                           en,
                                                           outputDirPath,
                                                           "3000",
                                                           "cn"])
        XCTAssertNoThrow(try! splitGpg.readFileLineByLineAndSplitTextWriteToFiles())
        XCTAssertTrue(self.compareText(sourceFilePath: en, isChinese: true))
    }

    
    func testAlaphabetConvertor() {
        for e_c in englishToChinese {
            XCTAssertTrue(chineseToEnglish[e_c.value]! == e_c.key)
        }
    }
    
    /*
     运行完所有的单元测试后需要手动删除桌面目录遗留的 tmp 和 tmp2 文件夹
     */
}
