//
//  doctorCRUD.swift
//  Hospitality
//
//  Created by admin@33 on 23/04/25.
//

import Foundation
import SwiftUI

struct DoctorsListView: View {
    @ObservedObject private var dataStore = MockHospitalDataStore()
    @State private var showingAddDoctor = false
    @State private var searchText = ""
    @State private var selectedDepartment = "All"
    @State private var selectedShift = "All"
    @State private var editMode: EditMode = .inactive
    @State private var selectedDoctors = Set<String>()
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var departments: [String] {
        var depts = ["All"]
        let allDepts = Set(dataStore.doctors.map { $0.doctorSpecialization })
        depts.append(contentsOf: allDepts.sorted())
        return depts
    }
    
    private var shifts: [String] {
        ["All", "Morning", "Afternoon", "Evening", "Night"]
    }
    
    private var filteredDoctors: [Staff] {
        var result = dataStore.staff.filter { staff in
            dataStore.doctors.contains { $0.staffId == staff.id }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.staffName.localizedCaseInsensitiveContains(searchText) ||
                $0.staffEmail.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedDepartment != "All" {
            result = result.filter { staff in
                dataStore.doctors.contains {
                    $0.staffId == staff.id && $0.doctorSpecialization == selectedDepartment
                }
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack {
            // Search and Filter Bar
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .background(Color(.systemGroupedBackground))
                
                ScrollView(.horizontal, showsIndicators: false) {
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
                                title: "Department",
                                selection: $selectedDepartment,
                                options: departments,
                                accentColor: .main
                            )
                            
                            FilterPill(
                                title: "Shift",
                                selection: $selectedShift,
                                options: shifts,
                                accentColor: .main
                            )
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            
            // Doctors List
            List(selection: $selectedDoctors) {
                ForEach(filteredDoctors) { staff in
                    NavigationLink(destination: DoctorDetailView(staff: staff, dataStore: dataStore)) {
                        DoctorRow(staff: staff, dataStore: dataStore)
                    }
                    .tag(staff.id)
                }
                .onDelete(perform: deleteDoctor)
            }
            .listStyle(InsetListStyle())
        }
        .navigationTitle("Doctors")
        .onAppear {
            fetchDoctors()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if editMode == .active {
                    Button(action: {
                        if !selectedDoctors.isEmpty {
                            showingDeleteConfirmation = true
                        }
                    }) {
                        Image(systemName: "trash")
                            .tint(.red)
                    }
                    .disabled(selectedDoctors.isEmpty)
                }
                
                Button(action: { showingAddDoctor = true }) {
                    Image(systemName: "plus")
                        .tint(.main)
                }
                
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingAddDoctor) {
            AddEditDoctorView(dataStore: dataStore) { staff, doctorDetails, staffDetails in
                dataStore.createDoctor(staff: staff, doctorDetails: doctorDetails, staffDetails: staffDetails)
                showingAddDoctor = false
            }
        }
        .actionSheet(isPresented: $showingDeleteConfirmation) {
            ActionSheet(
                title: Text("Confirm Deletion"),
                message: Text("Are you sure you want to delete this doctor?"),
                buttons: [
                    .destructive(Text("Delete"), action: deleteSelectedDoctor),
                    .cancel()
                ]
            )
        }
        .onAppear {
            dataStore.fetchStaff()
            dataStore.fetchDoctors()
            dataStore.fetchDoctorTypes()
        }
    }
    
    private func fetchDoctors() {
        isLoading = true
        errorMessage = nil
        
        DoctorService.shared.fetchDoctors { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let doctors):
                    // Convert API response to your local data models
                    let staffList = doctors.map { doctor in
                        Staff(
                            id: doctor.staff_id,
                            staffName: doctor.staff_name,
                            roleId: "doctor_role_id",
                            createdAt: Date(), // You might need to get this from the API
                            staffEmail: doctor.staff_email,
                            staffMobile: doctor.staff_mobile,
                            onLeave: doctor.on_leave
                        )
                    }
                    
                    let doctorDetailsList = doctors.map { doctor in
                        DoctorDetails(
                            id: UUID().uuidString,
                            staffId: doctor.staff_id,
                            doctorSpecialization: doctor.specialization,
                            doctorLicense: doctor.license,
                            doctorExperienceYears: doctor.experience_years,
                            doctorTypeId: nil // You might need to get this from the API
                        )
                    }
                    
                    // Update your data store
                    dataStore.staff = staffList
                    dataStore.doctors = doctorDetailsList
                    
                case .failure(let error):
                    errorMessage = "Failed to load doctors: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteDoctor(at offsets: IndexSet) {
        let idToDelete = offsets.map { filteredDoctors[$0].id }.first!
        showingDeleteConfirmation = true
        selectedDoctors = [idToDelete]
    }

    private func deleteSelectedDoctor() {
        guard let doctorId = selectedDoctors.first else { return }
        
        isLoading = true
        
        DoctorService.shared.deleteDoctor(doctorId: doctorId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    // Remove from local data store
                    self.dataStore.deleteStaff(ids: [doctorId])
                    // Refresh the list
                    self.fetchDoctors()
                case .failure(let error):
                    self.errorMessage = "Failed to delete doctor: \(error.localizedDescription)"
                }
                
                self.selectedDoctors.removeAll()
            }
        }
    }
}

struct DoctorRow: View {
    let staff: Staff
    @ObservedObject var dataStore: MockHospitalDataStore
    
