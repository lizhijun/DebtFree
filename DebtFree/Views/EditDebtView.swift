import SwiftUI
import SwiftData

struct EditDebtView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var debt: Debt
    
    @State private var name: String
    @State private var amount: Double
    @State private var interestRate: Double
    @State private var minimumPayment: Double
    @State private var dueDate: Date
    @State private var category: DebtCategory
    @State private var notes: String
    
    init(debt: Debt) {
        self.debt = debt
        _name = State(initialValue: debt.name)
        _amount = State(initialValue: debt.amount)
        _interestRate = State(initialValue: debt.interestRate)
        _minimumPayment = State(initialValue: debt.minimumPayment)
        _dueDate = State(initialValue: debt.dueDate)
        _category = State(initialValue: debt.category)
        _notes = State(initialValue: debt.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Debt Details") {
                    TextField("Debt Name", text: $name)
                    
                    HStack {
                        Text("$")
                        TextField("Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        TextField("Interest Rate", value: $interestRate, format: .number)
                            .keyboardType(.decimalPad)
                        Text("%")
                    }
                    
                    HStack {
                        Text("$")
                        TextField("Minimum Payment", value: $minimumPayment, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Additional Details") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    Picker("Category", selection: $category) {
                        ForEach(DebtCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Notes (Optional)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Edit Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateDebt()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && amount > 0 && minimumPayment > 0
    }
    
    private func updateDebt() {
        debt.name = name
        debt.amount = amount
        debt.interestRate = interestRate
        debt.minimumPayment = minimumPayment
        debt.dueDate = dueDate
        debt.category = category
        debt.notes = notes.isEmpty ? nil : notes
        
        dismiss()
    }
}

#Preview {
    EditDebtView(debt: Debt(
        name: "Sample Credit Card",
        amount: 5000,
        interestRate: 19.99,
        minimumPayment: 150,
        dueDate: Date()
    ))
    .modelContainer(for: Debt.self, inMemory: true)
} 