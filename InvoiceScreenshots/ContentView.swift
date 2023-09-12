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
        }
        .padding()
    }

    func executeScript() {
        isRunning = true
        AppleScriptExecutor.execute(clientName: clientName, invoiceNumber: invoiceNumber) { result in
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
        // This is where you'd put the logic to terminate the process, if it's possible
        // For now, let's just set isRunning to false for the sake of this example.
        isRunning = false
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
