
import Foundation

class AppleScriptExecutor {

    static func execute(clientName: String, invoiceNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let appleScriptString = """
            set strDate to do shell script "date +'%m\\d%Y'"
            set dateObj to (current date)
            set dateStamp to "" & strDate

            set dFolder to "/Users/joeshakely/Documents/" & clientName & "/ScreenCaptures/" & invoiceNumber & "/" & dateStamp & "/"
            do shell script ("mkdir -p " & dFolder)

            set i to 0
            repeat 10000 times
                if i = 0 then
                    delay 5
                    set timestamp to "_" & (do shell script "date +%H%M%S")
                    do shell script ("screencapture -D1 -R 50,130,3000,1930 " & dFolder & "Screenshots-" & dateStamp & timestamp & "_" & i & ".png")
                end if
                
                if i ≠ 0 then
                    set timestamp to "_" & (do shell script "date +%H%M%S")
                    do shell script ("screencapture -D1 -R 50,130,3000,1930 " & dFolder & "Screenshots-" & dateStamp & timestamp & "_" & i & ".png")
                end if
                
                delay 600 -- Wait for 10 minutes
                set i to i + 1
            end repeat
            tell application "Finder"
                activate
                set target of Finder window 1 to folder "Documents" of folder "WebServer" of folder "Library" of startup disk
                set target of Finder window 1 to folder "Documents" of folder "joeshakely" of folder "Users" of startup disk
                set target of Finder window 1 to folder "Meissner" of folder "Documents" of folder "joeshakely" of folder "Users" of startup disk
                set target of Finder window 1 to folder "ScreenCaptures" of folder "Meissner" of folder "Documents" of folder "joeshakely" of folder "Users" of startup disk
                set current view of Finder window 1 to column view
                set bounds of Finder window 1 to {1920, 84, 3000, 1920}
                set position of Finder window 1 to {257, 257}
                set bounds of Finder window 1 to {257, 257, 1337, 1312}
            end tell

            """
            
            var error: NSDictionary?
            if let script = NSAppleScript(source: appleScriptString) {
                let _ = script.executeAndReturnError(&error)
                if error != nil {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "AppleScriptError", code: error?["NSAppleScriptErrorNumber"] as? Int ?? -1, userInfo: error as? [String: Any])))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                }
            }
        }
    }
}
