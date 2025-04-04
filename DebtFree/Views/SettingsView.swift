import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var debts: [Debt]
    @Query private var payments: [Payment]
    
    @AppStorage("currency") private var currency = Currency.usd
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderDays") private var reminderDays = 3
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("aiSuggestionsEnabled") private var aiSuggestionsEnabled = true
    
    @State private var showingResetConfirmation = false
    @State private var showingAbout = false
    @State private var showingSampleData = false
    
    enum Currency: String, CaseIterable, Identifiable {
        case usd = "USD ($)"
        case eur = "EUR (€)"
        case gbp = "GBP (£)"
        case jpy = "JPY (¥)"
        case cad = "CAD ($)"
        case aud = "AUD ($)"
        case cny = "CNY (¥)"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("App Preferences") {
                    Picker("Currency", selection: $currency) {
                        ForEach(Currency.allCases) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Stepper("Remind \(reminderDays) days before due date", value: $reminderDays, in: 1...14)
                            .animation(.default, value: reminderDays)
                    }
                }
                
                Section("AI Features") {
                    Toggle("Enable AI Suggestions", isOn: $aiSuggestionsEnabled)
                    
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        Text("AI Settings")
                    }
                }
                
                Section("Data Management") {
                    Button("Add Sample Data") {
                        showingSampleData = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Export Data") {
                        // Export function would be implemented here
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset All Data") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("About DebtFree") {
                        showingAbout = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your debts and payment history. This action cannot be undone.")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingSampleData) {
                SampleDataView(addSampleData: addSampleData)
            }
        }
    }
    
    private func resetAllData() {
        for payment in payments {
            modelContext.delete(payment)
        }
        
        for debt in debts {
            modelContext.delete(debt)
        }
    }
    
    private func addSampleData() {
        // Only add sample data if there's no existing data
        guard debts.isEmpty else { return }
        
        // Create sample debts
        let creditCard = Debt(
            name: "Credit Card",
            amount: 5000,
            interestRate: 18.99,
            minimumPayment: 150,
            dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            category: .creditCard
        )
        
        let carLoan = Debt(
            name: "Car Loan",
            amount: 15000,
            interestRate: 4.5,
            minimumPayment: 300,
            dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            category: .carLoan
        )
        
        let studentLoan = Debt(
            name: "Student Loan",
            amount: 25000,
            interestRate: 5.8,
            minimumPayment: 400,
            dueDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date(),
            category: .studentLoan
        )
        
        modelContext.insert(creditCard)
        modelContext.insert(carLoan)
        modelContext.insert(studentLoan)
        
        // Create sample payments
        let today = Date()
        let calendar = Calendar.current
        
        // Credit card payments
        for i in 1...3 {
            if let pastDate = calendar.date(byAdding: .month, value: -i, to: today) {
                let payment = Payment(
                    amount: 150,
                    date: pastDate,
                    debt: creditCard
                )
                modelContext.insert(payment)
            }
        }
        
        // Car loan payments
        for i in 1...4 {
            if let pastDate = calendar.date(byAdding: .month, value: -i, to: today) {
                let payment = Payment(
                    amount: 300,
                    date: pastDate,
                    debt: carLoan
                )
                modelContext.insert(payment)
            }
        }
        
        // Student loan payments
        for i in 1...2 {
            if let pastDate = calendar.date(byAdding: .month, value: -i, to: today) {
                let payment = Payment(
                    amount: 400,
                    date: pastDate,
                    debt: studentLoan
                )
                modelContext.insert(payment)
            }
        }
    }
}

struct AISettingsView: View {
    @AppStorage("aiAnalysisFrequency") private var aiAnalysisFrequency = "weekly"
    @AppStorage("aiPrivacyLevel") private var aiPrivacyLevel = "standard"
    
    let analysisOptions = ["daily", "weekly", "monthly", "never"]
    let privacyOptions = ["standard", "enhanced", "maximum"]
    
    var body: some View {
        Form {
            Section("AI Analysis") {
                Picker("Analysis Frequency", selection: $aiAnalysisFrequency) {
                    Text("Daily").tag("daily")
                    Text("Weekly").tag("weekly")
                    Text("Monthly").tag("monthly")
                    Text("Never").tag("never")
                }
                
                Picker("Privacy Level", selection: $aiPrivacyLevel) {
                    Text("Standard").tag("standard")
                    Text("Enhanced").tag("enhanced")
                    Text("Maximum").tag("maximum")
                }
            }
            
            Section("About AI Features") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("DebtFree uses artificial intelligence to help you:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Label("Analyze your debt and suggest optimal repayment strategies", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline)
                    
                    Label("Predict your debt-free date based on your payment habits", systemImage: "calendar")
                        .font(.subheadline)
                    
                    Label("Identify potential savings opportunities", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            }
            
            Section("Privacy Information") {
                Text("All AI processing is done on-device. Your financial data is never sent to external servers unless you explicitly enable cloud backup.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("AI Settings")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("DebtFree")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical)
            
            Text("DebtFree helps you manage and eliminate your debts using AI-powered strategies and insights.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("© 2023 DebtFree")
                
                Text("All Rights Reserved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom)
        }
        .padding()
    }
}

struct SampleDataView: View {
    @Environment(\.dismiss) private var dismiss
    let addSampleData: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Sample Data")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("This will add sample debts and payments to help you see how the app works. Your existing data will not be affected.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                addSampleData()
                dismiss()
            }) {
                Text("Add Sample Data")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 