import SwiftUI

struct MainTabView: View {
    @AppStorage("darkMode") private var darkMode = false
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
            
            DebtsListView()
                .tabItem {
                    Label("Debts", systemImage: "creditcard")
                }
            
            StrategyView()
                .tabItem {
                    Label("Strategy", systemImage: "brain")
                }
            
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }
            
            PaymentsView()
                .tabItem {
                    Label("Payments", systemImage: "dollarsign.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Debt.self, Payment.self], inMemory: true)
} 