import SwiftUI
import SwiftData

struct AddDebtView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amount = 0.0
    @State private var interestRate = 0.0
    @State private var minimumPayment = 0.0
    @State private var dueDate = Date()
    @State private var category: DebtCategory = .creditCard
    @State private var notes = ""
    
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
            .navigationTitle("Add Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDebt()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && amount > 0 && minimumPayment > 0
    }
    
    private func saveDebt() {
        let newDebt = Debt(
            name: name,
            amount: amount,
            interestRate: interestRate,
            minimumPayment: minimumPayment,
            dueDate: dueDate,
            category: category,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(newDebt)
        dismiss()
    }
}

#Preview {
    AddDebtView()
        .modelContainer(for: Debt.self, inMemory: true)
} 