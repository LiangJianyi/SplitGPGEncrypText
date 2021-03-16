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
    
    private func parsePath(path: String) throws -> (basePath: String, directoryName: String) {
        let url = URL(fileURLWithPath: path)
        if url.pathComponents.count == 5 {
            if url.pathComponents[0] == "/" {
                if url.pathComponents[1] == "Users" {
                    if url.pathComponents[2] == NSUserName() {
                        if url.pathComponents[3] == "Desktop" {
                            if url.pathComponents[4].count > 0 {
                                return (basePath: url.pathComponents[0] + url.pathComponents[1] + url.pathComponents[2] + url.pathComponents[3],
                                        directoryName: url.pathComponents[4])
                            }
                        }
                    }
                }
            }
        }
        throw SplitGPGEncrypTextError.invalidFileUrl(path: path)
    }
    
    private func createDirectory(path: String) throws -> URL {
        let (basePath, directoryName) = try parsePath(path: path)
        var dirUrl = URL(fileURLWithPath: basePath, isDirectory: true)
        dirUrl.appendPathComponent(directoryName, isDirectory: true)
        if FileManager.default.fileExists(atPath: dirUrl.path) {
            return dirUrl
        } else {
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
            return dirUrl
        }
    }
    
    private func splitTextWriteToFiles(text: String, separator: Character) throws {
        let textLines = text.split(separator: "\n")
        let linesTotal = textLines.count
        let targetUrl = try createDirectory(path: self.writeDirURL!)
        let splitLineNumber = self.splitLineNumbers ?? 3
        if linesTotal % splitLineNumber > 0 {
            let splitFileTotal = linesTotal / splitLineNumber + 1
            var lineIndex = 0
            for i in 0..<splitFileTotal {
                let filename = "en_\(i + 1).txt"
                var fileUrl = targetUrl
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
    
    private func readTextFromFile(encoding: String.Encoding = .ascii) throws -> String {
        if let readUrl = self.readFileURL {
            return try String(contentsOf: URL(fileURLWithPath: readUrl), encoding: encoding)
        } else {
            throw SplitGPGEncrypTextError.readFileURLIsNull
        }
    }
    
    func run() {
        do {
            let fileText = try readTextFromFile()
            printLog("访问 demo.txt：\n\(fileText)")
            try splitTextWriteToFiles(text: fileText, separator: "\n")
        } catch SplitGPGEncrypTextError.readFileURLIsNull {
            print("Please input read file url.")
        } catch {
            print("Unkown error: \(error.localizedDescription)")
        }
    }
}



// SplitGPGEncrypText <read_file_path> <output_dir_path> <printlog> <split_line_number>
let splitGpg = try SplitGPGEncrypText(arguments: ["SplitGPGEncrypText", "/Users/jianyiliang/Desktop/demo.txt", "/Users/jianyiliang/Desktop/tmp/", "printlog", "3"])
splitGpg.run()

