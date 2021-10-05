import Foundation

// 给 String 添加下标访问
extension String {
    public subscript(_ i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
}

enum SplitGPGEncrypTextError: Error {
    case missingArgument(argumentName: String)
    case missingArguments(argumentNames: [String])
    case invalidArguments(argumentNames: [String])
    case invalidArgument(argumentName: String)
    case invalidFileUrl(path: String)
    case readFileURLIsNull
    case writeFileURLIsNull
}

struct SplitGPGEncrypText {
    private var readFilePath: String?
    private var writeDirPath: String?
    private var splitLineNumbers: Int?
    private var isPrintLog: Bool = false
    private var englishToChinese: Bool = false
    private var parallelProcess: Bool = false
    
    init(arguments: [String] = CommandLine.arguments) throws {
        switch arguments.count {
        case 1:
            throw SplitGPGEncrypTextError.missingArguments(argumentNames: ["read_file_path", "write_dir_path"])
        case 2:
            throw SplitGPGEncrypTextError.missingArgument(argumentName: "write_dir_path")
        case 3:
            self.readFilePath = arguments[1]
            self.writeDirPath = arguments[2]
            self.splitLineNumbers = 3
        default:
            self.readFilePath = arguments[1]
            self.writeDirPath = arguments[2]
            self.parseOptionArguments(arguments: [String](arguments[3..<arguments.count]))
        }
    }
    
    private func printLog(_ text: String) {
        if self.isPrintLog {
            print(text)
            print()
        }
    }
    
    private func writeTextToFile(fileUrl: URL, text: String) throws {
        if self.englishToChinese {
            let chinese = String(text.map { alaphabetConvertor($0, .englishToChinese) })
            printLog(chinese)
            try chinese.write(to: fileUrl, atomically: false, encoding: .utf8)
        } else {
            printLog(text)
            try text.write(to: fileUrl, atomically: false, encoding: .ascii)
        }
    }
    
    private mutating func parseOptionArguments(arguments: [String]) {
        for arg in arguments {
            switch arg {
            case "printlog":
                if self.isPrintLog {
                    fatalError("错误❌ 重复的参数：\(arg)")
                } else {
                    self.isPrintLog = true
                }
            case "cn":
                if self.englishToChinese {
                    fatalError("错误❌ 重复的参数：\(arg)")
                } else {
                    self.englishToChinese = true
                }
            case "parallel":
                if self.parallelProcess {
                    fatalError("错误❌ 重复的参数：\(arg)")
                } else {
                    self.parallelProcess = true
                }
            default:
                if let n = Int(arg) {
                    if self.splitLineNumbers != nil {
                        fatalError("错误❌ 重复的参数：\(arg)")
                    } else {
                        self.splitLineNumbers = n
                    }
                } else {
                    fatalError("错误❌ 重复的参数：\(arg)")
                }
            }
        }
    }
    
    public static func parsePath(path: String) throws -> (basePath: String, targetName: String) {
        var path = path
        if path[0] == "~" {
            path.replaceSubrange(path.utf8.startIndex...path.utf8.startIndex, with: "/Users/\(NSUserName())")
        }
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
        
        // 如果输出目录已经存在，则删除掉重新创建
        if FileManager.default.fileExists(atPath: dirUrl.path) {
            try FileManager.default.removeItem(at: dirUrl)
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
            return dirUrl
        } else {
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
            return dirUrl
        }
    }
    