    var doctorDetails: DoctorDetails? {
        dataStore.doctors.first { $0.staffId == staff.id }
    }
    
    var doctorType: DoctorType? {
        guard let doctor = doctorDetails else { return nil }
        return dataStore.doctorTypes.first { $0.id == doctor.doctorTypeId }
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
                
                if let specialization = doctorDetails?.doctorSpecialization {
                    Text(specialization)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let type = doctorType {
                    Text(type.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if staff.onLeave {
                Text("On Leave")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

struct AddEditDoctorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataStore: MockHospitalDataStore
    
    var onSave: (Staff, DoctorDetails, StaffDetails) -> Void
    
    // Staff fields
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var mobile: String = ""
    @State private var onLeave: Bool = false
    @State private var joiningDate: Date = Date()
    
    // Doctor fields
    @State private var specialization: String = ""
    @State private var license: String = ""
    @State private var experience: String = ""
    @State private var doctorTypeId: Int = 0
    
    // StaffDetails fields
    @State private var dob: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var address: String = ""
    @State private var qualifications: String = ""

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
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                }
                
                Section(header: Text("Address")) {
                    TextField("Address", text: $address)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Specialization", text: $specialization)
                    TextField("Qualifications", text: $qualifications)
                    TextField("License Number", text: $license)
                    TextField("Experience (Years)", text: $experience)
                        .keyboardType(.numberPad)
                    
                    Picker("Doctor Type", selection: $doctorTypeId) {
                        ForEach(dataStore.doctorTypes, id: \.id) { type in
                            Text(type.name).tag(type.id)
                        }
                    }
                    
                    DatePicker("Joining Date", selection: $joiningDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Doctor")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDoctor()
                    }
                    .disabled(name.isEmpty || email.isEmpty || mobile.isEmpty ||
                             specialization.isEmpty || qualifications.isEmpty ||
                             license.isEmpty || experience.isEmpty ||
                              doctorTypeId == 0 || address.isEmpty)
                }
            }
        }
    }
    
    private func saveDoctor() {
        // Validate inputs
        guard !name.isEmpty,
              !email.isEmpty,
              !mobile.isEmpty,
              !specialization.isEmpty,
              !license.isEmpty,
              !experience.isEmpty,
              doctorTypeId != 0,
              !qualifications.isEmpty,
              !address.isEmpty else {
            // Show error to user
            return
        }
        
        guard let experienceYears = Int(experience) else {
            return
        }
        
        // Format dates
//        let joiningDateString = CreateDoctorRequest.formattedDate(from: joiningDate)
        let dobString = CreateDoctorRequest.formattedDate(from: dob)
        
        // Call the service
        DoctorService.shared.createDoctor(
            name: name,
            email: email,
            mobile: mobile,
            specialization: specialization,
            license: license,
            experienceYears: experienceYears,
            doctorTypeId: doctorTypeId,
            joiningDate: joiningDate,
            dob: dobString,
            address: address,
            qualifications: qualifications
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.dataStore.fetchDoctors() // Refresh the list
                    self.presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Failed to create doctor: \(error)")
                }
            }
        }
    }
}

struct DoctorDetailView: View {
    let staff: Staff
    @ObservedObject var dataStore: MockHospitalDataStore
    
