import SwiftUI
import SwiftData

struct DebtsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var debts: [Debt]
    @State private var showingAddDebt = false
    @State private var sortOption: SortOption = .amount
    @State private var filterOption: FilterOption = .all
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case amount = "Amount"
        case interestRate = "Interest Rate"
        case dueDate = "Due Date"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case paid = "Paid"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filter and Sort Controls
                HStack {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                    
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                
                if filteredAndSortedDebts.isEmpty {
                    ContentUnavailableView(
                        "No Debts",
                        systemImage: "creditcard",
                        description: Text("Add a debt to start tracking")
                    )
                } else {
                    List {
                        ForEach(filteredAndSortedDebts) { debt in
                            NavigationLink {
                                DebtDetailView(debt: debt)
                            } label: {
                                DebtRowView(debt: debt)
                            }
                        }
                        .onDelete(perform: deleteDebts)
                    }
                }
            }
            .navigationTitle("Debts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddDebt = true
                    }) {
                        Label("Add Debt", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDebt) {
                AddDebtView()
            }
        }
    }
    
    private func deleteDebts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredAndSortedDebts[index])
            }
        }
    }
    
    private var filteredAndSortedDebts: [Debt] {
        var result = debts
        
        // Apply filtering
        switch filterOption {
        case .active:
            result = result.filter { !$0.isPaid }
        case .paid:
            result = result.filter { $0.isPaid }
        case .all:
            break
        }
        
        // Apply sorting
        switch sortOption {
        case .name:
            result.sort { $0.name < $1.name }
        case .amount:
            result.sort { $0.amount > $1.amount }
        case .interestRate:
            result.sort { $0.interestRate > $1.interestRate }
        case .dueDate:
            result.sort { $0.dueDate < $1.dueDate }
        }
        
        return result
    }
}

struct DebtRowView: View {
    let debt: Debt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(debt.name)
                    .font(.headline)
                
                Spacer()
                
                if debt.isPaid {
                    Text("PAID")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Label(
                    String(format: "$%.2f", debt.amount),
                    systemImage: "dollarsign.circle"
                )
                .font(.subheadline)
                
                Spacer()
                
                Label(
                    String(format: "%.2f%%", debt.interestRate),
                    systemImage: "percent"
                )
                .font(.subheadline)
            }
            .foregroundColor(.secondary)
            
            HStack {
                Text("Due: \(debt.dueDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(debt.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(categoryColor(for: debt.category))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryColor(for category: DebtCategory) -> Color {
        switch category {
        case .creditCard:
            return .red
        case .studentLoan:
            return .blue
        case .mortgage:
            return .purple
        case .carLoan:
            return .green
        case .personalLoan:
            return .orange
        case .medical:
            return .teal
        case .other:
            return .gray
        }
    }
}

#Preview {
    DebtsListView()
        .modelContainer(for: [Debt.self], inMemory: true)
} 