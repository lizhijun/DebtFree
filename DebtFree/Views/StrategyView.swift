import SwiftUI
import SwiftData
import Charts

struct StrategyView: View {
    @Query private var debts: [Debt]
    @State private var selectedStrategy: RepaymentStrategy
    @State private var monthlyPayment: Double
    @State private var showingPayOffDateView = false
    
    init() {
        // Default values - will be updated in onAppear
        _selectedStrategy = State(initialValue: .snowball)
        _monthlyPayment = State(initialValue: 0)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if unpaidDebts.isEmpty {
                        ContentUnavailableView(
                            "No Active Debts",
                            systemImage: "checkmark.circle",
                            description: Text("Congratulations! You have no active debts to pay off.")
                        )
                    } else {
                        // Recommended strategy
                        recommendedStrategySection
                        
                        // Monthly payment slider
                        monthlyPaymentSection
                        
                        // Debt-free projection
                        debtFreeProjectionSection
                        
                        // Ordered repayment plan
                        repaymentPlanSection
                        
                        // Comparison chart
                        strategyComparisonSection
                    }
                }
                .padding()
            }
            .navigationTitle("Repayment Strategy")
            .onAppear {
                initializeValues()
            }
            .sheet(isPresented: $showingPayOffDateView) {
                PayOffDateView(strategy: selectedStrategy, monthlyPayment: monthlyPayment)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(RepaymentStrategy.allCases) { strategy in
                            Button {
                                selectedStrategy = strategy
                            } label: {
                                Label(strategy.rawValue, systemImage: selectedStrategy == strategy ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Strategy", systemImage: "gear")
                    }
                }
            }
        }
    }
    
    // MARK: - Recommended Strategy Section
    
    private var recommendedStrategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended Strategy")
                    .font(.headline)
                
                Spacer()
                
                Text(selectedStrategy.rawValue)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            Text(selectedStrategy.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Monthly Payment Section
    
    private var monthlyPaymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Payment")
                .font(.headline)
            
            HStack {
                Text(String(format: "$%.0f", monthlyPayment))
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingPayOffDateView = true
                }) {
                    Label("See Debt-Free Date", systemImage: "calendar")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Slider(value: $monthlyPayment, in: minPayment...maxPayment, step: 50)
            
            HStack {
                Text("Min: \(String(format: "$%.0f", minPayment))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Recommended: \(String(format: "$%.0f", recommendedPayment))")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Max: \(String(format: "$%.0f", maxPayment))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Debt-Free Projection Section
    
    private var debtFreeProjectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debt-Free Projection")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Time to Freedom")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if debtFreeTime.months < 12 {
                        Text("\(debtFreeTime.months) months")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else {
                        Text("\(debtFreeTime.months / 12) years, \(debtFreeTime.months % 12) months")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Interest Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "$%.0f", debtFreeTime.amountSaved))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Repayment Plan Section
    
    private var repaymentPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repayment Order")
                .font(.headline)
            
            ForEach(Array(orderedDebts.enumerated()), id: \.element.id) { index, debt in
                DebtOrderCard(index: index + 1, debt: debt)
                
                if index < orderedDebts.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Strategy Comparison Section
    
    private var strategyComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy Comparison")
                .font(.headline)
            
            Chart {
                ForEach(strategyComparisonData, id: \.strategy) { item in
                    BarMark(
                        x: .value("Strategy", item.strategy.rawValue),
                        y: .value("Months", item.months)
                    )
                    .foregroundStyle(by: .value("Strategy", item.strategy.rawValue))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(preset: .aligned) { value in
                    AxisValueLabel {
                        if let strategy = value.as(String.self), let strategyEnum = RepaymentStrategy.allCases.first(where: { $0.rawValue == strategy }) {
                            Text(strategyEnum.rawValue.split(separator: " ").first ?? "")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let months = value.as(Int.self) {
                        AxisGridLine()
                        AxisValueLabel {
                            if months < 12 {
                                Text("\(months) mo")
                            } else {
                                Text("\(months / 12) yr")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    private var unpaidDebts: [Debt] {
        return debts.filter { !$0.isPaid }
    }
    
    private var orderedDebts: [Debt] {
        return DebtStrategy.ordenedRepaymentPlan(debts: unpaidDebts, strategy: selectedStrategy)
    }
    
    private var totalMinimumPayment: Double {
        return unpaidDebts.reduce(0) { $0 + $1.minimumPayment }
    }
    
    private var minPayment: Double {
        return max(totalMinimumPayment, 100) // At least minimal payments
    }
    
    private var maxPayment: Double {
        return max(totalMinimumPayment * 3, 5000) // 3x minimum or $5000, whichever is greater
    }
    
    private var recommendedPayment: Double {
        // Recommend 20% more than minimum or enough to pay off in 3 years, whichever is greater
        let baseRecommended = totalMinimumPayment * 1.2
        
        // Calculate payment needed for 3 year payoff
        let totalDebt = unpaidDebts.reduce(0) { $0 + $1.amount }
        let avgInterestRate = unpaidDebts.reduce(0) { $0 + $1.interestRate } / Double(max(1, unpaidDebts.count))
        
        // Simple approximation for payment to pay off in 3 years
        let monthlyRate = avgInterestRate / 100.0 / 12.0
        let months = 36.0 // 3 years
        
        // Amortization formula: P = (r * PV) / (1 - (1 + r)^-n)
        // Where: P = payment, r = monthly rate, PV = present value, n = number of months
        let threeYearPayment: Double
        if monthlyRate > 0 {
            threeYearPayment = (monthlyRate * totalDebt) / (1 - pow(1 + monthlyRate, -months))
        } else {
            threeYearPayment = totalDebt / months
        }
        
        return max(baseRecommended, threeYearPayment)
    }
    
    private var debtFreeTime: (months: Int, amountSaved: Double) {
        return DebtStrategy.calculateTimeToBeFree(debts: unpaidDebts, monthlyPayment: monthlyPayment)
    }
    
    private struct StrategyComparisonItem {
        let strategy: RepaymentStrategy
        let months: Int
    }
    
    private var strategyComparisonData: [StrategyComparisonItem] {
        return RepaymentStrategy.allCases
            .filter { $0 != .custom } // Skip custom for comparison
            .map { strategy in
                let result = DebtStrategy.calculateTimeToBeFree(
                    debts: DebtStrategy.ordenedRepaymentPlan(debts: unpaidDebts, strategy: strategy),
                    monthlyPayment: monthlyPayment
                )
                return StrategyComparisonItem(strategy: strategy, months: result.months)
            }
            .sorted { $0.months < $1.months }
    }
    
    // MARK: - Helper Methods
    
    private func initializeValues() {
        // Set initial strategy to recommended
        if !unpaidDebts.isEmpty {
            selectedStrategy = DebtStrategy.getRecommendedStrategy(for: unpaidDebts)
            monthlyPayment = recommendedPayment
        }
    }
}

// MARK: - Supporting Views

struct DebtOrderCard: View {
    let index: Int
    let debt: Debt
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(debt.name)
                    .font(.headline)
                
                Text(String(format: "$%.2f · %.1f%%", debt.amount, debt.interestRate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Minimum")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "$%.0f/mo", debt.minimumPayment))
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PayOffDateView: View {
    let strategy: RepaymentStrategy
    let monthlyPayment: Double
    @Environment(\.dismiss) private var dismiss
    @Query private var debts: [Debt]
    
    var unpaidDebts: [Debt] {
        return debts.filter { !$0.isPaid }
    }
    
    var debtFreeDate: Date {
        let result = DebtStrategy.calculateTimeToBeFree(debts: unpaidDebts, monthlyPayment: monthlyPayment)
        return Calendar.current.date(byAdding: .month, value: result.months, to: Date()) ?? Date()
    }
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("You'll Be Debt-Free On")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(debtFreeDate, style: .date)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.green)
            }
            
            Image(systemName: "party.popper.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
            
            VStack(spacing: 15) {
                InfoRow(title: "Strategy", value: strategy.rawValue)
                InfoRow(title: "Monthly Payment", value: String(format: "$%.0f", monthlyPayment))
                
                let result = DebtStrategy.calculateTimeToBeFree(debts: unpaidDebts, monthlyPayment: monthlyPayment)
                if result.months < 12 {
                    InfoRow(title: "Time to Freedom", value: "\(result.months) months")
                } else {
                    InfoRow(title: "Time to Freedom", value: "\(result.months / 12) years, \(result.months % 12) months")
                }
                
                InfoRow(title: "Interest Saved", value: String(format: "$%.0f", result.amountSaved))
                
                Divider()
                
                InfoRow(title: "Total Debt", value: String(format: "$%.0f", unpaidDebts.reduce(0) { $0 + $1.amount }))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    struct InfoRow: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(value)
                    .font(.headline)
            }
        }
    }
}

#Preview {
    StrategyView()
        .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 