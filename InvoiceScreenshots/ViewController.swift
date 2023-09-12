import AppKit

class ViewController: NSViewController {

    @IBOutlet weak var countdownTextField: NSTextField!
    var timerController = TimerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        timerController.updateLabel = { [weak self] timeString in
            self?.countdownTextField.stringValue = timeString
        }

        timerController.startTimer()
    }
}
