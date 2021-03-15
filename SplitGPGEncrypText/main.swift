import Foundation

enum SplitGPGEncrypTextError: Error {
    case missingArgument(argumentName: String)
    case missingArguments(argumentNames: [String])
    case invalidArguments(argumentNames: [String])
    case readFileURLIsNull
    case writeFileURLIsNull
}

struct SplitGPGEncrypText {
    private var readFileURL: String?
    private var writeDirURL: String?
    private var printLogSwitch: String?
    private var splitLineNumbers: Int?
    
    private var isPrintLog: Bool = false
    
    init(arguments: [String] = CommandLine.arguments) throws {
        switch arguments.count {
        case 1:
            throw SplitGPGEncrypTextError.missingArguments(argumentNames: ["read_file_url", "write_dir_url"])
        case 2:
            throw SplitGPGEncrypTextError.missingArgument(argumentName: "write_dir_url")
        case 3:
            self.readFileURL = arguments[1]
            self.writeDirURL = arguments[2]
        case 4:
            self.readFileURL = arguments[1]
            self.writeDirURL = arguments[2]
            self.printLogSwitch = arguments[3]
        case 5:
            self.readFileURL = arguments[1]
            self.writeDirURL = arguments[2]
            self.printLogSwitch = arguments[3]
            self.splitLineNumbers = Int(arguments[4])
        default:
            throw SplitGPGEncrypTextError.invalidArguments(argumentNames: [String](arguments[6..<arguments.count]))
        }
    }
    
    private func printLog(_ text: String) {
        if self.printLogSwitch == "printlog" {
            print(text)
        }
    }
    
    private func checkTargetName(url: URL, targetName: String) -> Bool {
        if url.pathComponents.count == 5 {
            if url.pathComponents[0] == "/" {
                if url.pathComponents[1] == "Users" {
                    if url.pathComponents[2] == NSUserName() {
                        if url.pathComponents[3] == "Desktop" {
                            if url.pathComponents[4] == targetName {
                                return true
                            }
                        }
                    }
                }
            }
            return false
        } else {
            return false
        }
    }
    
    private func createDirectory(baseUrlWithPath: String, directoryName: String) throws -> URL {
        var dirUrl = URL(fileURLWithPath: baseUrlWithPath, isDirectory: true)
        dirUrl.appendPathComponent(directoryName, isDirectory: true)
        if FileManager.default.fileExists(atPath: dirUrl.path) {
            return dirUrl
        } else {
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
            return dirUrl
        }
    }
    
    func splitTextWriteToFiles(text: String, separator: Character, splitLineNumber: Int, baseDirPath: String) throws {
        let textLines = text.split(separator: "\n")
        let linesTotal = textLines.count
        let baseUrl = try createDirectory(baseUrlWithPath: baseDirPath, directoryName: "tmp")
        if linesTotal % splitLineNumber > 0 {
            let splitFileTotal = linesTotal / splitLineNumber + 1
            var lineIndex = 0
            for i in 0..<splitFileTotal {
                let filename = "en_\(i + 1).txt"
                var fileUrl = baseUrl
                fileUrl.appendPathComponent(filename)
                var text = ""
                if i < splitFileTotal - 1 {
                    for _ in 1...splitLineNumber {
                        text += textLines[lineIndex] + "\n"
                        lineIndex += 1
                    }
                    printLog("往 \(fileUrl.absoluteString) 写入：\n\(text)")
                    try text.write(to: fileUrl, atomically: false, encoding: .ascii)
                } else {
                    for _ in 1...(linesTotal % splitLineNumber) {
                        text += textLines[lineIndex] + "\n"
                        lineIndex += 1
                    }
                    printLog("往 \(fileUrl.absoluteString) 写入：\n\(text)")
                    try text.write(to: fileUrl, atomically: false, encoding: .ascii)
                }
            }
        } else {
            let splitFileTotal = linesTotal / splitLineNumber
            var lineIndex = 0
            for i in 0..<splitFileTotal {
                let filename = "en_\(i + 1).txt"
                var fileUrl = baseUrl
                fileUrl.appendPathComponent(filename)
                var text = ""
                for _ in 1...splitLineNumber {
                    text += textLines[lineIndex] + "\n"
                    lineIndex += 1
                }
                printLog("往 \(fileUrl.absoluteString) 写入：\n\(text)")
                try text.write(to: fileUrl, atomically: false, encoding: .ascii)
            }
        }
    }
    
    func readTextFromFile(encoding: String.Encoding = .ascii) throws -> String {
        if let readUrl = self.readFileURL {
            return try String(contentsOf: URL(fileURLWithPath: readUrl), encoding: encoding)
        } else {
            throw SplitGPGEncrypTextError.readFileURLIsNull
        }
    }
}


//let fileText = try readTextFromFile(url: READ_FILE_URL)
//printLog("访问 demo.txt：\n\(fileText)")
//if let n = SPLIT_LINE_NUMBERS {
//    try splitTextWriteToFiles(text: fileText, separator: "\n", splitLineNumber: n)
//} else {
//    try splitTextWriteToFiles(text: fileText, separator: "\n", splitLineNumber: 3)
//}

let splitGpg = try SplitGPGEncrypText()
let fileText = try splitGpg.readTextFromFile()
try splitGpg.splitTextWriteToFiles(text: fileText, separator: "\n", splitLineNumber: 3)

