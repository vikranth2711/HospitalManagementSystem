//
//  labTechnicianCRUD.swift
//  Hospitality
//
//  Created by admin@33 on 23/04/25.
//

import SwiftUI

struct LabTechniciansListView: View {
    @StateObject private var dataStore = MockHospitalDataStore()
    @State private var showingAddTechnician = false
    @State private var searchText = ""
    @State private var selectedSpecialty = "All"
    @State private var editMode: EditMode = .inactive
    @State private var selectedTechnicians = Set<String>()
    @State private var showingDeleteConfirmation = false
    
    private var specialties: [String] {
        var specs = ["All"]
        let allSpecs = Set(dataStore.labTypes.map { $0.assigned_lab })
        specs.append(contentsOf: allSpecs.sorted())
        return specs
    }
    
    private var filteredTechnicians: [LabStaff] {
        var result = dataStore.labStaff
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.staffName.localizedCaseInsensitiveContains(searchText) ||
                $0.staffEmail.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedSpecialty != "All" {
            result = result.filter { staff in
                if let tech = dataStore.labTechnicians.first(where: { $0.staffId == staff.id }) {
                    // Find the lab by matching the assigned_lab name
                    return dataStore.labTypes.contains { $0.assigned_lab == selectedSpecialty }
                }
                return false
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color(.systemGroupedBackground))
            
            // Filter Section
            VStack(spacing: 12) {
                HStack {
                    Text("FILTERS")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 16)
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    FilterPill(
                        title: "Specialty",
                        selection: $selectedSpecialty,
                        options: specialties,
                        accentColor: .main
                    )
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            List(selection: $selectedTechnicians) {
                            ForEach(filteredTechnicians) { staff in
                                NavigationLink(destination: LabTechnicianDetailView(staff: staff)) {
                                    LabTechnicianRow(staff: staff)
                                }
                                .tag(staff.id)
                            }
                            .onDelete(perform: deleteTechnician)
                        }
        }
        .navigationTitle("Lab Technicians")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if editMode == .active {
                    Button(action: {
                        if !selectedTechnicians.isEmpty {
                            showingDeleteConfirmation = true
                        }
                    }) {
                        Image(systemName: "trash")
                            .tint(.red)
                    }
                    .disabled(selectedTechnicians.isEmpty)
                }
                
                Button(action: { showingAddTechnician = true }) {
                    Image(systemName: "plus")
                        .tint(.main)
                }
                
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingAddTechnician) {
            AddEditLabTechnicianView { staff, techDetails in
                dataStore.createLabTechnician(staff: staff, techDetails: techDetails)
                showingAddTechnician = false
            }
            .environmentObject(dataStore)
        }
        .actionSheet(isPresented: $showingDeleteConfirmation) {
            ActionSheet(
                title: Text("Delete Technicians"),
                message: Text("Are you sure you want to delete \(selectedTechnicians.count) technician(s)?"),
                buttons: [
                    .destructive(Text("Delete"), action: deleteSelectedTechnicians),
                    .cancel()
                ]
            )
        }
        .onAppear {
            dataStore.fetchStaff() // Fetches lab technicians from API
            dataStore.fetchLabs()  // Ensure labs are fetched for filtering
        }
    }
    
    private func deleteTechnician(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredTechnicians[$0].id }
        deleteTechnicians(ids: idsToDelete)
    }
    
    private func deleteSelectedTechnicians() {
        deleteTechnicians(ids: Array(selectedTechnicians))
        selectedTechnicians.removeAll()
        editMode = .inactive
    }
    
    private func deleteTechnicians(ids: [String]) {
        dataStore.deleteStaff(ids: ids)
    }
}

struct LabTechnicianRow: View {
    let staff: LabStaff
    @EnvironmentObject var dataStore: MockHospitalDataStore
    
    var labTechnician: LabTechnicianDetails? {
        dataStore.labTechnicians.first { $0.staffId == staff.id }
    }
    
