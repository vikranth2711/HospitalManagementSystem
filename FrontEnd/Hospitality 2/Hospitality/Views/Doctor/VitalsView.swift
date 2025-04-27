import SwiftUI

struct VitalsView: View {
    @Environment(\.colorScheme) var colorScheme

    @State private var originalVitals = PatientVitals(
        id: UUID().uuidString,
        patientId: "",
        patientHeight: 0.0,
        patientWeight: 0.0,
        patientHeartrate: 0,
        patientSpo2: 0,
        patientTemperature: 0.0,
        appointmentId: ""
    )
    
    // Separate editable state
    @State private var editablePatientHeight: String = ""
    @State private var editablePatientWeight: String = ""
    @State private var editablePatientHeartrate: String = ""
    @State private var editablePatientSpo2: String = ""
    @State private var editablePatientTemperature: String = ""

    var body: some View {
        ZStack {
            backgroundView

            Form {
                Section(header: Text("Patient Vitals")) {
                    TextField("Height (cm)*", text: $editablePatientHeight)
                        .keyboardType(.decimalPad)

                    TextField("Weight (kg)*", text: $editablePatientWeight)
                        .keyboardType(.decimalPad)

                    TextField("Heart Rate (bpm)*", text: $editablePatientHeartrate)
                        .keyboardType(.numberPad)

                    TextField("SpO₂ (%)", text: $editablePatientSpo2)
                        .keyboardType(.numberPad)

                    TextField("Temperature (°C)", text: $editablePatientTemperature)
                        .keyboardType(.decimalPad)
                }

                Section {
                    NavigationLink(destination: PrescriptionFormView()) {
                        Text("Go to Prescription")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Vitals Entry")
        }
        .onAppear {
            loadVitalsIntoEditableFields()
        }
    }

    // Load original vitals into editable fields when view appears
    private func loadVitalsIntoEditableFields() {
        editablePatientHeight = originalVitals.patientHeight == 0.0 ? "" : String(format: "%.1f", originalVitals.patientHeight)
        editablePatientWeight = originalVitals.patientWeight == 0.0 ? "" : String(format: "%.1f", originalVitals.patientWeight)
        editablePatientHeartrate = originalVitals.patientHeartrate == 0 ? "" : "\(originalVitals.patientHeartrate)"
        editablePatientSpo2 = originalVitals.patientSpo2 == 0 ? "" : "\(originalVitals.patientSpo2)"
        editablePatientTemperature = originalVitals.patientTemperature == 0.0 ? "" : String(format: "%.1f", originalVitals.patientTemperature)
    }


    // MARK: - Background View
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color(hex: "101490") : Color(hex: "E8F5FF"),
                colorScheme == .dark ? Color(hex: "1A202C") : Color(hex: "F0F8FF")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct VitalsView_Previews: PreviewProvider {
    static var previews: some View {
        VitalsView()
    }
}
