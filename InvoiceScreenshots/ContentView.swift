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
        timerController.resetTimer() // Reset the timer to 10:00
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var environmentColorScheme
    @State private var colorScheme: ColorScheme = .light
    @State private var clientName: String = ""
    @State private var invoiceNumber: String = "Invoice7"
    @State private var isRunning: Bool = false
    @State private var includeScreenshotSound: Bool = true
    @State private var formattedTime: String = "10:00"
    @State private var remainingSeconds: Int = 600
    @ObservedObject var viewModel = TimerViewModel()
    @State private var newClientName: String = ""
    @State private var showNewClientField: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @FetchRequest(entity: Client.entity(), sortDescriptors: [NSSortDescriptor(key: "id", ascending: false )]) private var clients: FetchedResults<Client>
        
    var body: some View {
        NavigationSplitView {
            List {
                Button(action: {
                    self.showNewClientField.toggle()
                }) {
                    Text("Add New Client")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }

                // Only show the Delete All Clients button if there are clients
                if !clients.isEmpty {
                    Button(action: {
                        self.showDeleteConfirmation = true
                    }) {
                        Text("Delete All Clients")
                            .foregroundColor(.red)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                }
            }
            .frame(minWidth: 170)
            .background(Color.clear)
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(title: Text("Delete All Clients?"),
                      message: Text("Are you sure you want to delete all clients? This action cannot be undone."),
                      primaryButton: .destructive(Text("Delete")),
                      secondaryButton: .cancel()
                )
            }
        } detail: {
            VStack(spacing: 20) {
                // Light/Dark mode toggle button at the top
                Button(action: toggleColorScheme) {
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                            .shadow(radius: 10)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                            .font(.title)
                            .foregroundColor(colorScheme == .dark ? .yellow : .gray)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                }
                .padding()

                // Add New Client Button
                Button(action: {
                    self.showNewClientField.toggle()
                }) {
                    HStack {
                        Text("Add New Client")
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .padding()
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                
                // New Client Name TextField
                if showNewClientField {
                    TextField("New Client Name", text: $newClientName)
                        .padding()
                        .border(Color.gray)

                    HStack {
                        Button(action: {
                            addNewClient()
                            newClientName = "" // Clear the field after adding
                            showNewClientField = false // Hide the TextField after saving
                        }) {
                            Text("Save Client")
                        }
                        .padding()
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        Button(action: {
                            newClientName = ""
                            showNewClientField = false
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                        }
                        .padding()
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                }
                
                // Only show the Picker if there are clients
                if !clients.isEmpty {
                    Picker("Select Client", selection: $clientName) {
                        ForEach(clients, id: \.self) { client in
                            Text(client.name ?? "")
                                .tag(client.name ?? "")
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .border(Color.gray)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }

                TextField("Enter Invoice Number", text: $invoiceNumber)
                    .padding()
                    .border(Color.gray)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(viewModel.formattedTime)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

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
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }

                Button(action: {
                    viewModel.cancelProcess()
                    formattedTime = viewModel.formattedTime // Reset the timer display
                }) {
                    Text("Cancel")
                }
                .padding()
                .disabled(!viewModel.isRunning)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Toggle(isOn: $includeScreenshotSound) {
                    Text("Include Screenshot Sound")
                }
                .padding()
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color.clear)
            .onAppear {
                loadColorScheme()
                initializeClientName()
            }
        }
        .background(Color.clear) // Ensure the entire background is transparent
        .preferredColorScheme(colorScheme)
    }

    func toggleColorScheme() {
        colorScheme = colorScheme == .dark ? .light : .dark
        UserDefaults.standard.set(colorScheme == .dark ? "dark" : "light", forKey: "colorScheme")
    }

    func loadColorScheme() {
        if let savedScheme = UserDefaults.standard.string(forKey: "colorScheme") {
            colorScheme = savedScheme == "dark" ? .dark : .light
        }
    }

    func initializeClientName() {
        if let savedClientName = UserDefaults.standard.string(forKey: "clientName") {
            clientName = savedClientName
        } else if let firstClient = clients.first {
            clientName = firstClient.name ?? ""
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
