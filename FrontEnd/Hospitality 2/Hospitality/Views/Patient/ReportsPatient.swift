import SwiftUI
import Combine

// MARK: - Models
struct LabRecord: Identifiable, Codable {
    let id: Int
    let lab: Int
    let labName: String
    let scheduledTime: Date
    let testResult: [String: TestResultValue]?
    let testType: Int
    let testTypeName: String
    let priority: String
    let appointment: Int
    let status : String

    enum CodingKeys: String, CodingKey {
        case id = "lab_test_id"
        case lab
        case labName = "lab_name"
        case scheduledTime = "test_datetime"
        case testResult = "test_result"
        case testType = "test_type"
        case testTypeName = "test_type_name"
        case priority
        case appointment
        case status
    }
}

enum TestResultValue: Codable {
    case number(Double)
    case text(String)
    case object([String: TestResultValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .text(string)
        } else if let object = try? container.decode([String: TestResultValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(
                TestResultValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown type in TestResultValue")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let num):
            try container.encode(num)
        case .text(let str):
            try container.encode(str)
        case .object(let dict):
            try container.encode(dict)
        }
    }
}

// MARK: - Service
class LabRecordService {
    static let shared = LabRecordService()
    private let baseURL = Constants.baseURL
    
    func fetchUpcomingLabRecords(completion: @escaping (Result<[LabRecord], DoctorCreationError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/hospital/general/patient/recommended-lab-tests/") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.serverError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.unknownError))
                return
            }
            
            if httpResponse.statusCode == 401 {
                completion(.failure(.unauthorized))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode), let data = data else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(.serverError(errorMessage)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode([LabRecord].self, from: data)
                print(response)
                completion(.success(response))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(.decodingError))
            }
        }.resume()
    }
}

// MARK: - View Model
class LabRecordsViewModel: ObservableObject {
    @State private var selectedFilter: String = "Recommended"
    @Published var records: [LabRecord] = []
    @Published var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    func fetchLabRecords() {
        isLoading = true
        LabRecordService.shared.fetchUpcomingLabRecords { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let records):
                    self?.records = records
                case .failure(let error):
                    print("Failed to fetch lab records: \(error)")
                    self?.records = []
                }
            }
        }
    }
}

// MARK: - View
struct ReportsContent: View {
    @State private var selectedFilter: String = "Recommended"
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = LabRecordsViewModel()
    @State private var opacity: Double = 0.0
    @State private var searchText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var isDateFilterActive: Bool = false
    @State private var selectedRecord: LabRecord?
    @State private var cardOffset: CGFloat = 100
    @State private var navBarOpacity: Double = 0.0
    
