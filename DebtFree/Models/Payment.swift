import Foundation
import SwiftData

@Model
final class Payment {
    var amount: Double
    var date: Date
    var debt: Debt?
    var notes: String?
    
    init(amount: Double, date: Date = Date(), debt: Debt? = nil, notes: String? = nil) {
        self.amount = amount
        self.date = date
        self.debt = debt
        self.notes = notes
    }
} 