    @State private var doctorDetails: SpecificDoctorResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingEditDoctor = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let doctor = doctorDetails {
                doctorDetailContent(doctor: doctor)
            } else {
                Text("No doctor details available")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(staff.staffName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditDoctor = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditDoctor) {
            EditDoctorView(
                staff: staff,
                dataStore: dataStore,
                doctorDetails: doctorDetails,
                onSave: { updatedStaff, updatedDoctorDetails in
                    // Handle the updated doctor information
                    self.doctorDetails = updatedDoctorDetails
                    // Refresh the details
                    self.fetchDoctorDetails()
                }
            )
        }
        .onAppear {
            fetchDoctorDetails()
        }
    }
    
    private func fetchDoctorDetails() {
        isLoading = true
        errorMessage = nil
        
        DoctorService.shared.fetchSpecificDoctor(doctorId: staff.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    self.doctorDetails = response
                case .failure(let error):
                    errorMessage = "Failed to load doctor details: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func doctorDetailContent(doctor: SpecificDoctorResponse) -> some View {
        List {
            Section {
                HStack {
                    Spacer()
                    if let photoUrl = doctor.profile_photo, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.main)
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.main)
                    }
                    Spacer()
                }
                
                HStack {
                    Text("Name")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.staff_name)
                }
                
