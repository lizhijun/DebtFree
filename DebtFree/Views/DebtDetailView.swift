import SwiftUI
import SwiftData

struct DebtDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var debt: Debt
    @State private var isEditing = false
    @State private var showingPaymentSheet = false
    @Query private var payments: [Payment]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Debt info card
                debtInfoCard
                
                // Payment History
                paymentHistorySection
                
                // Stats
                statsSection
                
                // AI Analysis
                aiAnalysisSection
            }
            .padding()
        }
        .navigationTitle(debt.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        isEditing = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showingPaymentSheet = true
                    }) {
                        Label("Make Payment", systemImage: "dollarsign.circle")
                    }
                    
                    Button(action: {
                        togglePaidStatus()
                    }) {
                        Label(
                            debt.isPaid ? "Mark as Unpaid" : "Mark as Paid",
                            systemImage: debt.isPaid ? "xmark.circle" : "checkmark.circle"
                        )
                    }
                    
                    Button(role: .destructive, action: {
                        deleteDebt()
                        dismiss()
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditDebtView(debt: debt)
        }
        .sheet(isPresented: $showingPaymentSheet) {
            MakePaymentView(debt: debt)
        }
    }
    
    private var debtInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Amount")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "$%.2f", debt.amount))
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if debt.isPaid {
                    Text("PAID")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            HStack {
                DebtInfoItem(
                    title: "Interest Rate",
                    value: "\(String(format: "%.2f%%", debt.interestRate))",
                    icon: "percent"
                )
                
                Spacer()
                
                DebtInfoItem(
                    title: "Min. Payment",
                    value: "\(String(format: "$%.2f", debt.minimumPayment))",
                    icon: "creditcard"
                )
                
                Spacer()
                
                DebtInfoItem(
                    title: "Due Date",
                    value: debt.dueDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar"
                )
            }
            
            Divider()
            
            HStack {
                Text("Category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(debt.category.rawValue)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(categoryColor(for: debt.category).opacity(0.2))
                    .foregroundColor(categoryColor(for: debt.category))
                    .cornerRadius(6)
            }
            
            if let notes = debt.notes, !notes.isEmpty {
                Divider()
                
                Text("Notes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(notes)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var paymentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payment History")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingPaymentSheet = true
                }) {
                    Label("New Payment", systemImage: "plus")
                        .font(.subheadline)
                }
            }
            
            if debtPayments.isEmpty {
                Text("No payments recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(debtPayments) { payment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(payment.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if let notes = payment.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", payment.amount))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 8)
                    
                    if payment != debtPayments.last {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            HStack {
                StatItem(
                    title: "Paid So Far",
                    value: "\(String(format: "$%.2f", totalPaid))",
                    color: .green
                )
                
                Spacer()
                
                StatItem(
                    title: "Remaining",
                    value: "\(String(format: "$%.2f", remainingAmount))",
                    color: .orange
                )
            }
            
            HStack {
                StatItem(
                    title: "Time to Pay Off",
                    value: estimatedPayoffTime,
                    color: .blue
                )
                
                Spacer()
                
                StatItem(
                    title: "Progress",
                    value: "\(Int(paymentProgress * 100))%",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var aiAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Analysis & Tips")
                .font(.headline)
            
            Text("Based on your payment history and interest rate, we recommend increasing your monthly payment to \(String(format: "$%.2f", recommendedPayment)) to save approximately \(String(format: "$%.2f", potentialInterestSavings)) in interest and pay off this debt \(monthsEarlier) months earlier.")
                .font(.subheadline)
            
            Button(action: {
                // Show detailed AI analysis
            }) {
                Text("See Detailed Analysis")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    private var debtPayments: [Payment] {
        return payments.filter { $0.debt?.id == debt.id }
            .sorted { $0.date > $1.date }
    }
    
    private var totalPaid: Double {
        return debtPayments.reduce(0) { $0 + $1.amount }
    }
    
    private var remainingAmount: Double {
        return max(debt.amount - totalPaid, 0)
    }
    
    private var paymentProgress: Double {
        guard debt.amount > 0 else { return 0 }
        return min(totalPaid / debt.amount, 1.0)
    }
    
    private var estimatedPayoffTime: String {
        guard debt.minimumPayment > 0 && remainingAmount > 0 else {
            return debt.isPaid ? "Paid off" : "∞"
        }
        
        let monthsLeft = Int(ceil(remainingAmount / debt.minimumPayment))
        if monthsLeft > 24 {
            let years = Double(monthsLeft) / 12.0
            return String(format: "%.1f years", years)
        } else {
            return "\(monthsLeft) months"
        }
    }
    
    // Placeholder calculation - would be replaced with actual AI model
    private var recommendedPayment: Double {
        return debt.minimumPayment * 1.5
    }
    
    // Placeholder calculation - would be replaced with actual AI model
    private var potentialInterestSavings: Double {
        return debt.amount * debt.interestRate / 100 * 0.3
    }
    
    // Placeholder calculation - would be replaced with actual AI model
    private var monthsEarlier: Int {
        return 6
    }
    
    // MARK: - Helper Methods
    
    private func togglePaidStatus() {
        debt.isPaid.toggle()
    }
    
    private func deleteDebt() {
        // First delete all payments associated with this debt
        for payment in debtPayments {
            modelContext.delete(payment)
        }
        
        // Then delete the debt itself
        modelContext.delete(debt)
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

// MARK: - Supporting Views

struct DebtInfoItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

#Preview {
    NavigationStack {
        DebtDetailView(debt: Debt(
            name: "Sample Credit Card",
            amount: 5000,
            interestRate: 19.99,
            minimumPayment: 150,
            dueDate: Date(),
            category: .creditCard
        ))
    }
    .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 