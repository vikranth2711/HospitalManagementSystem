//
//  labTechnicianCRUD.swift
//  Hospitality
//
//  Created by admin@33 on 23/04/25.
//

import SwiftUI
import PhotosUI

struct LabTechniciansListView: View {
    @EnvironmentObject private var dataStore: MockHospitalDataStore
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
                                NavigationLink(destination: LabTechnicianDetailView(staff: staff, dataStore: dataStore)) {
                                    LabTechnicianRow(staff: staff)
                                }
                                .tag(staff.id)
                            }
                            .onDelete(perform: deleteTechnician)
                        }
            .listStyle(InsetListStyle())
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
        
        labTechService.createLabTechnician(
            name: name,
            email: email,
            mobile: mobile,
            certification: certification,
            experienceYears: experienceYears,
            assignedLab: assignedLabName,
            joiningDate: Date()
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.dataStore.fetchStaff() // Refresh the list
                    self.presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    self.alertMessage = "Failed to create lab technician: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
}

struct LabTechnicianDetailView: View {
    let staff: LabStaff
    @ObservedObject var dataStore: MockHospitalDataStore
    @StateObject private var labTechService = LabTechnicianService.shared
    @State private var specificLabTech: SpecificLabTechResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingEditView = false
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if let tech = specificLabTech {
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
                        Text(tech.staff_name)
                    }
                    
                    HStack {
                        Text("Assigned Lab")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(tech.assigned_lab)
                    }
                    
                    HStack {
                        Text("Experience")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(tech.lab_experience_years) years")
                    }
                    
                    HStack {
                        Text("Certification")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(tech.certification)
                    }
                    
                    if let qualification = tech.staff_qualification, !qualification.isEmpty {
                        HStack {
                            Text("Qualification")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(qualification)
                        }
                    }
                    
