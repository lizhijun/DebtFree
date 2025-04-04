import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query private var debts: [Debt]
    @Query private var payments: [Payment]
    @State private var selectedReport: ReportType = .overview
    
    enum ReportType: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case paymentProgress = "Payment Progress"
        case categoryBreakdown = "Category Breakdown"
        case interestAnalysis = "Interest Analysis"
        
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .overview:
                return "chart.pie"
            case .paymentProgress:
                return "chart.line.uptrend.xyaxis"
            case .categoryBreakdown:
                return "tag"
            case .interestAnalysis:
                return "percent"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                reportPicker
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedReport {
                        case .overview:
                            overviewReport
                        case .paymentProgress:
                            paymentProgressReport
                        case .categoryBreakdown:
                            categoryBreakdownReport
                        case .interestAnalysis:
                            interestAnalysisReport
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Reports & Insights")
        }
    }
    
    // MARK: - Report Picker
    
    private var reportPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ReportType.allCases) { reportType in
                    Button {
                        selectedReport = reportType
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: reportType.systemImage)
                                .font(.headline)
                            
                            Text(reportType.rawValue)
                                .font(.subheadline)
                        }
                        .frame(minWidth: 80)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedReport == reportType ? .white : .primary)
                        .background(selectedReport == reportType ? Color.blue : Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Overview Report
    
    private var overviewReport: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Summary stats
            HStack(spacing: 15) {
                StatCard(
                    title: "Total Debt",
                    value: String(format: "$%.2f", totalDebt),
                    icon: "dollarsign.circle",
                    color: .red
                )
                
                StatCard(
                    title: "Paid So Far",
                    value: String(format: "$%.2f", totalPaidAmount),
                    icon: "arrow.up.circle",
                    color: .green
                )
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "# of Debts",
                    value: "\(debts.count)",
                    icon: "creditcard",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg. Interest",
                    value: String(format: "%.1f%%", averageInterestRate),
                    icon: "percent",
                    color: .orange
                )
            }
            
            // Progress ring
            VStack(alignment: .leading, spacing: 12) {
                Text("Overall Progress")
                    .font(.headline)
                
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(min(totalPaidAmount / (totalDebt + totalPaidAmount), 1.0)))
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 150, height: 150)
                        
                        VStack {
                            Text(String(format: "%.0f%%", (totalPaidAmount / (totalDebt + totalPaidAmount)) * 100))
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Paid Off")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Paid")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", totalPaidAmount))
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", totalDebt))
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.leading)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Debt-free projection
            VStack(alignment: .leading, spacing: 12) {
                Text("Debt-Free Projection")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Current Minimum Payments")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let debtFreeTime = DebtStrategy.calculateTimeToBeFree(
                            debts: debts.filter { !$0.isPaid },
                            monthlyPayment: debts.filter { !$0.isPaid }.reduce(0) { $0 + $1.minimumPayment }
                        )
                        
                        if debtFreeTime.months > 600 {
                            Text("Never")
                                .font(.headline)
                                .foregroundColor(.red)
                        } else if debtFreeTime.months > 12 {
                            Text("\(debtFreeTime.months / 12) years, \(debtFreeTime.months % 12) months")
                                .font(.headline)
                        } else {
                            Text("\(debtFreeTime.months) months")
                                .font(.headline)
                        }
                    }
                    
                    HStack {
                        Text("Recommended Strategy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let recommended = DebtStrategy.getRecommendedStrategy(for: debts.filter { !$0.isPaid })
                        Text(recommended.rawValue)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    NavigationLink(destination: StrategyView()) {
                        Text("View Detailed Strategy")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Payment Progress Report
    
    private var paymentProgressReport: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Payment Activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Payment Activity")
                    .font(.headline)
                
                if paymentsGroupedByMonth.isEmpty {
                    Text("No payment data available yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Chart {
                        ForEach(paymentsGroupedByMonth.sorted(by: { $0.key < $1.key }), id: \.key) { month, amount in
                            BarMark(
                                x: .value("Month", month, unit: .month),
                                y: .value("Amount", amount)
                            )
                            .foregroundStyle(Color.green.gradient)
                        }
                    }
                    .frame(height: 250)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            if let date = value.as(Date.self) {
                                AxisGridLine()
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            if let amount = value.as(Double.self) {
                                AxisGridLine()
                                AxisValueLabel {
                                    Text(String(format: "$%.0f", amount))
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Debt Reduction Progress
            VStack(alignment: .leading, spacing: 12) {
                Text("Debt Reduction Progress")
                    .font(.headline)
                
                if debtReductionOverTime.isEmpty {
                    Text("No debt reduction data available yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Chart {
                        ForEach(debtReductionOverTime.sorted(by: { $0.key < $1.key }), id: \.key) { month, amount in
                            LineMark(
                                x: .value("Month", month, unit: .month),
                                y: .value("Amount", amount)
                            )
                            .foregroundStyle(Color.red.gradient)
                            .interpolationMethod(.catmullRom)
                        }
                        .symbol {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .frame(height: 250)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            if let date = value.as(Date.self) {
                                AxisGridLine()
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            if let amount = value.as(Double.self) {
                                AxisGridLine()
                                AxisValueLabel {
                                    Text(String(format: "$%.0f", amount))
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Payment Stats
            VStack(alignment: .leading, spacing: 12) {
                Text("Payment Statistics")
                    .font(.headline)
                
                let statsGrid = [
                    ("Total Payments", String(format: "$%.2f", totalPaidAmount)),
                    ("Number of Payments", "\(payments.count)"),
                    ("Average Payment", String(format: "$%.2f", payments.isEmpty ? 0 : totalPaidAmount / Double(payments.count))),
                    ("Largest Payment", String(format: "$%.2f", payments.max(by: { $0.amount < $1.amount })?.amount ?? 0)),
                    ("Last Payment", payments.isEmpty ? "None" : (payments.sorted { $0.date > $1.date }.first?.date.formatted(date: .abbreviated, time: .omitted) ?? "None")),
                    ("Monthly Average", String(format: "$%.2f", averageMonthlyPayment))
                ]
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(statsGrid, id: \.0) { title, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(value)
                                .font(.headline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Category Breakdown Report
    
    private var categoryBreakdownReport: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Category Pie Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Debt by Category")
                    .font(.headline)
                
                if debtByCategory.isEmpty {
                    Text("No debt category data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Chart {
                        ForEach(debtByCategory.sorted(by: { $0.amount > $1.amount }), id: \.category) { item in
                            SectorMark(
                                angle: .value("Amount", item.amount),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("Category", item.category))
                            .annotation(position: .overlay) {
                                Text("\(Int(item.percentage))%")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .frame(height: 300)
                    .chartLegend(position: .bottom)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Category Details
            VStack(alignment: .leading, spacing: 12) {
                Text("Category Details")
                    .font(.headline)
                
                ForEach(debtByCategory.sorted(by: { $0.amount > $1.amount }), id: \.category) { item in
                    HStack {
                        Text(item.category)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", item.amount))
                            .font(.headline)
                        
                        Text(String(format: "(%.0f%%)", item.percentage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if item.category != debtByCategory.sorted(by: { $0.amount > $1.amount }).last?.category {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Category-specific insights
            if let highestCategory = debtByCategory.max(by: { $0.amount < $1.amount }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Insights")
                        .font(.headline)
                    
                    Text("Your highest debt category is '\(highestCategory.category)' at \(String(format: "$%.2f", highestCategory.amount)) (\(String(format: "%.0f%%", highestCategory.percentage)) of total debt).")
                        .font(.subheadline)
                    
                    if highestCategory.category == "Credit Card" {
                        Text("Consider using the Avalanche method to tackle high-interest credit card debt first.")
                            .font(.subheadline)
                            .padding(.top, 8)
                    } else if highestCategory.category == "Student Loan" {
                        Text("Student loans often have lower interest rates. Check if you qualify for loan forgiveness programs.")
                            .font(.subheadline)
                            .padding(.top, 8)
                    } else if highestCategory.category == "Mortgage" {
                        Text("Mortgages typically have lower interest rates. Focus on higher interest debts first.")
                            .font(.subheadline)
                            .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Interest Analysis Report
    
    private var interestAnalysisReport: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Interest Rate Comparison
            VStack(alignment: .leading, spacing: 12) {
                Text("Interest Rate Comparison")
                    .font(.headline)
                
                if debts.isEmpty {
                    Text("No debt data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Chart {
                        ForEach(debts.sorted(by: { $0.interestRate > $1.interestRate }), id: \.id) { debt in
                            BarMark(
                                x: .value("Rate", debt.interestRate),
                                y: .value("Debt", debt.name)
                            )
                            .foregroundStyle(by: .value("Debt", debt.name))
                        }
                    }
                    .frame(height: 300)
                    .chartXAxis {
                        AxisMarks { value in
                            if let rate = value.as(Double.self) {
                                AxisGridLine()
                                AxisValueLabel {
                                    Text("\(Int(rate))%")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Monthly Interest Cost
            VStack(alignment: .leading, spacing: 12) {
                Text("Monthly Interest Cost")
                    .font(.headline)
                
                ForEach(debts.sorted(by: { calculateMonthlyInterest($0) > calculateMonthlyInterest($1) }), id: \.id) { debt in
                    let monthlyInterest = calculateMonthlyInterest(debt)
                    HStack {
                        Text(debt.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f/month", monthlyInterest))
                            .font(.headline)
                            .foregroundColor(monthlyInterest > 100 ? .red : .primary)
                    }
                    .padding(.vertical, 8)
                    
                    if debt.id != debts.sorted(by: { calculateMonthlyInterest($0) > calculateMonthlyInterest($1) }).last?.id {
                        Divider()
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                HStack {
                    Text("Total Monthly Interest")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f/month", totalMonthlyInterest))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Interest Insights
            VStack(alignment: .leading, spacing: 12) {
                Text("Interest Insights")
                    .font(.headline)
                
                Text("You're paying \(String(format: "$%.2f", totalMonthlyInterest)) in interest every month. That's \(String(format: "$%.2f", totalMonthlyInterest * 12)) per year!")
                    .font(.subheadline)
                    .padding(.bottom, 8)
                
                if let highestInterestDebt = debts.max(by: { $0.interestRate < $1.interestRate }) {
                    Text("Your highest interest debt is '\(highestInterestDebt.name)' at \(String(format: "%.2f%%", highestInterestDebt.interestRate)). Prioritize this debt to save on interest costs.")
                        .font(.subheadline)
                        .padding(.bottom, 8)
                }
                
                if let recommendation = interestRecommendation {
                    Text(recommendation)
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Properties
    
    private var totalDebt: Double {
        return debts.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalPaidAmount: Double {
        return payments.reduce(0) { $0 + $1.amount }
    }
    
    private var averageInterestRate: Double {
        guard !debts.isEmpty else { return 0 }
        return debts.reduce(0) { $0 + $1.interestRate } / Double(debts.count)
    }
    
    private var averageMonthlyPayment: Double {
        let calendar = Calendar.current
        let paymentsByMonth: [Date: Double] = payments.reduce(into: [:]) { result, payment in
            let components = calendar.dateComponents([.year, .month], from: payment.date)
            guard let date = calendar.date(from: components) else { return }
            result[date, default: 0] += payment.amount
        }
        
        guard !paymentsByMonth.isEmpty else { return 0 }
        return paymentsByMonth.values.reduce(0, +) / Double(paymentsByMonth.count)
    }
    
    private var paymentsGroupedByMonth: [Date: Double] {
        let calendar = Calendar.current
        
        // Create a date range for the last 6 months
        let today = Date()
        var startDate = calendar.date(byAdding: .month, value: -5, to: today) ?? today
        startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate)) ?? startDate
        
        // Initialize dictionary with all months (including those with zero payments)
        var result: [Date: Double] = [:]
        var currentDate = startDate
        
        while currentDate <= today {
            result[currentDate] = 0
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
        
        // Fill in actual payment data
        for payment in payments {
            let components = calendar.dateComponents([.year, .month], from: payment.date)
            guard let monthDate = calendar.date(from: components) else { continue }
            
            // Only include payments from the last 6 months
            if monthDate >= startDate && monthDate <= today {
                result[monthDate, default: 0] += payment.amount
            }
        }
        
        return result
    }
    
    private var debtReductionOverTime: [Date: Double] {
        let calendar = Calendar.current
        
        // Create a date range for the last 6 months
        let today = Date()
        var startDate = calendar.date(byAdding: .month, value: -5, to: today) ?? today
        startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate)) ?? startDate
        
        // If we have no payments, return empty
        if payments.isEmpty {
            return [:]
        }
        
        // Get total initial debt amount
        let totalInitialDebt = totalDebt + totalPaidAmount
        
        // Group payments by month
        var paymentsByMonth: [Date: Double] = [:]
        for payment in payments {
            let components = calendar.dateComponents([.year, .month], from: payment.date)
            guard let monthDate = calendar.date(from: components) else { continue }
            paymentsByMonth[monthDate, default: 0] += payment.amount
        }
        
        // Sort payment dates
        let sortedMonths = paymentsByMonth.keys.sorted()
        
        // Initialize result dictionary
        var result: [Date: Double] = [:]
        
        // Initialize with full debt amount
        var remainingDebt = totalInitialDebt
        
        // Find first month with payment data
        guard let firstPaymentMonth = sortedMonths.first else {
            return [:]
        }
        
        // Function to get the first date of a month or next month
        func getFirstDayOrNext(of date: Date) -> Date? {
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components)
        }
        
        // Fill in debt reduction timeline
        var currentDate = min(startDate, firstPaymentMonth)
        
        // For dates before our 6-month window, just reduce the debt
        for month in sortedMonths where month < startDate {
            remainingDebt -= paymentsByMonth[month, default: 0]
        }
        
        // Now chart the recent 6 months
        while currentDate <= today {
            result[currentDate] = remainingDebt
            
            if let payment = paymentsByMonth[currentDate] {
                remainingDebt -= payment
            }
            
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
        
        return result
    }
    
    private struct CategoryBreakdown {
        let category: String
        let amount: Double
        let percentage: Double
    }
    
    private var debtByCategory: [CategoryBreakdown] {
        let debtsByCategory = Dictionary(grouping: debts.filter { !$0.isPaid }, by: { $0.category.rawValue })
        
        return debtsByCategory.map { category, debts in
            let amount = debts.reduce(0) { $0 + $1.amount }
            let percentage = totalDebt > 0 ? (amount / totalDebt) * 100 : 0
            return CategoryBreakdown(category: category, amount: amount, percentage: percentage)
        }
    }
    
    private func calculateMonthlyInterest(_ debt: Debt) -> Double {
        let monthlyRate = debt.interestRate / 100.0 / 12.0
        return debt.amount * monthlyRate
    }
    
    private var totalMonthlyInterest: Double {
        return debts.filter { !$0.isPaid }.reduce(0) { $0 + calculateMonthlyInterest($1) }
    }
    
    private var interestRecommendation: String? {
        let highInterestDebts = debts.filter { $0.interestRate > 15 && !$0.isPaid }
        
        if !highInterestDebts.isEmpty {
            return "Consider balance transfer options for your high-interest debts to save on interest costs."
        }
        
        let avgInterestRate = debts.filter { !$0.isPaid }.reduce(0) { $0 + $1.interestRate } / Double(max(1, debts.filter { !$0.isPaid }.count))
        
        if avgInterestRate > 10 {
            return "Your average interest rate is high at \(String(format: "%.2f%%", avgInterestRate)). Look into debt consolidation options."
        }
        
        return nil
    }
}

// MARK: - Supporting Views

struct StatCard: View {
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
                .font(.title2)
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
    ReportsView()
        .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 