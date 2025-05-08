# transactions/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from accounts.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated
from hospital.permissions import IsAdminStaff
from .models import Invoice, InvoiceType, Transaction, Unit
from .serializers import InvoiceSerializer
from django.shortcuts import get_object_or_404
from hospital.models import Appointment, LabTest, Patient
import decimal

class InvoiceListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        # Filter invoices based on user type
        if hasattr(request.user, 'patient_id'):
            # Patients can only see their own invoices
            invoices = Invoice.objects.filter(patient=request.user)
        elif hasattr(request.user, 'staff_id'):
            # Check if admin
            try:
                is_admin = request.user.role.role_permissions.get('is_admin', False)
                if is_admin:
                    # Admins can see all invoices
                    invoices = Invoice.objects.all()
                else:
                    # Non-admin staff can't see invoices
                    return Response({"error": "Not authorized to view invoices"}, status=403)
            except:
                return Response({"error": "Not authorized to view invoices"}, status=403)
        else:
            return Response({"error": "Invalid user"}, status=403)
            
        serializer = InvoiceSerializer(invoices, many=True)
        return Response(serializer.data, status=200)

class InvoiceDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, invoice_id):
        invoice = get_object_or_404(Invoice, invoice_id=invoice_id)
        
        # Check permissions
        if hasattr(request.user, 'patient_id'):
            if invoice.patient.patient_id != request.user.patient_id:
                return Response({"error": "Not authorized to view this invoice"}, status=403)
        elif hasattr(request.user, 'staff_id'):
            try:
                is_admin = request.user.role.role_permissions.get('is_admin', False)
                if not is_admin:
                    return Response({"error": "Not authorized to view this invoice"}, status=403)
            except:
                return Response({"error": "Not authorized to view this invoice"}, status=403)
        else:
            return Response({"error": "Invalid user"}, status=403)
            
        serializer = InvoiceSerializer(invoice)
        
        # Get detailed information about invoice items
        detailed_items = []
        for item_id in invoice.invoice_items:
            if invoice.invoice_type.invoice_type_name == 'appointment':
                try:
                    appointment = Appointment.objects.get(appointment_id=item_id)
                    detailed_items.append({
                        "item_id": item_id,
                        "item_type": "appointment",
                        "doctor_name": appointment.staff.staff_name,
                        "appointment_date": appointment.created_at.strftime('%Y-%m-%d'),
                        "slot_time": appointment.slot.slot_start_time.strftime('%H:%M')
                    })
                except Appointment.DoesNotExist:
                    detailed_items.append({"item_id": item_id, "item_type": "appointment", "status": "not found"})
            elif invoice.invoice_type.invoice_type_name == 'lab_test':
                try:
                    lab_test = LabTest.objects.get(lab_test_id=item_id)
                    detailed_items.append({
                        "item_id": item_id,
                        "item_type": "lab_test",
                        "test_name": lab_test.test_type.test_name,
                        "lab_name": lab_test.lab.lab_name,
                        "test_date": lab_test.test_datetime.strftime('%Y-%m-%d')
                    })
                except LabTest.DoesNotExist:
                    detailed_items.append({"item_id": item_id, "item_type": "lab_test", "status": "not found"})
        
        # Add detailed items to the response
        response_data = serializer.data
        response_data['detailed_items'] = detailed_items
        
        return Response(response_data, status=200)

class GenerateAppointmentInvoiceView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def post(self, request, appointment_id):
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check if invoice already exists for this appointment
        if Invoice.objects.filter(
            invoice_type__invoice_type_name='appointment',
            invoice_items__contains=[appointment_id]
        ).exists():
            return Response({"error": "Invoice already exists for this appointment"}, status=400)
            
        # Check if transaction exists
        if not appointment.tran:
            return Response({"error": "No transaction found for this appointment"}, status=400)
            
        # Get appointment charge
        if not appointment.charge:
            return Response({"error": "No charge information found for this appointment"}, status=400)
            
        # Get invoice type
        try:
            invoice_type = InvoiceType.objects.get(invoice_type_name='appointment')
        except InvoiceType.DoesNotExist:
            return Response({"error": "Appointment invoice type not found"}, status=400)
            
        # Calculate tax (assuming 5% tax)
        tax_rate = decimal.Decimal('0.05')
        subtotal = appointment.charge.charge_amount
        tax = subtotal * tax_rate
        total = subtotal + tax
        
        # Create invoice
        invoice = Invoice.objects.create(
            tran=appointment.tran,
            invoice_type=invoice_type,
            patient=appointment.patient,
            invoice_items=[appointment.appointment_id],
            invoice_subtotal=subtotal,
            invoice_tax=tax,
            invoice_total=total,
            invoice_unit=appointment.charge.charge_unit,
            invoice_status='paid' if appointment.tran.transaction_status == 'completed' else 'pending',
            invoice_remark=f"Invoice for appointment on {appointment.created_at.strftime('%Y-%m-%d')}"
        )
        
        serializer = InvoiceSerializer(invoice)
        return Response(serializer.data, status=201)