    var lab: LabType? {
        guard let labId = labTechnician?.assignedLabId else { return nil }
        return dataStore.labTypes.first { String($0.id) == labId }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.main)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.staffName)
                    .font(.headline)
                
                if let labName = lab?.assigned_lab {
                    Text(labName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let experience = labTechnician?.labExperienceYears {
                Text("\(experience) yrs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddEditLabTechnicianView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var labTechService = LabTechnicianService.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var dataStore: MockHospitalDataStore
    
    var onSave: (LabStaff, LabTechnicianDetails) -> Void
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var mobile: String = ""
    @State private var certification: String = ""
    @State private var experience: String = ""
    @State private var assignedLabName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Mobile", text: $mobile)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Certification", text: $certification)
                    TextField("Experience (Years)", text: $experience)
                        .keyboardType(.numberPad)
                    
                    Picker("Assigned Lab", selection: $assignedLabName) {
                        ForEach(dataStore.labTypes, id: \.assigned_lab) { lab in
                            Text(lab.assigned_lab).tag(lab.assigned_lab)
                        }
                    }
                }
            }
            .navigationTitle("Add Lab Technician")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        createLabTechnician()
                    }
                    .disabled(name.isEmpty || email.isEmpty || certification.isEmpty || assignedLabName.isEmpty)
                }
            }
        }
    }
    
    private func createLabTechnician() {
        guard let experienceYears = Int(experience) else {
            alertMessage = "Please enter valid experience years"
            showingAlert = true
            return
        }
        
        print("Input values: name=\(name), email=\(email), mobile=\(mobile), certification=\(certification), experience=\(experience), assignedLabId=\(assignedLabName)")
        print("Lab Types: \(dataStore.labTypes)")
        
        labTechService.createLabTechnician(
            name: name,
            email: email,
            mobile: mobile,
            certification: certification,
            experienceYears: experienceYears,
            assignedLab: assignedLabName,
            joiningDate: Date(),
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        print("Success: Created lab technician with staff_id=\(response.staff_id)")
                        let staff = LabStaff(
                            id: response.staff_id,
                            staffName: name,
                            roleId: "lab_tech_role_id",
                            createdAt: Date(),
                            staffEmail: email,
                            staffMobile: mobile
                        )
                        
                        let techDetails = LabTechnicianDetails(
                            id: UUID().uuidString,
                            staffId: response.staff_id,
                            certificationId: certification,
                            labExperienceYears: experienceYears,
                            assignedLabId: assignedLabName
                        )
                        
                        self.onSave(staff, techDetails)
                        self.presentationMode.wrappedValue.dismiss()
                        
                    case .failure(let error):
                        print("Failure: \(error.localizedDescription)")
                        self.alertMessage = "Failed to create lab technician: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        )
    }
}

struct LabTechnicianDetailView: View {
    let staff: LabStaff
    @EnvironmentObject var dataStore: MockHospitalDataStore
    
    var labTechnician: LabTechnicianDetails? {
        dataStore.labTechnicians.first { $0.staffId == staff.id }
    }
    
    var lab: Lab? {
        guard let labId = labTechnician?.assignedLabId else { return nil }
        return dataStore.labs.first { $0.id == labId }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.main)
                    Spacer()
                }
                
                HStack {
                    Text("Name")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(staff.staffName)
                }
                
                if let labName = lab?.labName {
                    HStack {
                        Text("Assigned Lab")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(labName)
                    }
                }
                
                if let experience = labTechnician?.labExperienceYears {
                    HStack {
                        Text("Experience")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(experience) years")
                    }
                }
                
                if let certification = labTechnician?.certificationId {
                    HStack {
                        Text("Certification")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(certification)
                    }
                }
            }
            
            Section(header: Text("Contact")) {
                HStack {
                    Text("Email")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(staff.staffEmail)
                }
                
                HStack {
                    Text("Mobile")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(staff.staffMobile)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(staff.staffName)
    }
}

struct FilterPill<Selection: Hashable>: View {
    let title: String
    @Binding var selection: Selection
    let options: [Selection]
    let accentColor: Color
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    HStack {
                        Text(String(describing: option))
                        if selection == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selection as! String == "All" ? title : String(describing: selection))
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(selection as! String == "All" ? .gray : .white)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(selection as! String == "All" ? .gray : .white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selection as! String == "All" ? Color(.systemGray5) : accentColor)
            )
            .animation(.easeOut, value: selection)
        }
    }
}
