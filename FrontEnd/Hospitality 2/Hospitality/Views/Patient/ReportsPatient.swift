import SwiftUI
import Combine

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
    }
}

enum TestResultValue: Codable {
    case number(Double)
    case text(String)
    case object([String: TestResultValue])  // Optional: For future complex types

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
        guard let url = URL(string: "\(baseURL)/hospital/general/patient/recommended-lab-tests/") ??
                URL(string: "http://ec2-13-127-223-203.ap-south-1.compute.amazonaws.com/api/hospital/general/patient/recommended-lab-tests/")
        else {
            completion(.failure(.invalidURL))
            return
        }
        
        print(url)
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
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = LabRecordsViewModel()
    @State private var opacity: Double = 0.0
    @State private var searchText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedFilter: String = "Upcoming" // Default to Upcoming
    @State private var iconScale: CGFloat = 0.8
    @State private var isDateFilterActive: Bool = false
    @State private var selectedRecord: LabRecord? // For overlay
    
    private var filteredRecords: [LabRecord] {
        viewModel.records.filter { record in
            let isUpcoming = record.scheduledTime >= Date()
            let matchesSegment = selectedFilter == "Upcoming" ? isUpcoming : !isUpcoming
            let matchesSearch = searchText.isEmpty || record.labName.lowercased().contains(searchText.lowercased())
            let matchesDate = !isDateFilterActive || Calendar.current.isDate(record.scheduledTime, inSameDayAs: selectedDate)
            return matchesSegment && matchesSearch && matchesDate
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "101420") : Color(hex: "E8F5FF"),
                    colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Background circles
            ForEach(0..<8) { _ in
                Circle()
                    .fill(colorScheme == .dark ? Color.blue.opacity(0.05) : Color.blue.opacity(0.03))
                    .frame(width: CGFloat.random(in: 50...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: 3)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Lab Records")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))
                            
                            Text("View your scheduled and completed lab tests")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "4A5568"))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            triggerHaptic()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isDateFilterActive.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "4A90E2"))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.blue.opacity(0.1))
                                )
                                .scaleEffect(iconScale)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)
                    
                    // Segmented Picker for Upcoming/Completed
                    Picker("Report Type", selection: $selectedFilter) {
                        Text("Upcoming").tag("Upcoming")
                        Text("Completed").tag("Completed")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search tests...", text: $searchText)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.15), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark ? Color.blue.opacity(0.3) : Color(hex: "4A90E2").opacity(0.3), lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    
                    // Date Picker
                    HStack(spacing: 12) {
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .accentColor(colorScheme == .dark ? .blue : Color(hex: "4A90E2"))
                        .opacity(isDateFilterActive ? 1.0 : 0.5)
                    }
                    .padding(.horizontal)
                    
                    // Records List
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                        } else if filteredRecords.isEmpty {
                            Text("No \(selectedFilter.lowercased()) lab records found")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "718096"))
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(filteredRecords) { record in
                                LabRecordCard(record: record, onTap: { selectedRecord = record })
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .padding(.vertical)
            }
            .opacity(opacity)
            .onAppear {
                viewModel.fetchLabRecords()
                withAnimation(.easeInOut(duration: 0.8)) {
                    opacity = 1.0
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                    iconScale = 1.0
                }
            }
            
            // Overlay
            if let record = selectedRecord {
                LabRecordDetailOverlay(record: record, isPresented: Binding(
                    get: { selectedRecord != nil },
                    set: { if !$0 { selectedRecord = nil } }
                ))
            }
        }
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Overlay View
    private struct LabRecordDetailOverlay: View {
        let record: LabRecord
        @Binding var isPresented: Bool
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 20) {
                    // Header
                    Text("Lab Record Details")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C5282"))

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
//                        DetailRow(label: "Test Type", value: record.testTypeName)
//                        DetailRow(label: "Priority", value: record.priority.capitalized)
//                        DetailRow(label: "Lab Name", value: record.labName)
//                        DetailRow(label: "Scheduled Time", value: record.scheduledTime, format: .dateTime.day().month().year().hour().minute())

                        // Dynamic Test Results Section
                        if let resultMap = record.testResult {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Test Results:")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "718096"))

                                ForEach(resultMap.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack {
                                        Text(key.capitalized + ":")
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))

                                        Spacer()

                                        switch value {
                                        case .number(let num):
                                            Text(String(num))
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundColor(.blue)

                                        case .text(let str):
                                            Text(str)
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundColor(.gray)

                                        @unknown default:
                                            Text("Unsupported")
                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        } else {
                            DetailRow(label: "Test Results", value: "Not Available")
                        }
                    }
                    .padding(.horizontal)

                    // Close Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "4A90E2"))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.15), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            }
        }

        // Helper View for Detail Rows
        private struct DetailRow<Value>: View {
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
                HStack {
                    Text(label + ":")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "718096"))

                    Spacer()

                    if let dateValue = value as? Date, let format = format {
                        Text(dateValue, format: format)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                    } else {
                        Text(String(describing: value))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                    }
                }
            }
        }
    }

}

// MARK: - Lab Record Card
struct LabRecordCard: View {
    let record: LabRecord
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color.blue.opacity(0.2) : Color(hex: "4A90E2").opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "4A90E2"))
                        .font(.system(size: 20))
                }
                
                // Title and Label
                HStack {
                    Text(record.labName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                    
                    if record.scheduledTime >= Date() {
                        Text("Recommended")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(colorScheme == .dark ? Color.blue : Color(hex: "4A90E2"))
                            .clipShape(Capsule())
                    } else {
                        Text("Completed")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(colorScheme == .dark ? Color.green : Color(hex: "2ECC71"))
                            .clipShape(Capsule())
                    }
                }
                
                // Type and Scheduled Time
                HStack {
                    Text(record.testTypeName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "718096"))
                    
                    Spacer()
                    
                    Text(record.scheduledTime, format: .dateTime.day().month().hour().minute())
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "718096"))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "1E2533") : .white)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.15), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
