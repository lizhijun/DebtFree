import Foundation
import SwiftData

@Model
final class Debt {
    var name: String
    var amount: Double
    var interestRate: Double
    var minimumPayment: Double
    var dueDate: Date
    var category: DebtCategory
    var isPaid: Bool
    var createdDate: Date
    var notes: String?
    
    init(name: String, 
         amount: Double, 
         interestRate: Double, 
         minimumPayment: Double, 
         dueDate: Date, 
         category: DebtCategory = .other, 
         isPaid: Bool = false, 
         notes: String? = nil) {
        self.name = name
        self.amount = amount
        self.interestRate = interestRate
        self.minimumPayment = minimumPayment
        self.dueDate = dueDate
        self.category = category
        self.isPaid = isPaid
        self.createdDate = Date()
        self.notes = notes
    }
}

enum DebtCategory: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case studentLoan = "Student Loan"
    case mortgage = "Mortgage"
    case carLoan = "Car Loan"
    case personalLoan = "Personal Loan"
    case medical = "Medical"
    case other = "Other"
} 