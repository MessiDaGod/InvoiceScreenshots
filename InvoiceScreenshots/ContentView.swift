//
//  ContentView.swift
//  InvoiceScreenshots
//
//  Created by Joe Shakely on 9/12/23.
//

import SwiftUI
import CoreData


class TimerViewModel: ObservableObject {
    var timerController = TimerController()
    
    @Published var formattedTime: String = "10:00"
    @Published var isRunning: Bool = false
    
    init() {
        timerController.updateLabel = { [weak self] time in
            self?.formattedTime = time
        }
    }
    
    func executeScript(clientName: String, invoiceNumber: String, includeSound: Bool) {
        isRunning = true
        timerController.startTimer()
        
        AppleScriptExecutor.execute(clientName: clientName, invoiceNumber: invoiceNumber, includeSound: includeSound) { [weak self] result in
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
        AppleScriptExecutor.terminateCurrentProcess()
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var clientName: String = "Meissner"
    @State private var invoiceNumber: String = "Invoice2"
    @State private var isRunning: Bool = false
    @State private var includeScreenshotSound: Bool = true
    @State private var remainingSeconds: Int = 600
    @State private var formattedTime: String = "10:00"
    @ObservedObject var viewModel = TimerViewModel()
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var timerController = TimerController()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Client's Name", text: $clientName)
                .padding()
                .border(Color.gray)

            TextField("Enter Invoice Number", text: $invoiceNumber)
                .padding()
                .border(Color.gray)
            
            Text(viewModel.formattedTime)

            Button(action: {
                viewModel.executeScript(clientName: clientName, invoiceNumber: invoiceNumber, includeSound: includeScreenshotSound)
            }) {
                Text("Execute Script")
            }
            .padding()
            .disabled(viewModel.isRunning)

            Button(action: viewModel.cancelProcess) {
                Text("Cancel")
            }
            .padding()
            .disabled(!viewModel.isRunning)
            
            Toggle(isOn: $includeScreenshotSound) {
                Text("Include Screenshot Sound")
            }
            .padding()

        }
        .padding()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
