import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("filterDistance") private var distanceMiles = 50
    @AppStorage("filterAgeMin") private var ageMin = 18
    @AppStorage("filterAgeMax") private var ageMax = 35
    @AppStorage("filterLookingFor") private var lookingFor = "Everyone"
    @AppStorage("filterHairColors") private var hairColorsRaw = ""
    @AppStorage("filterEthnicities") private var ethnicitiesRaw = ""
    
    private let lookingForOptions = ["Everyone", "Men", "Women", "Non-binary"]
    
    private var selectedHairColors: Set<String> {
        Set(hairColorsRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }
    
    private var selectedEthnicities: Set<String> {
        Set(ethnicitiesRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Distance") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Within \(distanceMiles) miles")
                            .foregroundStyle(Color.textOnDark)
                        Slider(value: Binding(
                            get: { Double(distanceMiles) },
                            set: { distanceMiles = Int($0) }
                        ), in: 5...100, step: 5)
                        .tint(Color.brand)
                    }
                }
                .listRowBackground(Color.bgCard)
                
                Section("Age Range") {
                    HStack {
                        Text("Min")
                            .foregroundStyle(Color.textMuted)
                        Picker("Min age", selection: $ageMin) {
                            ForEach(18...50, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(Color.textOnDark)
                        Text("Max")
                            .foregroundStyle(Color.textMuted)
                        Picker("Max age", selection: $ageMax) {
                            ForEach(18...50, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(Color.textOnDark)
                    }
                    .onChange(of: ageMin) { _, newVal in
                        if newVal > ageMax { ageMax = newVal }
                    }
                    .onChange(of: ageMax) { _, newVal in
                        if newVal < ageMin { ageMin = newVal }
                    }
                }
                .listRowBackground(Color.bgCard)
                
                Section("Looking For") {
                    Picker("Looking for", selection: $lookingFor) {
                        ForEach(lookingForOptions, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundStyle(Color.textOnDark)
                }
                .listRowBackground(Color.bgCard)
                
                Section("Hair Color") {
                    Text("Include profiles with any selected hair color. Leave empty to show all.")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                    ForEach(ProfileOptions.hairColorOptions, id: \.self) { opt in
                        Button {
                            var current = selectedHairColors
                            if current.contains(opt) {
                                current.remove(opt)
                            } else {
                                current.insert(opt)
                            }
                            hairColorsRaw = current.sorted().joined(separator: ",")
                        } label: {
                            HStack {
                                Text(opt).foregroundStyle(Color.textOnDark)
                                Spacer()
                                if selectedHairColors.contains(opt) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brand)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Color.bgCard)
                
                Section("Ethnicity") {
                    Text("Include profiles with any selected ethnicity. Leave empty to show all.")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                    ForEach(ProfileOptions.ethnicityOptions, id: \.self) { opt in
                        Button {
                            var current = selectedEthnicities
                            if current.contains(opt) {
                                current.remove(opt)
                            } else {
                                current.insert(opt)
                            }
                            ethnicitiesRaw = current.sorted().joined(separator: ",")
                        } label: {
                            HStack {
                                Text(opt).foregroundStyle(Color.textOnDark)
                                Spacer()
                                if selectedEthnicities.contains(opt) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brand)
                                }
                            }
                        }
                    }
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
            .smoothAppear()
        }
    }
}