class GenerateLabTestInvoiceView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def post(self, request, lab_test_id):
        lab_test = get_object_or_404(LabTest, lab_test_id=lab_test_id)
        
        # Check if invoice already exists for this lab test
        if Invoice.objects.filter(
            invoice_type__invoice_type_name='lab_test',
            invoice_items__contains=[lab_test_id]
        ).exists():
            return Response({"error": "Invoice already exists for this lab test"}, status=400)
            
        # Check if transaction exists
        if not lab_test.tran:
            return Response({"error": "No transaction found for this lab test"}, status=400)
            
        # Get invoice type
        try:
            invoice_type = InvoiceType.objects.get(invoice_type_name='lab_test')
        except InvoiceType.DoesNotExist:
            return Response({"error": "Lab test invoice type not found"}, status=400)
            
        # Get test charge
        from hospital.models import LabTestCharge
        try:
            charge = LabTestCharge.objects.get(test=lab_test.test_type, is_active=True)
        except LabTestCharge.DoesNotExist:
            return Response({"error": "No charge information found for this lab test"}, status=400)
            
        # Calculate tax (assuming 5% tax)
        tax_rate = decimal.Decimal('0.05')
        subtotal = charge.charge_amount
        tax = subtotal * tax_rate
        total = subtotal + tax
        
        # Create invoice
        invoice = Invoice.objects.create(
            tran=lab_test.tran,
            invoice_type=invoice_type,
            patient=lab_test.appointment.patient,
            invoice_items=[lab_test.lab_test_id],
            invoice_subtotal=subtotal,
            invoice_tax=tax,
            invoice_total=total,
            invoice_unit=charge.charge_unit,
            invoice_status='paid' if lab_test.tran.transaction_status == 'completed' else 'pending',
            invoice_remark=f"Invoice for {lab_test.test_type.test_name} on {lab_test.test_datetime.strftime('%Y-%m-%d')}"
        )
        
        serializer = InvoiceSerializer(invoice)
        return Response(serializer.data, status=201)

class GenerateMultipleLabTestsInvoiceView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def post(self, request):
        lab_test_ids = request.data.get('lab_test_ids', [])
        patient_id = request.data.get('patient_id')
        
        if not lab_test_ids:
            return Response({"error": "No lab test IDs provided"}, status=400)
            
        if not patient_id:
            return Response({"error": "Patient ID is required"}, status=400)
            
        # Get patient
        try:
            patient = Patient.objects.get(patient_id=patient_id)
        except Patient.DoesNotExist:
            return Response({"error": f"Patient with ID {patient_id} not found"}, status=400)
            
        # Check if all lab tests exist and belong to the patient
        lab_tests = []
        for test_id in lab_test_ids:
            try:
                test = LabTest.objects.get(lab_test_id=test_id)
                if test.appointment.patient.patient_id != patient.patient_id:
                    return Response({"error": f"Lab test {test_id} does not belong to this patient"}, status=400)
                if not test.tran:
                    return Response({"error": f"Lab test {test_id} has no transaction"}, status=400)
                lab_tests.append(test)
            except LabTest.DoesNotExist:
                return Response({"error": f"Lab test with ID {test_id} not found"}, status=400)
                
        # Check if any of these tests already have invoices
        for test in lab_tests:
            if Invoice.objects.filter(
                invoice_type__invoice_type_name='lab_test',
                invoice_items__contains=[test.lab_test_id]
            ).exists():
                return Response({"error": f"Invoice already exists for lab test {test.lab_test_id}"}, status=400)
                
        # Get invoice type
        try:
            invoice_type = InvoiceType.objects.get(invoice_type_name='lab_test')
        except InvoiceType.DoesNotExist:
            return Response({"error": "Lab test invoice type not found"}, status=400)
            
        # Calculate totals
        from hospital.models import LabTestCharge
        subtotal = decimal.Decimal('0.00')
        unit = None
        
        for test in lab_tests:
            try:
                charge = LabTestCharge.objects.get(test=test.test_type, is_active=True)
                subtotal += charge.charge_amount
                if unit is None:
                    unit = charge.charge_unit
                elif unit.unit_id != charge.charge_unit.unit_id:
                    return Response({"error": "Cannot create invoice with different currency units"}, status=400)
            except LabTestCharge.DoesNotExist:
                return Response({"error": f"No charge information found for lab test {test.lab_test_id}"}, status=400)
                
        # Calculate tax (assuming 5% tax)
        tax_rate = decimal.Decimal('0.05')
        tax = subtotal * tax_rate
        total = subtotal + tax
        
        # Create invoice
        invoice = Invoice.objects.create(
            tran=lab_tests[0].tran,  # Use the first test's transaction
            invoice_type=invoice_type,
            patient=patient,
            invoice_items=[test.lab_test_id for test in lab_tests],
            invoice_subtotal=subtotal,
            invoice_tax=tax,
            invoice_total=total,
            invoice_unit=unit,
            invoice_status='paid',
            invoice_remark=f"Invoice for multiple lab tests on {lab_tests[0].test_datetime.strftime('%Y-%m-%d')}"
        )
        
        serializer = InvoiceSerializer(invoice)
        return Response(serializer.data, status=201)

