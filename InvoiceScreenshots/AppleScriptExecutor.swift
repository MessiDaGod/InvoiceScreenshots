import Foundation
import Cocoa

class AppleScriptExecutor {
    
    private static var isTaskRunning: Bool = false
    static var runningProcess: Process?
    
    static func promptForDirectory() -> URL? {
        var resultURL: URL? = nil
        DispatchQueue.main.sync {
            let openPanel = NSOpenPanel()
            openPanel.title = "Choose a directory"
            openPanel.showsResizeIndicator = true
            openPanel.showsHiddenFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseFiles = false

            if openPanel.runModal() == .OK {
                resultURL = openPanel.url
            }
        }
        return resultURL
    }

    static func execute(clientName: String, invoiceNumber: String, includeSound: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            
            guard let _ = promptForDirectory() else {
                // Handle the case where the user didn't select a directory.
                return
            }
            
            let dateResult = shell("date +'%m%d%Y'").trimmingCharacters(in: .whitespacesAndNewlines)
            let dFolder = "/Users/\(NSUserName())/Documents/\(clientName)/ScreenCaptures/\(invoiceNumber)/\(dateResult)/"
            
            _ = shell("mkdir -p '\(dFolder)'")
            
            isTaskRunning = true
            
            for i in 0..<10000 {
                if isTaskRunning == false {
                    break
                }
                
                if i == 0 {
                    sleep(5)
                }
                let timestamp = shell("date +'%H%M%S'").trimmingCharacters(in: .whitespacesAndNewlines)
                let screenshotName = "Screenshots-\(dateResult)_\(timestamp)_\(i).png"
                let soundFlag = includeSound ? "" : "-x"
                let fullPath = dFolder + screenshotName
                _ = shell("screencapture \(soundFlag) -D1 -R 50,130,3000,1930 '\(fullPath)'")
                sleep(600)  // Wait for 10 minutes
            }
            
            // Open Finder at the specified directory (this is optional)
            _ = shell("open '\(dFolder)'")
        }
    }
    
    private static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        runningProcess = task
        
        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

//        task.waitUntilExit()
        return output ?? ""
    }
    
    static func terminateCurrentProcess() {
        runningProcess?.interrupt()  // sends an interrupt signal
        runningProcess?.terminate()  // sends a terminate signal
    }
}
