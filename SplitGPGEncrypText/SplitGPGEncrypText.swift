import Foundation

enum SplitGPGEncrypTextError: Error {
    case missingArgument(argumentName: String)
    case missingArguments(argumentNames: [String])
    case invalidArguments(argumentNames: [String])
    case invalidFileUrl(path: String)
    case readFileURLIsNull
    case writeFileURLIsNull
}

struct SplitGPGEncrypText {
    private var readFilePath: String?
    private var writeDirPath: String?
    private var printLogSwitch: String?
    private var splitLineNumbers: Int?
    
    private var isPrintLog: Bool = false
    
    init(arguments: [String] = CommandLine.arguments) throws {
        switch arguments.count {
        case 1:
            throw SplitGPGEncrypTextError.missingArguments(argumentNames: ["read_file_path", "write_dir_path"])
        case 2:
            throw SplitGPGEncrypTextError.missingArgument(argumentName: "write_dir_path")
        case 3:
            self.readFilePath = arguments[1]
            self.writeDirPath = arguments[2]
        case 4:
            self.readFilePath = arguments[1]
            self.writeDirPath = arguments[2]
            self.printLogSwitch = arguments[3]
        case 5:
            self.readFilePath = arguments[1]
            self.writeDirPath = arguments[2]
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
    
    public static func parsePath(path: String) throws -> (basePath: String, targetName: String) {
        let url = URL(fileURLWithPath: path)
        if url.pathComponents.count == 5 {
            if url.pathComponents[0] == "/" {
                if url.pathComponents[1] == "Users" {
                    if url.pathComponents[2] == NSUserName() {
                        if url.pathComponents[3] == "Desktop" {
                            if url.pathComponents[4].count > 0 {
                                var bPath = URL(fileURLWithPath: url.pathComponents[0])
                                bPath.appendPathComponent(url.pathComponents[1])
                                bPath.appendPathComponent(url.pathComponents[2])
                                bPath.appendPathComponent(url.pathComponents[3])
                                return (basePath: bPath.path,
                                        targetName: url.pathComponents[4])
                            }
                        }
                    }
                }
            }
        }
        throw SplitGPGEncrypTextError.invalidFileUrl(path: path)
    }
    
    public static func createDirectory(path: String) throws -> URL {
        let (basePath, directoryName) = try parsePath(path: path)
        var dirUrl = URL(fileURLWithPath: basePath, isDirectory: true)
        dirUrl.appendPathComponent(directoryName, isDirectory: true)
        if FileManager.default.fileExists(atPath: dirUrl.path) {
            try FileManager.default.removeItem(at: dirUrl)
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
            return dirUrl
        } else {
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
            return dirUrl
        }
    }
    
    public func splitTextWriteToFiles(text: String, separator: Character) throws {
        let textLines = text.split(separator: "\n")
        let linesTotal = textLines.count
        let targetUrl = try SplitGPGEncrypText.createDirectory(path: self.writeDirPath!)
        let splitLineNumber = self.splitLineNumbers ?? 3
        if linesTotal % splitLineNumber > 0 {
            let splitFileTotal = linesTotal / splitLineNumber + 1
            var lineIndex = 0
            for i in 1...splitFileTotal {
                let filename = "en_\(i).txt"
                var fileUrl = targetUrl
                fileUrl.appendPathComponent(filename)
                var text = ""
                if i < splitFileTotal {
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
            for i in 1...splitFileTotal {
                let filename = "en_\(i).txt"
                var fileUrl = targetUrl
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
    
    public func readTextFromFile(encoding: String.Encoding = .ascii) throws -> String {
        if let readUrl = self.readFilePath {
            return try String(contentsOf: URL(fileURLWithPath: readUrl), encoding: encoding)
        } else {
            throw SplitGPGEncrypTextError.readFileURLIsNull
        }
    }
    
    public func run() {
        do {
            let fileText = try readTextFromFile()
            printLog("访问 \(self.readFilePath!)")
            try splitTextWriteToFiles(text: fileText, separator: "\n")
        } catch SplitGPGEncrypTextError.readFileURLIsNull {
            print("Read file url is null.")
        } catch {
            print("Running SplitGPGEncrypText throw an unkown error: \(error.localizedDescription)")
        }
    }
}