class UpdateInvoiceStatusView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def put(self, request, invoice_id):
        invoice = get_object_or_404(Invoice, invoice_id=invoice_id)
        status_value = request.data.get('status')
        
        if not status_value:
            return Response({"error": "Status is required"}, status=400)
            
        if status_value not in ['pending', 'paid', 'cancelled', 'refunded']:
            return Response({"error": "Invalid status value"}, status=400)
            
        invoice.invoice_status = status_value
        invoice.save()
        
        serializer = InvoiceSerializer(invoice)
        return Response(serializer.data, status=200)

class PatientInvoicesView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, patient_id):
        # Check permissions
        if hasattr(request.user, 'patient_id'):
            if int(patient_id) != request.user.patient_id:
                return Response({"error": "Not authorized to view these invoices"}, status=403)
        elif hasattr(request.user, 'staff_id'):
            try:
                is_admin = request.user.role.role_permissions.get('is_admin', False)
                if not is_admin:
                    return Response({"error": "Not authorized to view these invoices"}, status=403)
            except:
                return Response({"error": "Not authorized to view these invoices"}, status=403)
        else:
            return Response({"error": "Invalid user"}, status=403)
            
        # Get patient's invoices
        invoices = Invoice.objects.filter(patient_id=patient_id)
        serializer = InvoiceSerializer(invoices, many=True)
        return Response(serializer.data, status=200)

from django.http import HttpResponse
from django.template.loader import render_to_string
from weasyprint import HTML
import tempfile

class GenerateInvoicePDFView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, invoice_id):
        invoice = get_object_or_404(Invoice, invoice_id=invoice_id)
        
        # Check permissions
        if hasattr(request.user, 'patient_id'):
            if invoice.patient.patient_id != request.user.patient_id:
                return Response({"error": "Not authorized to view this invoice"}, status=403)
        elif hasattr(request.user, 'staff_id'):
            try:
                is_admin = request.user.role.role_permissions.get('is_admin', False)
                if not is_admin:
                    return Response({"error": "Not authorized to view this invoice"}, status=403)
            except:
                return Response({"error": "Not authorized to view this invoice"}, status=403)
        else:
            return Response({"error": "Invalid user"}, status=403)
            
        # Get detailed information about invoice items
        detailed_items = []
        for item_id in invoice.invoice_items:
            if invoice.invoice_type.invoice_type_name == 'appointment':
                try:
                    appointment = Appointment.objects.get(appointment_id=item_id)
                    detailed_items.append({
                        "item_id": item_id,
                        "item_type": "appointment",
                        "doctor_name": appointment.staff.staff_name,
                        "appointment_date": appointment.created_at.strftime('%Y-%m-%d'),
                        "slot_time": appointment.slot.slot_start_time.strftime('%H:%M'),
                        "amount": appointment.charge.charge_amount
                    })
                except Appointment.DoesNotExist:
                    pass
            elif invoice.invoice_type.invoice_type_name == 'lab_test':
                try:
                    lab_test = LabTest.objects.get(lab_test_id=item_id)
                    from hospital.models import LabTestCharge
                    charge = LabTestCharge.objects.get(test=lab_test.test_type, is_active=True)
                    detailed_items.append({
                        "item_id": item_id,
                        "item_type": "lab_test",
                        "test_name": lab_test.test_type.test_name,
                        "lab_name": lab_test.lab.lab_name,
                        "test_date": lab_test.test_datetime.strftime('%Y-%m-%d'),
                        "amount": charge.charge_amount
                    })
                except (LabTest.DoesNotExist, LabTestCharge.DoesNotExist):
                    pass
        
        # Prepare context for the template
        context = {
            'invoice': invoice,
            'detailed_items': detailed_items,
            'hospital_name': 'Your Hospital Name',
            'hospital_address': 'Your Hospital Address',
            'hospital_phone': 'Your Hospital Phone',
            'hospital_email': 'your@hospital.com'
        }
        
        # Render HTML
        html_string = render_to_string('invoice_template.html', context)
        
        # Generate PDF
        response = HttpResponse(content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="invoice_{invoice.invoice_number}.pdf"'
        
        with tempfile.NamedTemporaryFile(suffix='.html') as temp:
            temp.write(html_string.encode('utf-8'))
            temp.flush()
            HTML(filename=temp.name).write_pdf(response)
            
        return response

