import Foundation




// SplitGPGEncrypText <read_file_path> <output_dir_path> <printlog> <split_line_number>
//let splitGpg = try SplitGPGEncrypText(arguments: ["SplitGPGEncrypText", "/Users/jianyiliang/Desktop/demo.txt", "/Users/jianyiliang/Desktop/tmp/", "printlog", "3"])



do {
    let splitGpg = try SplitGPGEncrypText(arguments: CommandLine.arguments)
    splitGpg.run()
} catch SplitGPGEncrypTextError.readFileURLIsNull {
    print("Please input read file path.")
} catch SplitGPGEncrypTextError.missingArgument(let argumentName) {
    print("Missing argument: \(argumentName)")
} catch SplitGPGEncrypTextError.missingArguments(let argumentNames) {
    print("Missing arguments: \(argumentNames)")
} catch SplitGPGEncrypTextError.invalidArguments(let argumentNames) {
    print("Invalid arguments: \(argumentNames)")
} catch {
    print("SplitGPGEncrypText initialize throw an unkown error: \(error.localizedDescription)")
}
