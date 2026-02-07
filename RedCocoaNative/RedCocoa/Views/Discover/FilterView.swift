import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Distance") {
                    Text("Within 50 miles")
                        .foregroundStyle(Color.textOnDark)
                }
                .listRowBackground(Color.bgCard)
                
                Section("Age Range") {
                    Text("18 - 35")
                        .foregroundStyle(Color.textOnDark)
                }
                .listRowBackground(Color.bgCard)
                
                Section("Looking For") {
                    Text("Everyone")
                        .foregroundStyle(Color.textOnDark)
                }
                .listRowBackground(Color.bgCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgDark)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.brand)
                }
            }
        }
    }
}
