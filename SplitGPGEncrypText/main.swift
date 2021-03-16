import Foundation




// SplitGPGEncrypText <read_file_path> <output_dir_path> <printlog> <split_line_number>
//let splitGpg = try SplitGPGEncrypText(arguments: ["SplitGPGEncrypText", "/Users/jianyiliang/Desktop/demo.txt", "/Users/jianyiliang/Desktop/tmp/", "printlog", "3"])

let splitGpg = try SplitGPGEncrypText(arguments: CommandLine.arguments)
splitGpg.run()

