import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var debts: [Debt]
    @Query private var payments: [Payment]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary cards
                    summaryCardsView
                    
                    // Debt breakdown chart
                    debtBreakdownChart
                    
                    // Payment history
                    recentPaymentsView
                }
                .padding()
            }
            .navigationTitle("Debt Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add AI analysis feature here
                    }) {
                        Label("AI Analysis", systemImage: "brain")
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Cards
    var summaryCardsView: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                SummaryCardView(
                    title: "Total Debt",
                    value: String(format: "$%.2f", totalDebtAmount),
                    icon: "creditcard.fill",
                    color: .red
                )
                
                SummaryCardView(
                    title: "Average Interest",
                    value: String(format: "%.2f%%", averageInterestRate),
                    icon: "percent",
                    color: .orange
                )
            }
            
            HStack(spacing: 15) {
                SummaryCardView(
                    title: "Due This Month",
                    value: String(format: "$%.2f", dueThisMonth),
                    icon: "calendar",
                    color: .blue
                )
                
                SummaryCardView(
                    title: "Paid This Month",
                    value: String(format: "$%.2f", paidThisMonth),
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Debt Breakdown Chart
    var debtBreakdownChart: some View {
        VStack(alignment: .leading) {
            Text("Debt Breakdown")
                .font(.headline)
            
            Chart {
                ForEach(debtBreakdownData, id: \.category) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                    .annotation(position: .overlay) {
                        Text("\(Int(item.percentage))%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
            }
            .frame(height: 200)
            .chartLegend(position: .bottom, alignment: .center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Payments View
    var recentPaymentsView: some View {
        VStack(alignment: .leading) {
            Text("Recent Payments")
                .font(.headline)
            
            if sortedPayments.isEmpty {
                Text("No payments recorded yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(sortedPayments.prefix(5), id: \.self) { payment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(payment.debt?.name ?? "Unknown Debt")
                                .font(.subheadline)
                            Text(payment.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", payment.amount))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 8)
                    
                    if payment != sortedPayments.prefix(5).last {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Data Properties
    
    struct DebtBreakdownItem {
        let category: String
        let amount: Double
        let percentage: Double
    }
    
    var totalDebtAmount: Double {
        debts.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var averageInterestRate: Double {
        let unpaidDebts = debts.filter { !$0.isPaid }
        guard !unpaidDebts.isEmpty else { return 0 }
        return unpaidDebts.reduce(0) { $0 + $1.interestRate } / Double(unpaidDebts.count)
    }
    
    var dueThisMonth: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return debts.filter { debt in
            !debt.isPaid &&
            Calendar.current.component(.month, from: debt.dueDate) == currentMonth &&
            Calendar.current.component(.year, from: debt.dueDate) == currentYear
        }.reduce(0) { $0 + $1.minimumPayment }
    }
    
    var paidThisMonth: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return payments.filter { payment in
            Calendar.current.component(.month, from: payment.date) == currentMonth &&
            Calendar.current.component(.year, from: payment.date) == currentYear
        }.reduce(0) { $0 + $1.amount }
    }
    
    var debtBreakdownData: [DebtBreakdownItem] {
        let unpaidDebts = debts.filter { !$0.isPaid }
        guard !unpaidDebts.isEmpty else { return [] }
        
        var categoryTotals: [String: Double] = [:]
        
        for debt in unpaidDebts {
            let category = debt.category.rawValue
            categoryTotals[category, default: 0] += debt.amount
        }
        
        return categoryTotals.map { category, amount in
            DebtBreakdownItem(
                category: category,
                amount: amount,
                percentage: (amount / totalDebtAmount) * 100
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    var sortedPayments: [Payment] {
        payments.sorted { $0.date > $1.date }
    }
}

// MARK: - Supporting Views
struct SummaryCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 