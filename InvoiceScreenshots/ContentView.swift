//
//  ContentView.swift
//  InvoiceScreenshots
//
//  Created by Joe Shakely on 9/12/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var clientName: String = "Meissner"
    @State private var invoiceNumber: String = "Invoice2"
    @State private var isRunning: Bool = false
    @State private var includeScreenshotSound: Bool = true
    @State private var remainingSeconds: Int = 600

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
            
            Text(formattedTime)
                .onReceive(timer) { _ in
                    if self.remainingSeconds > 0 {
                        self.remainingSeconds -= 1
                    } else {
                        self.remainingSeconds = 600
                    }
                }

            Button(action: executeScript) {
                Text("Execute Script")
            }
            .padding()
            .disabled(isRunning)

            Button(action: cancelProcess) {
                Text("Cancel")
            }
            .padding()
            .disabled(!isRunning)
            
            Toggle(isOn: $includeScreenshotSound) {
                Text("Include Screenshot Sound")
            }
            .padding()

        }
        .padding()
        .onReceive(timer) { _ in
            if self.isRunning == false {
                self.remainingSeconds = 600
            }
            else if self.isRunning == true {
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.remainingSeconds = 600
                }
            }
        }
    }

    func executeScript() {
        isRunning = true
        AppleScriptExecutor.execute(clientName: clientName, invoiceNumber: invoiceNumber, includeSound: includeScreenshotSound) { result in
            DispatchQueue.main.async {
                self.isRunning = false
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
        self.remainingSeconds = 600
        AppleScriptExecutor.terminateCurrentProcess()
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