                HStack {
                    Text("Specialization")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.specialization)
                }
                
                HStack {
                    Text("Experience")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(doctor.experience_years) years")
                }
                
                HStack {
                    Text("Type")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.doctor_type.name)
                }
                
                HStack {
                    Text("License")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.license)
                }
                
                HStack {
                    Text("Qualification")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.staff_qualification)
                }
            }
            
            Section(header: Text("Contact")) {
                HStack {
                    Text("Email")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.staff_email)
                }
                
                HStack {
                    Text("Mobile")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.staff_mobile)
                }
                
                if let address = doctor.staff_address {
                    HStack {
                        Text("Address")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(address)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            
            Section(header: Text("Personal Information")) {
                HStack {
                    Text("Date of Birth")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.staff_dob)
                }
                
                HStack {
                    Text("Joining Date")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(doctor.created_at)
                }
            }
            
            if doctor.on_leave {
                Section {
                    Text("Currently on leave")
                        .foregroundColor(.orange)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct EditDoctorView: View {
    @Environment(\.presentationMode) var presentationMode
    let staff: Staff
    @ObservedObject var dataStore: MockHospitalDataStore
    let doctorDetails: SpecificDoctorResponse?
    let onSave: (Staff, SpecificDoctorResponse) -> Void
    
    @State private var name: String
    @State private var email: String
    @State private var mobile: String
    @State private var specialization: String
    @State private var license: String
    @State private var experience: String
    @State private var doctorTypeId: Int
    @State private var onLeave: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var dob: String
    @State private var address: String
    @State private var qualifications: String
    @State private var profilePhoto: String
    @State private var showingPhotoPicker = false
    
    init(staff: Staff, dataStore: MockHospitalDataStore, doctorDetails: SpecificDoctorResponse?, onSave: @escaping (Staff, SpecificDoctorResponse) -> Void) {
        self.staff = staff
        self.dataStore = dataStore
        self.doctorDetails = doctorDetails
        self.onSave = onSave
        
        _name = State(initialValue: staff.staffName)
        _email = State(initialValue: staff.staffEmail)
        _mobile = State(initialValue: staff.staffMobile)
        _onLeave = State(initialValue: staff.onLeave)
        
        if let details = doctorDetails {
            _specialization = State(initialValue: details.specialization)
            _license = State(initialValue: details.license)
            _experience = State(initialValue: String(details.experience_years))
            _doctorTypeId = State(initialValue: details.doctor_type.id)
            _dob = State(initialValue: details.staff_dob)
            _address = State(initialValue: details.staff_address ?? "")
            _qualifications = State(initialValue: details.staff_qualification)
            _profilePhoto = State(initialValue: details.profile_photo ?? "file_upload")
        } else {
            _specialization = State(initialValue: "")
            _license = State(initialValue: "")
            _experience = State(initialValue: "")
            _doctorTypeId = State(initialValue: 0)
            _dob = State(initialValue: "")
            _address = State(initialValue: "")
            _qualifications = State(initialValue: "")
            _profilePhoto = State(initialValue: "file_upload")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Photo")) {
                    HStack {
                        if profilePhoto != "file_upload", let url = URL(string: profilePhoto) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } placeholder: {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.main)
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.main)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingPhotoPicker = true
                        }) {
                            Text("Change Photo")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Mobile", text: $mobile)
                        .keyboardType(.phonePad)
                    Toggle("On Leave", isOn: $onLeave)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Specialization", text: $specialization)
                    TextField("License Number", text: $license)
                    TextField("Experience (Years)", text: $experience)
                        .keyboardType(.numberPad)
                    Picker("Doctor Type", selection: $doctorTypeId) {
                        ForEach(dataStore.doctorTypes, id: \.id) { type in
                            Text(type.name).tag(type.id)
                        }
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    Text("Date of Birth: \(dob)")
                        .foregroundColor(.secondary)
                    TextField("Address", text: $address)
                    TextField("Qualifications", text: $qualifications)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Doctor")
            .disabled(isLoading)
            .overlay(
                isLoading ? ProgressView().progressViewStyle(CircularProgressViewStyle()) : nil
            )
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedPhotoUrl: $profilePhoto)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || email.isEmpty || mobile.isEmpty || specialization.isEmpty || license.isEmpty || experience.isEmpty || doctorTypeId == 0 || qualifications.isEmpty || profilePhoto.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let experienceYears = Int(experience) else {
            errorMessage = "Please enter a valid number for experience"
            print("Invalid experience: \(experience)")
            return
        }
        
        guard doctorTypeId != 0 else {
            errorMessage = "Please select a valid doctor type"
            print("Invalid doctorTypeId: \(doctorTypeId)")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            print("Invalid email: \(email)")
            return
        }
        
        guard !profilePhoto.isEmpty else {
            errorMessage = "Profile photo is required"
            print("Missing profile photo")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let request = EditDoctorRequest(
            staff_name: name,
            staff_email: email,
            staff_mobile: mobile,
            on_leave: onLeave,
            specialization: specialization,
            license: license,
            experience_years: experienceYears,
            doctor_type_id: doctorTypeId,
            staff_dob: dob,
            staff_address: address.isEmpty ? nil : address,
            staff_qualification: qualifications,
            profile_photo: profilePhoto
        )
        
        print("EditDoctorRequest: \(request)")
        
        DoctorService.shared.updateDoctor(staffId: staff.id, request: request) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    print("Update successful: \(response.message)")
                    
                    let updatedStaff = Staff(
                        id: staff.id,
                        staffName: name,
                        roleId: staff.roleId,
                        createdAt: staff.createdAt,
                        staffEmail: email,
                        staffMobile: mobile,
                        onLeave: onLeave
                    )
                    
                    let updatedDetails = SpecificDoctorResponse(
                        staff_id: staff.id,
                        staff_name: name,
                        staff_email: email,
                        staff_mobile: mobile,
                        created_at: doctorDetails?.created_at ?? "",
                        specialization: specialization,
                        license: license,
                        experience_years: experienceYears,
                        doctor_type: DoctorType(
                            id: doctorTypeId,
                            name: dataStore.doctorTypes.first { $0.id == doctorTypeId }?.name ?? "Unknown"
                        ),
                        on_leave: onLeave,
                        staff_dob: dob,
                        staff_address: address,
                        staff_qualification: qualifications,
                        profile_photo: profilePhoto
                    )
                    
                    dataStore.updateStaff(staff: updatedStaff)
                    dataStore.updateDoctorDetails(details: DoctorDetails(
                        id: UUID().uuidString,
                        staffId: staff.id,
                        doctorSpecialization: specialization,
                        doctorLicense: license,
                        doctorExperienceYears: experienceYears,
                        doctorTypeId: doctorTypeId
                    ))
                    
                    onSave(updatedStaff, updatedDetails)
                    presentationMode.wrappedValue.dismiss()
                    
                case .failure(let error):
                    errorMessage = "Failed to update doctor: \(error.localizedDescription)"
                    print("Update failed: \(error)")
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search...", text: $text)
                    .foregroundColor(.primary)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct PhotoPickerView: View {
    @Binding var selectedPhotoUrl: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Profile Photo")) {
                    Button(action: {
                        // Simulate photo selection by setting a placeholder URL
                        // In a real app, this would open a photo picker and upload to a server
                        selectedPhotoUrl = "https://example.com/doctor_profile_\(UUID().uuidString).jpg"
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Choose Photo")
                        }
                    }
                    
                    Button(action: {
                        // Reset to default
                        selectedPhotoUrl = "file_upload"
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove Photo")
                        }
                    }
                }
            }
            .navigationTitle("Select Photo")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