    private var filteredRecords: [LabRecord] {
           viewModel.records.filter { record in
               let matchesSegment: Bool
               switch selectedFilter {
               case "Recommended":
                   matchesSegment = record.status.lowercased() == "recommended"
               case "Completed":
                   matchesSegment = record.status.lowercased() == "completed"
               case "Paid":
                   matchesSegment = record.status.lowercased() == "paid"
               default:
                   matchesSegment = true
               }
               
               let matchesSearch = searchText.isEmpty || record.testTypeName.lowercased().contains(searchText.lowercased())
               let matchesDate = !isDateFilterActive || Calendar.current.isDate(record.scheduledTime, inSameDayAs: selectedDate)
               
               return matchesSegment && matchesSearch && matchesDate
           }
       }


    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? Color(hex: "0A0E1A") : Color(hex: "E6F0FA"),
                        colorScheme == .dark ? Color(hex: "1A2238") : Color(hex: "F8FBFF")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle decorative elements
                GeometryReader { geometry in
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(colorScheme == .dark ? Color.blue.opacity(0.1) : Color(hex: "4A90E2").opacity(0.05))
                            .frame(width: CGFloat.random(in: 100...250))
                            .blur(radius: 20)
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                    }
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Lab Reports")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E3A8A"))
                            
                            Text("Track your medical tests and results")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "64748B"))
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.gray)
                            TextField("Search tests...", text: $searchText)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .font(.system(size: 16, design: .rounded))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "1E293B") : .white)
                                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 8)
                        )
                        .padding(.horizontal)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: searchText)
                        
                        // Filters
                        HStack(spacing: 12) {
                            Picker("Report Type", selection: $selectedFilter) {
                                Text("Recommended").tag("Recommended")
                                Text("Completed").tag("Completed")
                                Text("Paid").tag("Paid")
                            }
                            .pickerStyle(.segmented)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(hex: "1E293B") : .white)
                            )
                            
                            // Date Filter Toggle
                            Button(action: {
                                triggerHaptic()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isDateFilterActive.toggle()
                                }
                            }) {
                                Image(systemName: isDateFilterActive ? "calendar.circle.fill" : "calendar.circle")
                                    .font(.system(size: 24))
                                    .foregroundStyle(colorScheme == .dark ? Color(hex: "60A5FA") : Color(hex: "2563EB"))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color(hex: "DBEAFE"))
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Date Picker
                        if isDateFilterActive {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .accentColor(colorScheme == .dark ? Color(hex: "60A5FA") : Color(hex: "2563EB"))
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(hex: "1E293B") : .white)
                                    .shadow(color: .black.opacity(0.1), radius: 4)
                            )
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Records List
                        LazyVStack(spacing: 16) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(colorScheme == .dark ? .white : Color(hex: "2563EB"))
                                    .padding(.vertical, 32)
                                    .frame(maxWidth: .infinity)
                            } else if filteredRecords.isEmpty {
                                Text("No \(selectedFilter.lowercased()) lab records found")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "64748B"))
                                    .padding(.vertical, 32)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(filteredRecords) { record in
                                    LabRecordCard(record: record, onTap: { selectedRecord = record })
                                        .padding(.horizontal)
                                        .offset(y: cardOffset)
                                        .animation(
                                            .spring(response: 0.6, dampingFraction: 0.8)
                                            .delay(Double(filteredRecords.firstIndex(where: { $0.id == record.id }) ?? 0) * 0.05),
                                            value: cardOffset
                                        )
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom, 32)
                }
                .opacity(opacity)
                .onAppear {
                    viewModel.fetchLabRecords()
                    withAnimation(.easeInOut(duration: 0.8)) {
                        opacity = 1.0
                        cardOffset = 0
                    }
                    withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                        navBarOpacity = 1.0
                    }
                }
                .refreshable {
                    viewModel.fetchLabRecords()
                }
                
                // Detail Overlay
                if let record = selectedRecord {
                    LabRecordDetailOverlay(record: record, isPresented: Binding(
                        get: { selectedRecord != nil },
                        set: { if !$0 { selectedRecord = nil } }
                    ))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reports")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E3A8A"))
                        .opacity(navBarOpacity)
                }
            }
        }
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Detail Overlay
struct LabRecordDetailOverlay: View {
    let record: LabRecord
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 24) {
                // Header with close button
                HStack {
                    Text("Lab Report Details")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E3A8A"))
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color(hex: "64748B"))
                    }
                }
                .padding(.horizontal)
                
                // Details ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Test Type", value: record.testTypeName)
                        DetailRow(label: "Priority", value: record.priority.capitalized)
                        DetailRow(
                            label: "Scheduled Time",
                            value: record.scheduledTime,
                            format: .dateTime.day().month().year().hour().minute()
                        )
                        
                        // Test Results
                        if let resultMap = record.testResult, !resultMap.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Test Results")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "475569"))
                                
                                ForEach(resultMap.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack {
                                        Text(key.capitalized + ":")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                                        
                                        Spacer()
                                        
                                        switch value {
                                        case .number(let num):
                                            Text(String(format: "%.2f", num))
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundStyle(Color(hex: "2563EB"))
                                        case .text(let str):
                                            Text(str)
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundStyle(Color(hex: "64748B"))
                                        case .object:
                                            Text("Complex Data")
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundStyle(.red)
                                        }
                                    }
                                }
                            }
                        } else {
                            DetailRow(label: "Test Results", value: "Not Available")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Buttons
                HStack(spacing: 16) {
                    // Download PDF Button
                    Button(action: {
                        generateAndSharePDF()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Download PDF")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "2563EB"), Color(hex: "60A5FA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    
                    // Close Button
//                    Button(action: {
//                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//                            isPresented = false
//                        }
//                    }) {
//                        Text("Close")
//                            .font(.system(size: 16, weight: .semibold, design: .rounded))
//                            .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E293B"))
//                            .padding(.vertical, 14)
//                            .frame(maxWidth: .infinity)
//                            .background(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .fill(colorScheme == .dark ? Color(hex: "334155") : Color(hex: "E2E8F0"))
//                            )
//                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(hex: "1E293B") : .white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.15), radius: 12)
            )
            .padding(.horizontal, 16)
        }
    }
    
    @StateObject var viewModel11 = DoctorViewModel()
    
    private func generateAndSharePDF() {
        // Break down the PDF generation into distinct steps
        //let pdfData = PDFGenerator.createLabRecordPDF(from: record, using: viewModel11)
        
        PDFGenerator.createLabRecordPDF(from: record, using: viewModel11) { pdfData in
            if let data = pdfData {
                // Use the PDF data (save to file, share, etc.)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LabTest-\(record.id).pdf")
                
                do {
                    try pdfData!.write(to: tempURL)
                    sharePDF(at: tempURL)
                } catch {
                    print("Failed to write PDF: \(error.localizedDescription)")
                }
                
            } else {
                print("Failed to generate PDF.")
            }
        }
    }
    
    private func sharePDF(at url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // Detail Row Component
    struct DetailRow<Value>: View {
        let label: String
        let value: Value
        let format: Date.FormatStyle?
        
        init(label: String, value: Value, format: Date.FormatStyle? = nil) {
            self.label = label
            self.value = value
            self.format = format
        }
        
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            HStack(alignment: .top) {
                Text(label + ":")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "475569"))
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                if let dateValue = value as? Date, let format = format {
                    Text(dateValue, format: format)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                } else {
                    Text(String(describing: value))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                }
            }
        }
    }
}

// MARK: - Lab RecordmediumCard
struct LabRecordCard: View {
    let record: LabRecord
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.95
    
    var body: some View {
        Button(action: {
            triggerHaptic()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 0.92
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 0.95
                }
                onTap()
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "2563EB"), Color(hex: "60A5FA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 24))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and Status
                    HStack {
                        Text(record.testTypeName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                        Text(record.status.capitalized)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(record.scheduledTime >= Date()
                                        ? Color(hex: "2563EB").opacity(0.15)
                                        : Color(hex: "22C55E").opacity(0.15)
                                    )
                            )
                            .foregroundStyle(record.scheduledTime >= Date()
                                ? Color(hex: "2563EB")
                                : Color(hex: "22C55E")
                            )
                    }
                    
                    // Details
                    HStack {
                        Spacer()
                        
                        Text(record.scheduledTime, format: .dateTime.day().month().hour().minute())
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "64748B"))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(hex: "1E293B") : .white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 8)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scale)
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Previews
struct ReportsContent_Previews: PreviewProvider {
    static var previews: some View {
        ReportsContent()
            .preferredColorScheme(.light)
        ReportsContent()
            .preferredColorScheme(.dark)
    }
}
