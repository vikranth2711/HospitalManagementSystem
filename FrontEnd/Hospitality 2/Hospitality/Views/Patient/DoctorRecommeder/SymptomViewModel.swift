// struct AppointmentHistoryCard: View {
//     let appointment: PatientAppointHistoryListResponse
//     @Environment(\.colorScheme) var colorScheme
//     @State private var slotStartTime: String = "Loading..."
//     @State private var isSlotLoading: Bool = false
//     @State private var staffName: String = "Loading..."
//     @State private var isStaffNameLoading: Bool = false
    
//     var body: some View {
//         VStack(alignment: .leading, spacing: 12) {
//             HStack {
//                 VStack(alignment: .leading, spacing: 4) {
//                     Text(staffName)
//                         .font(.system(size: 18, weight: .semibold, design: .rounded))
                    
//                     Text("\(formatDate(appointment.date)) • \(slotStartTime)")
//                         .font(.system(size: 14, weight: .medium, design: .rounded))
//                         .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
//                 }
                
//                 Spacer()
                
//                 StatusBadge(status: appointment.status)
//             }
            
//             Divider()
            
//             HStack {
//                 VStack(alignment: .leading, spacing: 4) {
//                     Text("Doctor")
//                         .font(.caption)
//                         .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .gray.opacity(0.7))
                    
//                     Text(staffName)
//                         .font(.system(size: 14, weight: .medium, design: .rounded))
//                         .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black)
//                 }
                
//                 Spacer()
                
//                 VStack(alignment: .trailing, spacing: 4) {
//                     Text("Time")
//                         .font(.caption)
//                         .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .gray.opacity(0.7))
                    
//                     Text(slotStartTime)
//                         .font(.system(size: 14, weight: .medium, design: .rounded))
//                         .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black)
//                 }
//             }
            
//             if let reason = appointment.reason, !reason.isEmpty {
//                 Text("Reason: \(reason)")
//                     .font(.system(size: 14, weight: .regular, design: .rounded))
//                     .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
//                     .padding(.top, 4)
//             } else {
//                 Text("No reason provided")
//                     .font(.system(size: 14, weight: .regular, design: .rounded))
//                     .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .gray.opacity(0.7))
//                     .italic()
//                     .padding(.top, 4)
//             }
//         }
//         .padding()
//         .background(
//             RoundedRectangle(cornerRadius: 12)
//                 .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
//                 .shadow(
//                     color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.2),
//                     radius: 5, x: 0, y: 2
//                 )
//         )
//         .overlay(
//             RoundedRectangle(cornerRadius: 12)
//                 .stroke(Color.blue, lineWidth: 1)
//         )
//         .onAppear {
//             loadSlotTime()
//             loadStaffName()
//         }
//     }
    
//     private func formatDate(_ dateString: String) -> String {
//         let dateFormatter = DateFormatter()
//         dateFormatter.dateFormat = "yyyy-MM-dd"
        
//         guard let date = dateFormatter.date(from: dateString) else {
//             return dateString
//         }
        
//         dateFormatter.dateStyle = .medium
//         return dateFormatter.string(from: date)
//     }
    
//     private func loadSlotTime() {
//         guard !isSlotLoading else { return }
        
//         isSlotLoading = true
        
//         Task {
//             do {
//                 let dateFormatter = DateFormatter()
//                 dateFormatter.dateFormat = "yyyy-MM-dd"
//                 guard let appointmentDate = dateFormatter.date(from: String(appointment.date.prefix(10))) else {
//                     throw NetworkError.unknownError
//                 }
                
//                 let dateString = dateFormatter.string(from: appointmentDate)
//                 let slots = try await DoctorServices().fetchDoctorSlots(doctorId: appointment.staff_id ?? "", date: dateString)
                
//                 if let slot = slots.first(where: { $0.slot_id == appointment.slot_id }) {
//                     let timeFormatter = DateFormatter()
//                     timeFormatter.dateFormat = "HH:mm:ss"
//                     if let timeDate = timeFormatter.date(from: slot.slot_start_time) {
//                         timeFormatter.dateFormat = "HH:mm"
//                         DispatchQueue.main.async {
//                             slotStartTime = timeFormatter.string(from: timeDate)
//                             isSlotLoading = false
//                         }
//                     } else {
//                         DispatchQueue.main.async {
//                             slotStartTime = "N/A"
//                             isSlotLoading = false
//                         }
//                     }
//                 } else {
//                     DispatchQueue.main.async {
//                         slotStartTime = "N/A"
//                         isSlotLoading = false
//                     }
//                 }
//             } catch {
//                 DispatchQueue.main.async {
//                     slotStartTime = "N/A"
//                     isSlotLoading = false
//                 }
//             }
//         }
//     }
    
//     private func loadStaffName() {
//         guard !isStaffNameLoading else { return }
        
//         isStaffNameLoading = true
        
//         Task {
//             do {
//                 guard let url = URL(string: "\(Constants.baseURL)/hospital/general/doctors/\(appointment.staff_id ?? "")/") else {
//                     throw NetworkError.invalidURL
//                 }
                
//                 var request = URLRequest(url: url)
//                 request.httpMethod = "GET"
//                 request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//                 request.addValue("Bearer \(UserDefaults.accessToken)", forHTTPHeaderField: "Authorization")
                
//                 let (data, response) = try await URLSession.shared.data(for: request)
                
//                 guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
//                     throw NetworkError.invalidResponse
//                 }
                
//                 let doctor = try JSONDecoder().decode(PatientSpecificDoctorResponse.self, from: data)
                
//                 DispatchQueue.main.async {
//                     staffName = doctor.staff_name
//                     isStaffNameLoading = false
//                 }
//             } catch {
//                 DispatchQueue.main.async {
//                     staffName = "Unknown Doctor"
//                     isStaffNameLoading = false
//                 }
//             }
//         }
//     }
// }