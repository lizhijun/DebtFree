import Foundation

enum RepaymentStrategy: String, CaseIterable, Identifiable {
    case snowball = "Snowball Method"
    case avalanche = "Avalanche Method"
    case highestBalance = "Highest Balance First"
    case lowestBalance = "Lowest Balance First"
    case highestInterest = "Highest Interest First"
    case custom = "Custom Order"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .snowball:
            return "Pay minimum on all debts, then put extra money toward the smallest debt first. When it's paid off, apply that payment to the next smallest debt."
        case .avalanche:
            return "Pay minimum on all debts, then put extra money toward the highest interest debt first. This saves the most money in interest over time."
        case .highestBalance:
            return "Focus on paying off the debt with the highest balance first. Good for eliminating large debts quickly."
        case .lowestBalance:
            return "Similar to the snowball method, but doesn't necessarily consider interest rates. Just focuses on eliminating small debts first."
        case .highestInterest:
            return "Similar to the avalanche method, prioritizing the highest interest debt regardless of balance."
        case .custom:
            return "Create your own custom repayment order based on your preferences."
        }
    }
}

struct DebtStrategy {
    static func getRecommendedStrategy(for debts: [Debt]) -> RepaymentStrategy {
        // Count the number of debts
        let debtCount = debts.count
        
        // Get total debt amount
        let totalDebt = debts.reduce(0) { $0 + $1.amount }
        
        // Check average interest rate
        let avgInterestRate = debts.reduce(0) { $0 + $1.interestRate } / Double(max(1, debtCount))
        
        // Check if there's a high interest rate debt (over 15%)
        let hasHighInterestDebt = debts.contains { $0.interestRate > 15.0 }
        
        // Check if there are small balance debts (under $1000)
        let hasSmallDebts = debts.contains { $0.amount < 1000 }
        
        // Check if there's a large balance debt (over 50% of total)
        let hasLargeDebt = debts.contains { $0.amount > totalDebt * 0.5 }
        
        // Base strategy recommendation on debt profile
        if hasHighInterestDebt && totalDebt > 10000 {
            return .avalanche
        } else if hasSmallDebts && debtCount >= 3 {
            return .snowball
        } else if hasLargeDebt {
            return .highestBalance
        } else if avgInterestRate > 10.0 {
            return .highestInterest
        } else {
            return .snowball // Default to snowball as it's psychologically rewarding
        }
    }
    
    static func ordenedRepaymentPlan(debts: [Debt], strategy: RepaymentStrategy) -> [Debt] {
        var orderedDebts = debts
        
        switch strategy {
        case .snowball:
            orderedDebts.sort { $0.amount < $1.amount }
        case .avalanche, .highestInterest:
            orderedDebts.sort { $0.interestRate > $1.interestRate }
        case .highestBalance:
            orderedDebts.sort { $0.amount > $1.amount }
        case .lowestBalance:
            orderedDebts.sort { $0.amount < $1.amount }
        case .custom:
            // With custom, we'd use a user-defined order
            // For now, just leave as is
            break
        }
        
        return orderedDebts
    }
    
    static func calculateTimeToBeFree(debts: [Debt], monthlyPayment: Double) -> (months: Int, amountSaved: Double) {
        guard !debts.isEmpty else { return (0, 0) }
        
        let strategy = getRecommendedStrategy(for: debts)
        let orderedDebts = ordenedRepaymentPlan(debts: debts, strategy: strategy)
        
        // Make a copy of the debts we can modify
        var simulatedDebts = orderedDebts.map { debt in
            (id: debt.id, amount: debt.amount, interestRate: debt.interestRate, minimumPayment: debt.minimumPayment)
        }
        
        // Total minimum payment across all debts
        let totalMinPayment = simulatedDebts.reduce(0) { $0 + $1.minimumPayment }
        
        // Extra payment to apply to first debt in order
        var extraPayment = max(0, monthlyPayment - totalMinPayment)
        
        var months = 0
        var totalInterestPaid = 0.0
        var totalInterestWithMinimums = 0.0
        
        // Calculate estimated time and interest with just minimum payments
        for debt in simulatedDebts {
            let monthsToPayOff = ceil(debt.amount / debt.minimumPayment)
            let interestRate = debt.interestRate / 100.0 / 12.0 // Monthly interest rate
            totalInterestWithMinimums += debt.amount * interestRate * monthsToPayOff
        }
        
        // Simulate month-by-month repayment
        while !simulatedDebts.isEmpty {
            months += 1
            
            // Apply interest
            for i in 0..<simulatedDebts.count {
                let monthlyInterestRate = simulatedDebts[i].interestRate / 100.0 / 12.0
                let interestAmount = simulatedDebts[i].amount * monthlyInterestRate
                simulatedDebts[i].amount += interestAmount
                totalInterestPaid += interestAmount
            }
            
            // Pay minimum on all debts
            for i in 0..<simulatedDebts.count {
                let payment = min(simulatedDebts[i].amount, simulatedDebts[i].minimumPayment)
                simulatedDebts[i].amount -= payment
            }
            
            // Apply extra payment to first debt
            if !simulatedDebts.isEmpty && extraPayment > 0 {
                let extraPaymentToApply = min(simulatedDebts[0].amount, extraPayment)
                simulatedDebts[0].amount -= extraPaymentToApply
            }
            
            // Remove any paid off debts
            simulatedDebts = simulatedDebts.filter { $0.amount > 0.1 } // Allow for small rounding errors
            
            // If debts paid off, distribute extra money to next debt
            if !simulatedDebts.isEmpty {
                extraPayment = max(0, monthlyPayment - simulatedDebts.reduce(0) { $0 + $1.minimumPayment })
            }
            
            // Failsafe to prevent infinite loops
            if months > 600 { // 50 years
                break
            }
        }
        
        let amountSaved = totalInterestWithMinimums - totalInterestPaid
        return (months, amountSaved)
    }
} 