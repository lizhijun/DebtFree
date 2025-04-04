import SwiftUI
import SwiftData

struct PaymentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Payment.date, order: .reverse) private var payments: [Payment]
    @Query private var debts: [Debt]
    
    @State private var showingPaymentSheet = false
    @State private var selectedDebt: Debt?
    @State private var filterOption: FilterOption = .all
    @State private var searchText = ""
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case thisYear = "This Year"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if filteredPayments.isEmpty {
                    ContentUnavailableView(
                        "No Payments",
                        systemImage: "dollarsign.circle",
                        description: Text("Add a payment to start tracking")
                    )
                } else {
                    List {
                        ForEach(filteredPayments) { payment in
                            PaymentRowView(payment: payment)
                        }
                        .onDelete(perform: deletePayments)
                    }
                    .searchable(text: $searchText, prompt: "Search by debt name")
                }
            }
            .navigationTitle("Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if !debts.isEmpty {
                            selectedDebt = debts.first
                            showingPaymentSheet = true
                        }
                    }) {
                        Label("Add Payment", systemImage: "plus")
                    }
                    .disabled(debts.isEmpty)
                }
            }
            .sheet(isPresented: $showingPaymentSheet) {
                if let debt = selectedDebt {
                    MakePaymentView(debt: debt)
                }
            }
            .sheet(item: $selectedDebt) { debt in
                MakePaymentView(debt: debt)
            }
        }
    }
    
    private var filteredPayments: [Payment] {
        var result = payments
        
        // Apply time-based filtering
        switch filterOption {
        case .thisMonth:
            result = result.filter { isThisMonth(date: $0.date) }
        case .lastMonth:
            result = result.filter { isLastMonth(date: $0.date) }
        case .thisYear:
            result = result.filter { isThisYear(date: $0.date) }
        case .all:
            break
        }
        
        // Apply search text filtering
        if !searchText.isEmpty {
            result = result.filter { payment in
                guard let debtName = payment.debt?.name else { return false }
                return debtName.lowercased().contains(searchText.lowercased())
            }
        }
        
        return result
    }
    
    private func deletePayments(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredPayments[index])
            }
        }
    }
    
    // MARK: - Date Helpers
    
    private func isThisMonth(date: Date) -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        return calendar.component(.month, from: date) == calendar.component(.month, from: currentDate) &&
               calendar.component(.year, from: date) == calendar.component(.year, from: currentDate)
    }
    
    private func isLastMonth(date: Date) -> Bool {
        let calendar = Calendar.current
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return false
        }
        return calendar.component(.month, from: date) == calendar.component(.month, from: lastMonth) &&
               calendar.component(.year, from: date) == calendar.component(.year, from: lastMonth)
    }
    
    private func isThisYear(date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.year, from: date) == calendar.component(.year, from: Date())
    }
}

struct PaymentRowView: View {
    let payment: Payment
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.debt?.name ?? "Unknown Debt")
                    .font(.headline)
                
                Text(payment.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", payment.amount))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PaymentsView()
        .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 