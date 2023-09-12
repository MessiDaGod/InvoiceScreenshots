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
        }
        .padding()
    }

    func executeScript() {
        AppleScriptExecutor.execute(clientName: clientName, invoiceNumber: invoiceNumber) { result in
            switch result {
            case .success:
                print("Success!")
            case .failure(let error):
                print("Error:", error)
            }
        }
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