    /// 逐行读取文本并根据指定的步长（self.splitLineNumbers）切割文本然后写入到指定目录（self.writeDirPath）
    public func readFileLineByLineAndSplitTextWriteToFiles() throws {
        // 确保文件存在
        guard FileManager.default.fileExists(atPath: self.readFilePath!) else {
            throw SplitGPGEncrypTextError.invalidFileUrl(path: self.readFilePath!)
        }

        // 使用系统调用 fopen 打开并读取文件（参数 r 为读取 flag），返回一个文件指针
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(self.readFilePath!, "r") else {
            fatalError("Could not open file at \(self.readFilePath!)")
        }
        defer {
            // 关闭文件流
            #if DEBUG
            print("Close the file: \(self.readFilePath!)")
            #endif
            fclose(filePointer)
        }

        // a pointer to a null-terminated, UTF-8 encoded sequence of bytes
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil

        // the smallest multiple of 16 that will fit the byte array for this line
        var lineCap: Int = 0
        
        // 创建切割文件目录
        let writeDirUrl = try SplitGPGEncrypText.createDirectory(path: self.writeDirPath!)

        // 初始化迭代器
        var bytesReader = getline(&lineByteArrayPointer, &lineCap, filePointer)
        
        var fileId = 1
        var lineNumber = 1
        var fileUrl = writeDirUrl.appendingPathComponent("en_\(fileId).txt")
        // 逐行写入
        while bytesReader > 0 {
            // note: this translates the sequence of bytes to a string using UTF-8 interpretation
            let currentLine = String(cString: lineByteArrayPointer!, encoding: .ascii)!
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                let fileHandle = try FileHandle(forWritingTo: fileUrl)
                defer {
                    // 关闭文件句柄
                    #if DEBUG
                    print("Close the file handler: \(fileUrl)")
                    #endif
                    fileHandle.closeFile()
                }
                fileHandle.seekToEndOfFile()
                fileHandle.write(currentLine.data(using: .ascii)!)
                printLog(currentLine)
            } else {
                print("往 \(fileUrl) 写入\n")
                // 无需开启 atomically 进行原子写入，
                // 当前 else 分支属于该文件暂不存在
                try currentLine.write(to: fileUrl, atomically: false, encoding: .utf8)
            }
            
            // 更新读取的字节数，用于下一次迭代
            bytesReader = getline(&lineByteArrayPointer, &lineCap, filePointer)
            
            // 更新行数和文件编号
            if lineNumber < self.splitLineNumbers! {
                lineNumber += 1
            } else {
                lineNumber = 1
                fileId += 1
                fileUrl = writeDirUrl.appendingPathComponent("en_\(fileId).txt")
            }
        }
    }
    
    public func splitTextWriteToFiles(text: String, separator: Character) throws {
        let textLines = text.split(separator: "\n")
        let linesTotal = textLines.count
        let targetUrl = try SplitGPGEncrypText.createDirectory(path: self.writeDirPath!)

        if self.splitLineNumbers! < 1 {
            fatalError("Invalid splitLineNumbers argument. splitLineNumbers=\(self.splitLineNumbers!)")
        }
        
        if linesTotal % self.splitLineNumbers! > 0 {
            let splitFileTotal = linesTotal / self.splitLineNumbers! + 1
            var lineIndex = 0
            for fileID in 1...splitFileTotal {
                let filename = "en_\(fileID).txt"
                var fileUrl = targetUrl
                fileUrl.appendPathComponent(filename)
                print("往 \(fileUrl.absoluteString) 写入\n")
                var text = ""
                if fileID < splitFileTotal {
                    for _ in 1...self.splitLineNumbers! {
                        text += textLines[lineIndex] + "\n"
                        lineIndex += 1
                    }
                } else {
                    for _ in 1...(linesTotal % self.splitLineNumbers!) {
                        text += textLines[lineIndex] + "\n"
                        lineIndex += 1
                    }
                }
                try self.writeTextToFile(fileUrl: fileUrl, text: text)
            }
        } else {
            let splitFileTotal = linesTotal / self.splitLineNumbers!
            var lineIndex = 0
            for fileID in 1...splitFileTotal {
                let filename = "en_\(fileID).txt"
                var fileUrl = targetUrl
                fileUrl.appendPathComponent(filename)
                var text = ""
                for _ in 1...self.splitLineNumbers! {
                    text += textLines[lineIndex] + "\n"
                    lineIndex += 1
                }
                try self.writeTextToFile(fileUrl: fileUrl, text: text)
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
            // 如果文本文件大于1GB，采用逐行读取
            if try FileManager.default.attributesOfItem(atPath: self.readFilePath!)[.size] as! UInt64 > 1000000000 {
                try self.readFileLineByLineAndSplitTextWriteToFiles()
            } else {
                let fileText = try readTextFromFile()
                print("读取 \(self.readFilePath!)")
                try splitTextWriteToFiles(text: fileText, separator: "\n")
            }
        } catch SplitGPGEncrypTextError.readFileURLIsNull {
            print("Read file url is null.")
        } catch {
            print("Running SplitGPGEncrypText throw an unkown error: \(error.localizedDescription)")
        }
    }
}
