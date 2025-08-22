import PDFKit

struct PDFGenerator {

    @MainActor
    static func createLabRecordPDF(from record: LabRecord, using viewModel: DoctorViewModel, completion: @escaping (Data?) -> Void) {
        viewModel.fetchPatientProfileLab { success in
            if success {
                let pdfData = generatePDF(from: record, using: viewModel)
                completion(pdfData)
            } else {
                completion(nil)
            }
        }
    }

    @MainActor
    private static func generatePDF(from record: LabRecord, using viewModel: DoctorViewModel) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "MediCARE",
            kCGPDFContextAuthor: "MediCARE",
            kCGPDFContextTitle: "Lab Test Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        //var patients: () = viewModel.fetchPatientProfileLab(completion: <#(Bool) -> Void#>)
        
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            var yPos: CGFloat = 40
            let leftMargin: CGFloat = 40

            // MARK: - Drawing Helpers
            
            func drawCenteredText(_ text: String, font: UIFont, y: CGFloat) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraphStyle]
                let attributed = NSAttributedString(string: text, attributes: attrs)
                let size = attributed.size()
                let x = (pageRect.width - size.width) / 2.0
                attributed.draw(at: CGPoint(x: x, y: y))
            }

            func drawText(_ text: String, font: UIFont = .systemFont(ofSize: 14), indent: CGFloat = 0) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font]
                let attributed = NSAttributedString(string: text, attributes: attrs)
                attributed.draw(at: CGPoint(x: leftMargin + indent, y: yPos))
                yPos += 24
            }

            func drawLine(y: CGFloat) {
                context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                context.cgContext.setLineWidth(1)
                context.cgContext.move(to: CGPoint(x: leftMargin, y: y))
                context.cgContext.addLine(to: CGPoint(x: pageRect.width - leftMargin, y: y))
                context.cgContext.strokePath()
            }

            // MARK: - Header
            
            drawCenteredText("MEDICARE HOSPITAL", font: .boldSystemFont(ofSize: 24), y: yPos)
            yPos += 30
            drawCenteredText("Infosys Rd, Hebbal Industrial Estate, Hebbal,", font: .systemFont(ofSize: 12), y: yPos)
            yPos += 16
            drawCenteredText("Mysuru, Ilavala Hobli, Karnataka 570027", font: .systemFont(ofSize: 12), y: yPos)
            yPos += 30
            drawLine(y: yPos)
            yPos += 20

            drawCenteredText("LAB TEST REPORT", font: .boldSystemFont(ofSize: 20), y: yPos)
            yPos += 40

            // MARK: - Patient Information
            
            drawText("Patient Details", font: .boldSystemFont(ofSize: 16))
            yPos += 10

            if let patient = viewModel.patientData {
                
                //print(" werwr \(patient.patient_name)  pfo")
                drawText("Name: \(patient.patient_name)", indent: 10)
                drawText("Mobile: \(patient.patient_mobile ?? "9871618879")", indent: 10)
                drawText("Email: \(patient.patient_email)", indent: 10)
                drawText("Date of Birth: \(patient.patient_dob)", indent: 10)
                drawText("Gender: \(patient.patient_gender)", indent: 10)
                drawText("Blood Group: \(patient.patient_blood_group)", indent: 10)
                drawText("Address: \(patient.patient_address ?? "123 Main St, SRM, Chennai")", indent: 10)

            } else {
                drawText("Name: Akshita Sharma", indent: 10)
                drawText("Mobile: 9871618879", indent: 10)
                drawText("Email: akshitashar012@gmail.com", indent: 10)
                drawText("Date of Birth: 12-02-2005", indent: 10)
                drawText("Gender: Female", indent: 10)
                drawText("Blood Group: A+", indent: 10)
                drawText("Address: 123 Main St, SRM, Chennai", indent: 10)
            }
            

            yPos += 10
            drawLine(y: yPos)
            yPos += 20

            // MARK: - Lab Test Information
            
            drawText("Lab Name: \(record.labName)")
            drawText("Test Type: \(record.testTypeName)")
            drawText("Scheduled Date & Time: \(record.scheduledTime.formatted(.dateTime))")
            drawText("Priority: \(record.priority)")
            drawText("Appointment ID: \(record.appointment)")

            yPos += 10
            drawLine(y: yPos)
            yPos += 20

            // MARK: - Test Results
            
            drawText("Test Results", font: .boldSystemFont(ofSize: 16))
            yPos += 10

            if let results = record.testResult {
                for (key, value) in results {
                    switch value {
                    case .number(let num):
                        drawText("• \(key): \(num)", indent: 10)
                    case .text(let str):
                        drawText("• \(key): \(str)", indent: 10)
                    case .object(let dict):
                        drawText("• \(key): [Complex Object - \(dict.count) values]", indent: 10)
                    }
                }
            } else {
                drawText("Test Results: Pending", indent: 10)
            }

            yPos += 20
            drawLine(y: yPos)
            yPos += 30

            // MARK: - Footer
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let generatedOn = dateFormatter.string(from: Date())

            drawText("Report generated on: \(generatedOn)", font: .italicSystemFont(ofSize: 12))
            yPos += 10
            drawText("Note: Please consult your physician for accurate interpretation of results.", font: .italicSystemFont(ofSize: 12))
        }
    }
}
