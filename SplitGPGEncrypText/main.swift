import Foundation

var isPrintLog: Bool = false

func printLog(_ text: String) {
    if CommandLine.arguments.count >= 3 {
        if CommandLine.arguments[3] == "printlog" {
            print(text)
        }
    }
}

func createDirectory(baseUrlWithPath: String, directoryName: String) throws -> URL {
    var dirUrl = URL(fileURLWithPath: baseUrlWithPath, isDirectory: true)
    dirUrl.appendPathComponent(directoryName, isDirectory: true)
    if FileManager.default.fileExists(atPath: dirUrl.path) {
        return dirUrl
    } else {
        try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        return dirUrl
    }
}

func splitTextWriteToFiles(text: String, separator: Character, splitLineNumber: Int) throws {
    let textLines = text.split(separator: "\n")
    let linesTotal = textLines.count
    let baseUrl = try createDirectory(baseUrlWithPath: CommandLine.arguments[2], directoryName: "tmp")
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

func readTextFromFile(url: String, encoding: String.Encoding = .ascii) throws -> String {
    return try String(contentsOf: URL(fileURLWithPath: url), encoding: encoding)
}

let fileText = try readTextFromFile(url: CommandLine.arguments[1])
print("访问 demo.txt：\n\(fileText)")
try splitTextWriteToFiles(text: fileText, separator: "\n", splitLineNumber: 3)
