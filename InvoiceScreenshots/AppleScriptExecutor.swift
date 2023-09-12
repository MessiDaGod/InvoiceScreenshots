
import Foundation

class AppleScriptExecutor {

    static func execute(clientName: String, invoiceNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            
            let dateResult = shell("date +%m%d%Y")
            let dFolder = "/Users/joeshakely/Documents/\(clientName)/ScreenCaptures/\(invoiceNumber)/" + dateResult + "/"
            
            _ = shell("mkdir -p " + dFolder)
            
            for i in 0..<10000 {
                if i == 0 {
                    sleep(5)
                }
                let timestamp = shell("date +%H%M%S")
                let screenshotName = "Screenshots-" + dateResult + "_" + timestamp + "_\(i).png"
                let fullPath = dFolder + screenshotName
                _ = shell("screencapture -D1 -R 50,130,3000,1930 " + fullPath)
                sleep(600)  // Wait for 10 minutes
            }
            
            // Open Finder at the specified directory (this is optional)
            _ = shell("open " + dFolder)
        }
    }
    
    private static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        task.waitUntilExit()
        return output ?? ""
    }
}
