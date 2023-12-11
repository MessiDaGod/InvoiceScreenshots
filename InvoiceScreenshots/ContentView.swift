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
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var clientName: String = ""
    @State private var invoiceNumber: String = "Invoice7"
    @State private var isRunning: Bool = false
    @State private var includeScreenshotSound: Bool = true
    @State private var remainingSeconds: Int = 600
    @State private var formattedTime: String = "10:00"
    @ObservedObject var viewModel = TimerViewModel()
    @State private var newClientName: String = ""
    @State private var showNewClientField: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    // For toggling the sidebar
    @State private var isSidebarVisible: Bool = true
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var timerController = TimerController()
    
    @FetchRequest(entity: Client.entity(), sortDescriptors: [NSSortDescriptor(key: "id", ascending: true)]) private var clients: FetchedResults<InvoiceScreenshots.Client>
        
    // Initial setup: Load values from UserDefaults
    init() {
        if let savedClientName = UserDefaults.standard.string(forKey: "clientName") {
            _clientName = State(initialValue: savedClientName)
        }
        else if let firstClient = clients.first {
            _clientName = State(initialValue: firstClient.name ?? "")
        }
    }

    var body: some View {
        NavigationView {
            // Sidebar
            VStack {
                List {
                    Button(action: {
                        // Placeholder action for Add New Client
                    }) {
                        Text("Add New Client")
                    }

                    // Only show the Delete All Clients button if there are clients
                    if !clients.isEmpty {
                        Button(action: {
                            self.showDeleteConfirmation = true
                        }) {
                            Text("Delete All Clients")
                        }
                    }
                }
                Spacer()
            }
            .frame(minWidth: 200, maxHeight: .infinity)
            .colorScheme(.dark)
            
            // Main content
            VStack(spacing: 20) {
                // Add New Client Button
                Button(action: {
                    self.showNewClientField.toggle()
                }) {
                    HStack {
                        Text("Add New Client")
                            .foregroundColor(Color.white)
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                    .padding()
                }
                .colorScheme(.dark)
                
                // Delete all Clients
                Button(action: {
                    self.showDeleteConfirmation = true
                }) {
                    HStack {
                        Text("Delete All Clients")
                        .foregroundColor(Color.white)
                    }
                    .padding()
                }
                .alert(isPresented: $showDeleteConfirmation) {
                    Alert(title: Text("Delete All Clients?"),
                          message: Text("Are you sure you want to delete all clients? This action cannot be undone."),
                          primaryButton: .destructive(Text("Delete")) {
                              deleteAllClients()
                          },
                          secondaryButton: .cancel()
                    )
                }

                
                // New Client Name TextField
                if showNewClientField {
                    TextField("New Client Name", text: $newClientName)
                        .padding()
                        .border(Color.gray)

                    Button(action: {
                        addNewClient()
                        newClientName = "" // Clear the field after adding
                        showNewClientField = false // Hide the TextField after saving
                    }) {
                        Text("Save Client")
                    }
                    .padding()
                }

                
                // Only show the Picker if there are clients
                if !clients.isEmpty {
                    Picker("Select Client", selection: $clientName) {
                        ForEach(clients, id: \.self) { client in
                            Text(client.name ?? "").tag(client.name ?? "")
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .border(Color.gray)
                }


                TextField("Enter Invoice Number", text: $invoiceNumber)
                    .padding()
                    .border(Color.gray)
                
                Text(viewModel.formattedTime)

                Button(action: {
                    // Save values to UserDefaults
                    UserDefaults.standard.set(clientName, forKey: "clientName")
                    UserDefaults.standard.set(invoiceNumber, forKey: "invoiceNumber")
                    
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
            .colorScheme(.dark)
        }
        .padding()
        .onAppear {
            validateClientSelection()
        }
        .colorScheme(.dark)
    }

    
    func validateClientSelection() {
        if !clients.map({ $0.name ?? "" }).contains(clientName), let firstClient = clients.first {
            _clientName.wrappedValue = firstClient.name ?? ""
        }
    }
    
    func addNewClient() {
        let client = Client(context: viewContext)
        client.name = newClientName
        
        do {
            try viewContext.save()
            print("Saved successfully!")
          
            // Set the clientName to the new client's name
            clientName = newClientName

            // Fetch and print all clients to debug
            let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
            let allClients = try viewContext.fetch(fetchRequest)
            for client in allClients {
                print("Client name:", client.name ?? "No name")
            }
        } catch let error as NSError {
            if error.code == NSValidationMultipleErrorsError || error.code == NSValidationMultipleErrorsError {
                print("Client with the same name already exists!")
                viewContext.rollback() // This will undo the changes in the context
            } else {
                print("Error saving new client: \(error)")
            }
        }
    }


    
    func deleteAllClients() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Client.fetchRequest()
        
        do {
            let fetchedClients = try viewContext.fetch(fetchRequest) as! [Client]
            for client in fetchedClients {
                viewContext.delete(client)
            }
            
            try viewContext.save()
            
            // Reset clientName after deletion
            if let firstClient = clients.first {
                clientName = firstClient.name ?? ""
            } else {
                clientName = ""
            }
            
        } catch {
            print("Error deleting all clients: \(error)")
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
