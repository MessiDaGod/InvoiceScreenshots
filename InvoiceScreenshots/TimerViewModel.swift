import SwiftUI
import CoreData
import Combine


class TimerViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    var timerController = TimerController()
    
    @Published var clientName: String = ""
    @Published var formattedTime: String = "10:00"
    @Published var isRunning: Bool = false
    
    init() {
        timerController.updateLabel = { [weak self] time in
            self?.formattedTime = time
        }

        $clientName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: "lastClientName")
            }
            .store(in: &cancellables)
    }
    
    func executeScript(clientName: String, invoiceNumber: String, includeSound: Bool) {
        isRunning = true
        timerController.startTimer()
        
        ScreenshotTerminalExecutor.execute(clientName: clientName, invoiceNumber: invoiceNumber, includeSound: includeSound) { [weak self] result in
            DispatchQueue.main.async {
                self?.timerController.stopTimer()
                self?.isRunning = false
                switch result {
                case .success:
                    print("Success!")
                case .failure(let error):
                    print("Error:", error)
                }
            }
        }
    }
    
    func cancelProcess() {
        isRunning = false
        timerController.stopTimer()
        ScreenshotTerminalExecutor.terminateCurrentProcess()
        timerController.resetTimer() // Reset the timer to 10:00
    }
}
