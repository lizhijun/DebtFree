import SwiftUI
import SwiftData

struct MakePaymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let debt: Debt
    
    @State private var amount: Double = 0
    @State private var date: Date = Date()
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    Text(debt.name)
                        .font(.headline)
                    
                    HStack {
                        Text("$")
                        TextField("Payment Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Payment Date", selection: $date, displayedComponents: [.date])
                }
                
                Section("Suggested Amounts") {
                    SuggestedPaymentButton(amount: debt.minimumPayment, label: "Minimum Payment")
                    SuggestedPaymentButton(amount: debt.amount, label: "Full Balance")
                    SuggestedPaymentButton(amount: round(debt.amount * 0.1 * 100) / 100, label: "10% of Balance")
                }
                
                Section("Notes (Optional)") {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add notes about this payment")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Make Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        makePayment()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        amount > 0
    }
    
    private func makePayment() {
        let payment = Payment(
            amount: amount,
            date: date,
            debt: debt,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(payment)
        
        // If this payment covers the full debt, mark as paid
        if amount >= debt.amount {
            debt.isPaid = true
        }
        
        dismiss()
    }
    
    @ViewBuilder
    private func SuggestedPaymentButton(amount: Double, label: String) -> some View {
        Button {
            self.amount = amount
        } label: {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "$%.2f", amount))
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    MakePaymentView(debt: Debt(
        name: "Sample Credit Card",
        amount: 5000,
        interestRate: 19.99,
        minimumPayment: 150,
        dueDate: Date()
    ))
    .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 