                    if let dob = tech.staff_dob, !dob.isEmpty {
                        HStack {
                            Text("Date of Birth")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dob)
                        }
                    }
                    
                    if let address = tech.staff_address, !address.isEmpty {
                        HStack {
                            Text("Address")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(address)
                        }
                    }
                    
                    if let photo = tech.profile_photo, !photo.isEmpty {
                        HStack {
                            Text("Profile Photo")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(photo)
                        }
                    }
                    
                    HStack {
                        Text("On Leave")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(tech.on_leave ? "Yes" : "No")
                    }
                }
                
                Section(header: Text("Contact")) {
                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(tech.staff_email)
                    }
                    
                    HStack {
                        Text("Mobile")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(tech.staff_mobile)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(specificLabTech?.staff_name ?? staff.staffName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
                .disabled(specificLabTech == nil)
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditLabTechnicianView(
                labTech: specificLabTech!,
                dataStore: dataStore,
                onSave: { updatedTech in
                    specificLabTech = updatedTech
                    showingEditView = false
                }
            )
        }
        .onAppear {
            fetchSpecificLabTechnician()
        }
    }
    
    private func fetchSpecificLabTechnician() {
        isLoading = true
        errorMessage = nil
        
        labTechService.fetchSpecificLabTechnician(staffId: staff.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    specificLabTech = response
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct EditLabTechnicianView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataStore: MockHospitalDataStore
    @StateObject private var labTechService = LabTechnicianService.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    let labTech: SpecificLabTechResponse
    let onSave: (SpecificLabTechResponse) -> Void
    
    @State private var name: String
    @State private var email: String
    @State private var mobile: String
    @State private var certification: String
    @State private var experience: String
    @State private var assignedLab: String
    @State private var onLeave: Bool
    @State private var dob: String
    @State private var address: String
    @State private var qualification: String
    
    init(labTech: SpecificLabTechResponse, dataStore: MockHospitalDataStore, onSave: @escaping (SpecificLabTechResponse) -> Void) {
        self.labTech = labTech
        self.dataStore = dataStore
        self.onSave = onSave
        _name = State(initialValue: labTech.staff_name)
        _email = State(initialValue: labTech.staff_email)
        _mobile = State(initialValue: labTech.staff_mobile)
        _certification = State(initialValue: labTech.certification)
        _experience = State(initialValue: String(labTech.lab_experience_years))
        _assignedLab = State(initialValue: labTech.assigned_lab)
        _onLeave = State(initialValue: labTech.on_leave)
        _dob = State(initialValue: labTech.staff_dob ?? "")
        _address = State(initialValue: labTech.staff_address ?? "")
        _qualification = State(initialValue: labTech.staff_qualification ?? "")
    }
    
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
                    TextField("Date of Birth (YYYY-MM-DD)", text: $dob)
                    TextField("Address", text: $address)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Certification", text: $certification)
                    TextField("Experience (Years)", text: $experience)
                        .keyboardType(.numberPad)
                    TextField("Qualification", text: $qualification)
                    
                    Picker("Assigned Lab", selection: $assignedLab) {
                        ForEach(dataStore.labTypes, id: \.assigned_lab) { lab in
                            Text(lab.assigned_lab).tag(lab.assigned_lab)
                        }
                    }
                    
                    Toggle("On Leave", isOn: $onLeave)
                }
                
                Section(header: Text("Profile Photo")) {
                    Button(action: { showImagePicker = true }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Select Profile Photo")
                        }
                    }
                    
                    if selectedImage != nil {
                        Image(uiImage: selectedImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
                
                if !alertMessage.isEmpty {
                    Section {
                        Text(alertMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Lab Technician")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateLabTechnician()
                    }
                    .disabled(name.isEmpty || email.isEmpty || certification.isEmpty || assignedLab.isEmpty)
                }
            }
        }
    }
    
    private func updateLabTechnician() {
        guard let experienceYears = Int(experience) else {
            alertMessage = "Please enter valid experience years"
            showingAlert = true
            return
        }
        
        guard !name.isEmpty else {
            alertMessage = "Name is required"
            showingAlert = true
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
        
        guard !certification.isEmpty else {
            alertMessage = "Certification is required"
            showingAlert = true
            return
        }
        
        guard !assignedLab.isEmpty else {
            alertMessage = "Please select an assigned lab"
            showingAlert = true
            return
        }
        
        let request = UpdateLabTechRequest(
            staff_name: name,
            staff_email: email,
            staff_mobile: mobile,
            certification: certification,
            lab_experience_years: experienceYears,
            assigned_lab: assignedLab,
            on_leave: onLeave,
            staff_dob: dob.isEmpty ? nil : dob,
            staff_address: address.isEmpty ? nil : address,
            staff_qualification: qualification.isEmpty ? nil : qualification,
            profile_photo: selectedImage?.jpegData(compressionQuality: 0.8)
        )
        
        labTechService.updateLabTechnician(
            staffId: labTech.staff_id,
            request: request
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("Update response: \(response.message)")
                    let updatedTech = SpecificLabTechResponse(
                        staff_id: labTech.staff_id,
                        staff_name: name,
                        staff_email: email,
                        staff_mobile: mobile,
                        created_at: labTech.created_at,
                        certification: certification,
                        lab_experience_years: experienceYears,
                        assigned_lab: assignedLab,
                        on_leave: onLeave,
                        staff_dob: dob.isEmpty ? nil : dob,
                        staff_address: address.isEmpty ? nil : address,
                        staff_qualification: qualification.isEmpty ? nil : qualification,
                        profile_photo: selectedImage != nil ? "updated_photo.jpg" : nil
                    )
                    
                    onSave(updatedTech)
                    presentationMode.wrappedValue.dismiss()
                    
                case .failure(let error):
                    alertMessage = "Failed to update lab technician: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
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

extension UpdateLabTechRequest {
    var toDictionary: [String: Any] {
        var dict: [String: Any] = [
            "staff_name": staff_name,
            "staff_email": staff_email,
            "staff_mobile": staff_mobile,
            "certification": certification,
            "lab_experience_years": lab_experience_years,
            "assigned_lab": assigned_lab,
            "on_leave": on_leave
        ]
        // Only include optional fields if they have non-empty values
        if ((staff_dob?.isEmpty) == nil) {
            dict["staff_dob"] = staff_dob
        }
        if ((staff_address?.isEmpty) == nil) {
            dict["staff_address"] = staff_address
        }
        if ((staff_qualification?.isEmpty) == nil) {
            dict["staff_qualification"] = staff_qualification
        }
        if let photo = profile_photo, !photo.isEmpty {
            dict["profile_photo"] = photo
        }
        return dict
    }
}
