import decimal
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.shortcuts import get_object_or_404
from accounts.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated
from .models import (LabType, Staff, StaffDetails, DoctorDetails, LabTechnicianDetails, Role, DoctorType, 
                     Schedule, Appointment, Slot, PatientDetails, Patient, PatientVitals,
                     PrescribedMedicine, Prescription, Shift, Diagnosis, Medicine,
                     TargetOrgan, AppointmentCharge, LabTestType, LabTest, Lab, LabTestCharge)
from .permissions import IsAdminStaff
import uuid
import datetime
from django.utils.dateparse import parse_datetime
from transactions.models import Transaction, PaymentMethod, TransactionType, Unit, InvoiceType, Invoice
import json
import traceback
from .serializers import LabTestSerializer, LabSerializer, RecommendedLabTestSerializer, AssignedPatientSerializer
class DoctorListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        doctors = Staff.objects.filter(doctor_details__isnull=False)
        result = []
        for staff in doctors:
            doctor = staff.doctor_details
            result.append({
                "staff_id": staff.staff_id,
                "staff_name": staff.staff_name,
                "specialization": doctor.doctor_specialization,
                "doctor_type": doctor.doctor_type.doctor_type,
                "on_leave": staff.on_leave
            })
        return Response(result, status=status.HTTP_200_OK)

class DoctorDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, staff_id):
        staff = get_object_or_404(Staff, staff_id=staff_id, doctor_details__isnull=False)
        doctor = staff.doctor_details
        data = {
            "staff_id": staff.staff_id,
            "staff_name": staff.staff_name,
            "specialization": doctor.doctor_specialization,
            "doctor_type": doctor.doctor_type.doctor_type,
            "on_leave": staff.on_leave
        }
        return Response(data, status=status.HTTP_200_OK)

from datetime import datetime, timedelta

class DoctorSlotsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, staff_id):
        date_str = request.GET.get("date")
        if not date_str:
            return Response({"error": "Date is required"}, status=400)
        try:
            date = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "Invalid date format"}, status=400)

        # Find shifts assigned to doctor on that date
        schedules = Schedule.objects.filter(staff__staff_id=staff_id, schedule_date=date)
        slots = []
        for schedule in schedules:
            for slot in schedule.shift.slots.all():
                # Check if slot is already booked
                is_booked = Appointment.objects.filter(
                    staff__staff_id=staff_id, slot=slot, created_at__date=date
                ).exists()
                slots.append({
                    "slot_id": slot.slot_id,
                    "slot_start_time": slot.slot_start_time,
                    "slot_duration": slot.slot_duration,
                    "is_booked": is_booked
                })
        return Response(slots, status=200)

# class BookAppointmentView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def post(self, request):
#         patient = request.user
#         data = request.data
#         date = data.get("date")
#         staff_id = data.get("staff_id")
#         slot_id = data.get("slot_id")
#         reason = data.get("reason")

#         if not all([date, staff_id, slot_id, reason]):
#             return Response({"error": "Missing required fields"}, status=400)

#         try:
#             slot = Slot.objects.get(slot_id=slot_id)
#             staff = Staff.objects.get(staff_id=staff_id)
#         except (Slot.DoesNotExist, Staff.DoesNotExist):
#             return Response({"error": "Invalid staff or slot"}, status=400)

#         # Check if slot is available
#         slot_datetime = datetime.strptime(date, "%Y-%m-%d")
#         if Appointment.objects.filter(
#             staff=staff, slot=slot, created_at__date=slot_datetime
#         ).exists():
#             return Response({"error": "Slot already booked"}, status=409)

#         appointment = Appointment.objects.create(
#             patient=patient,
#             staff=staff,
#             slot=slot,
#         )
#         # Optionally, save the reason in a remark field or a related model
#         appointment.patient.patient_remark = reason
#         appointment.patient.save()
#         return Response({"message": "Appointment booked", "appointment_id": appointment.appointment_id}, status=201)

class BookAppointmentView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        patient = request.user
        data = request.data
        date = data.get("date")
        staff_id = data.get("staff_id")
        slot_id = data.get("slot_id")
        reason = data.get("reason")

        if not all([date, staff_id, slot_id, reason]):
            return Response({"error": "Missing required fields"}, status=400)

        try:
            slot = Slot.objects.get(slot_id=slot_id)
            staff = Staff.objects.get(staff_id=staff_id)
        except (Slot.DoesNotExist, Staff.DoesNotExist):
            return Response({"error": "Invalid staff or slot"}, status=400)

        # Check if slot is available
        try:
            appointment_date = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "Invalid date format. Use YYYY-MM-DD"}, status=400)
            
        if Appointment.objects.filter(
            staff=staff, slot=slot, appointment_date=appointment_date
        ).exists():
            return Response({"error": "Slot already booked"}, status=409)

        appointment = Appointment.objects.create(
            patient=patient,
            staff=staff,
            slot=slot,
            reason=reason,
            status='upcoming',
            appointment_date=appointment_date
        )
        
        return Response({
            "message": "Appointment booked", 
            "appointment_id": appointment.appointment_id
        }, status=201)

############## NEEDS FIXING ###########################
# class BookAppointmentWithPaymentView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def post(self, request):
#         patient = request.user
#         data = request.data
#         date = data.get("date")
#         staff_id = data.get("staff_id")
#         slot_id = data.get("slot_id")
#         reason = data.get("reason")
#         payment_method_id = data.get("payment_method_id")

#         if not all([date, staff_id, slot_id, reason, payment_method_id]):
#             return Response({"error": "Missing required fields"}, status=400)

#         try:
#             slot = Slot.objects.get(slot_id=slot_id)
#             staff = Staff.objects.get(staff_id=staff_id)
#             payment_method = PaymentMethod.objects.get(payment_method_id=payment_method_id)
#             transaction_type = TransactionType.objects.get(transaction_type_name="payment")
#             default_unit = Unit.objects.get(unit_name="INR")  # Adjust as needed
#         except (Slot.DoesNotExist, Staff.DoesNotExist, PaymentMethod.DoesNotExist, 
#                 TransactionType.DoesNotExist, Unit.DoesNotExist) as e:
#             return Response({"error": f"Invalid reference: {str(e)}"}, status=400)

#         # Check if slot is available
#         try:
#             appointment_date = datetime.strptime(date, "%Y-%m-%d").date()
#         except ValueError:
#             return Response({"error": "Invalid date format. Use YYYY-MM-DD"}, status=400)
            
#         if Appointment.objects.filter(
#             staff=staff, slot=slot, created_at__date=appointment_date
#         ).exists():
#             return Response({"error": "Slot already booked"}, status=409)

#         # Get appointment charge for this doctor
#         try:
#             charge = AppointmentCharge.objects.get(doctor=staff, is_active=True)
#         except AppointmentCharge.DoesNotExist:
#             return Response({"error": "No appointment charge set for this doctor"}, status=400)

#         # Create transaction
#         transaction = Transaction.objects.create(
#             transaction_reference=f"APP-{uuid.uuid4().hex[:8].upper()}",
#             transaction_type=transaction_type,
#             payment_method=payment_method,
#             transaction_amount=charge.charge_amount,
#             transaction_unit=charge.charge_unit,
#             transaction_status="completed",  # Assuming payment is successful
#             patient=patient,
#             transaction_details={"appointment_date": date, "doctor": staff.staff_name}
#         )

#         # Create appointment
#         appointment = Appointment.objects.create(
#             patient=patient,
#             staff=staff,
#             slot=slot,
#             tran=transaction,
#             charge=charge,
#             reason=reason,
#             status='upcoming'
#         )
        
#         return Response({
#             "message": "Appointment booked and payment processed", 
#             "appointment_id": appointment.appointment_id,
#             "transaction_id": transaction.transaction_id
#         }, status=201)

class BookAppointmentWithPaymentView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        patient = request.user
        data = request.data
        date = data.get("date")
        staff_id = data.get("staff_id")
        slot_id = data.get("slot_id")
        reason = data.get("reason")
        payment_method_id = data.get("payment_method_id")
        transaction_reference = data.get("transaction_reference")  # Get transaction reference from frontend

        # Check required fields
        if not all([date, staff_id, slot_id, reason, payment_method_id]):
            return Response({"error": "Missing required fields"}, status=400)

        # Transaction reference is required for payment
        if not transaction_reference:
            return Response({"error": "Transaction reference is required"}, status=400)

        try:
            slot = Slot.objects.get(slot_id=slot_id)
            staff = Staff.objects.get(staff_id=staff_id)
            payment_method = PaymentMethod.objects.get(payment_method_id=payment_method_id)
            transaction_type = TransactionType.objects.get(transaction_type_name="payment")
            default_unit = Unit.objects.get(unit_name="INR")  # Adjust as needed
        except (Slot.DoesNotExist, Staff.DoesNotExist, PaymentMethod.DoesNotExist, 
                TransactionType.DoesNotExist, Unit.DoesNotExist) as e:
            return Response({"error": f"Invalid reference: {str(e)}"}, status=400)

        # Check if slot is available
        try:
            appointment_date = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "Invalid date format. Use YYYY-MM-DD"}, status=400)
            
        if Appointment.objects.filter(
            staff=staff, slot=slot, appointment_date=appointment_date
        ).exists():
            return Response({"error": "Slot already booked"}, status=409)

        # Check if transaction reference is already used
        if Transaction.objects.filter(transaction_reference=transaction_reference).exists():
            return Response({"error": "Transaction reference already used"}, status=400)

        # Get appointment charge for this doctor
        try:
            charge = AppointmentCharge.objects.get(doctor=staff, is_active=True)
        except AppointmentCharge.DoesNotExist:
            return Response({"error": "No appointment charge set for this doctor"}, status=400)

        # Create transaction with the provided reference
        transaction = Transaction.objects.create(
            transaction_reference=transaction_reference,
            transaction_type=transaction_type,
            payment_method=payment_method,
            transaction_amount=charge.charge_amount,
            transaction_unit=charge.charge_unit,
            transaction_status="completed",  # Assuming payment is successful
            patient=patient,
            transaction_details={
                "appointment_date": date, 
                "doctor": staff.staff_name,
                "payment_gateway_response": data.get("payment_gateway_response", {})  # Optional additional payment details
            }
        )

        # Create appointment
        appointment = Appointment.objects.create(
            patient=patient,
            staff=staff,
            slot=slot,
            tran=transaction,
            charge=charge,
            reason=reason,
            status='upcoming',
            appointment_date=appointment_date  # Make sure to set the appointment date
        )
        
        # Generate invoice for the appointment
        try:
            invoice_type = InvoiceType.objects.get(invoice_type_name='appointment')
            
            # Calculate tax (assuming 5% tax)
            tax_rate = decimal.Decimal('0.05')
            subtotal = charge.charge_amount
            tax = subtotal * tax_rate
            total = subtotal + tax
            
            # Create invoice
            invoice = Invoice.objects.create(
                tran=transaction,
                invoice_type=invoice_type,
                patient=patient,
                invoice_items=[appointment.appointment_id],
                invoice_subtotal=subtotal,
                invoice_tax=tax,
                invoice_total=total,
                invoice_unit=charge.charge_unit,
                invoice_status='paid',
                invoice_remark=f"Invoice for appointment on {appointment_date.isoformat()}"
            )
            
            return Response({
                "message": "Appointment booked and payment processed", 
                "appointment_id": appointment.appointment_id,
                "transaction_id": transaction.transaction_id,
                "invoice_id": invoice.invoice_id,
                "invoice_number": invoice.invoice_number
            }, status=201)
            
        except Exception as e:
            # If invoice creation fails, still return success for the appointment
            return Response({
                "message": "Appointment booked and payment processed, but invoice generation failed", 
                "appointment_id": appointment.appointment_id,
                "transaction_id": transaction.transaction_id,
                "error": str(e)
            }, status=201)

class RescheduleAppointmentView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def put(self, request, appointment_id):
        try:
            appointment = Appointment.objects.get(appointment_id=appointment_id)
        except Appointment.DoesNotExist:
            return Response({"error": "Appointment not found"}, status=404)
        
        # Check if user is authorized to reschedule this appointment
        if hasattr(request.user, 'patient_id'):
            if appointment.patient.patient_id != request.user.patient_id:
                return Response({"error": "Not authorized to reschedule this appointment"}, status=403)
        elif hasattr(request.user, 'staff_id'):
            # Staff can reschedule any appointment if they're admin
            if appointment.staff.staff_id != request.user.staff_id:
                try:
                    is_admin = request.user.role.role_permissions.get('is_admin', False)
                    if not is_admin:
                        return Response({"error": "Not authorized to reschedule this appointment"}, status=403)
                except:
                    return Response({"error": "Not authorized to reschedule this appointment"}, status=403)
        else:
            return Response({"error": "Invalid user"}, status=403)
            
        # Check if appointment can be rescheduled
        if appointment.status != 'upcoming':
            return Response({"error": "Only upcoming appointments can be rescheduled"}, status=400)
            
        # Get new slot and date
        new_slot_id = request.data.get('slot_id')
        new_date = request.data.get('date')
        
        if not all([new_slot_id, new_date]):
            return Response({"error": "Missing required fields"}, status=400)
            
        try:
            new_slot = Slot.objects.get(slot_id=new_slot_id)
            new_date = datetime.strptime(new_date, "%Y-%m-%d").date()
        except (Slot.DoesNotExist, ValueError):
            return Response({"error": "Invalid slot or date format"}, status=400)
            
        # Check if new slot is available
        if Appointment.objects.filter(
            staff=appointment.staff, slot=new_slot, created_at__date=new_date
        ).exists():
            return Response({"error": "Selected slot is already booked"}, status=409)
            
        # Update appointment
        appointment.slot = new_slot
        appointment.created_at = datetime.combine(new_date, datetime.min.time())
        appointment.save()
        
        return Response({
            "message": "Appointment rescheduled successfully",
            "appointment_id": appointment.appointment_id,
            "new_date": new_date,
            "new_slot_id": new_slot.slot_id
        }, status=200)

# class DiagnosisCreateView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]
#     parser_classes = [MultiPartParser, FormParser, JSONParser]

#     def post(self, request, appointment_id):
#         # Check if user is a doctor or staff
#         if not hasattr(request.user, 'staff_id'):
#             return Response({"error": "Only staff can create diagnoses"}, status=403)
            
#         # Get the appointment
#         appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
#         # Check if this staff is assigned to this appointment
#         if appointment.staff.staff_id != request.user.staff_id:
#             return Response({"error": "You are not authorized to diagnose this appointment"}, status=403)
            
#         # Get diagnosis data
#         diagnosis_data = request.data.get("diagnosis_data", {})
#         if isinstance(diagnosis_data, str):
#             try:
#                 diagnosis_data = json.loads(diagnosis_data)
#             except json.JSONDecodeError:
#                 return Response({"error": "Invalid JSON in diagnosis_data"}, status=400)
                
#         lab_test_required = request.data.get("lab_test_required", "false").lower() == "true"
#         follow_up_required = request.data.get("follow_up_required", "false").lower() == "true"
        
#         if not diagnosis_data:
#             return Response({"error": "Diagnosis data is required"}, status=400)
            
#         # Create the diagnosis
#         diagnosis = Diagnosis.objects.create(
#             appointment=appointment,
#             diagnosis_data=diagnosis_data,
#             lab_test_required=lab_test_required,
#             follow_up_required=follow_up_required
#         )
        
#         # Mark the appointment as completed
#         appointment.status = 'completed'
#         appointment.save()
        
#         return Response({
#             "message": "Diagnosis created and appointment marked as completed",
#             "diagnosis_id": diagnosis.diagnosis_id
#         }, status=201)
class DiagnosisCreateView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request, appointment_id):
        # Check if user is a doctor or staff
        if not hasattr(request.user, 'staff_id'):
            return Response({"error": "Only staff can create diagnoses"}, status=403)
            
        # Get the appointment
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check if this staff is assigned to this appointment
        if appointment.staff.staff_id != request.user.staff_id:
            return Response({"error": "You are not authorized to diagnose this appointment"}, status=403)
            
        # Get diagnosis data
        diagnosis_data = request.data.get("diagnosis_data", {})
        if isinstance(diagnosis_data, str):
            try:
                diagnosis_data = json.loads(diagnosis_data)
            except json.JSONDecodeError:
                return Response({"error": "Invalid JSON in diagnosis_data"}, status=400)
        
        # Handle both boolean and string inputs for lab_test_required
        lab_test_required_value = request.data.get("lab_test_required", False)
        if isinstance(lab_test_required_value, str):
            lab_test_required = lab_test_required_value.lower() == "true"
        else:
            lab_test_required = bool(lab_test_required_value)
            
        # Handle both boolean and string inputs for follow_up_required
        follow_up_required_value = request.data.get("follow_up_required", False)
        if isinstance(follow_up_required_value, str):
            follow_up_required = follow_up_required_value.lower() == "true"
        else:
            follow_up_required = bool(follow_up_required_value)
        
        if not diagnosis_data:
            return Response({"error": "Diagnosis data is required"}, status=400)
            
        # Create the diagnosis
        diagnosis = Diagnosis.objects.create(
            appointment=appointment,
            diagnosis_data=diagnosis_data,
            lab_test_required=lab_test_required,
            follow_up_required=follow_up_required
        )
        
        # Mark the appointment as completed
        appointment.status = 'completed'
        appointment.save()
        
        return Response({
            "message": "Diagnosis created and appointment marked as completed",
            "diagnosis_id": diagnosis.diagnosis_id
        }, status=201)


class ShiftListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        shifts = Shift.objects.all()
        data = []
        for shift in shifts:
            data.append({
                "shift_id": shift.shift_id,
                "shift_name": shift.shift_name,
                "start_time": shift.start_time.strftime('%H:%M:%S'),
                "end_time": shift.end_time.strftime('%H:%M:%S')
            })
        return Response(data, status=status.HTTP_200_OK)
    
class DiagnosisDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, diagnosis_id):
        diagnosis = get_object_or_404(Diagnosis, diagnosis_id=diagnosis_id)
        
        # Check if user has permission to view this diagnosis
        user = request.user
        if hasattr(user, 'patient_id'):
            # Patients can only view their own diagnoses
            if diagnosis.appointment.patient.patient_id != user.patient_id:
                return Response({"error": "Not authorized to view this diagnosis"}, status=403)
        elif hasattr(user, 'staff_id'):
            # Staff can view diagnoses for appointments they're assigned to
            if diagnosis.appointment.staff.staff_id != user.staff_id:
                # Check if admin staff
                try:
                    is_admin = user.role.role_permissions.get('is_admin', False)
                    if not is_admin:
                        return Response({"error": "Not authorized to view this diagnosis"}, status=403)
                except:
                    return Response({"error": "Not authorized to view this diagnosis"}, status=403)
        else:
            return Response({"error": "Invalid user"}, status=403)
            
        data = {
            "diagnosis_id": diagnosis.diagnosis_id,
            "diagnosis_data": diagnosis.diagnosis_data,
            "lab_test_required": diagnosis.lab_test_required,
            "follow_up_required": diagnosis.follow_up_required,
            "appointment": {
                "appointment_id": diagnosis.appointment.appointment_id,
                "date": diagnosis.appointment.created_at.date(),
                "patient_id": diagnosis.appointment.patient.patient_id,
                "patient_name": diagnosis.appointment.patient.patient_name,
                "staff_id": diagnosis.appointment.staff.staff_id,
                "staff_name": diagnosis.appointment.staff.staff_name
            }
        }
        
        return Response(data, status=200)

# class AppointmentHistoryView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         user = request.user
#         if hasattr(user, 'patient_id'):
#             appointments = Appointment.objects.filter(patient=user)
#         elif hasattr(user, 'staff_id'):
#             appointments = Appointment.objects.filter(staff=user)
#         else:
#             return Response({"error": "Invalid user"}, status=403)

#         data = []
#         for app in appointments:
#             data.append({
#                 "appointment_id": app.appointment_id,
#                 "date": app.created_at.date(),
#                 "slot_id": app.slot.slot_id,
#                 "staff_id": app.staff.staff_id,
#                 "patient_id": app.patient.patient_id,
#                 "status": "completed" if app.created_at < datetime.now() else "upcoming"
#             })
#         return Response(data, status=200)
from django.utils import timezone

# class AppointmentHistoryView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         user = request.user
#         if hasattr(user, 'patient_id'):
#             appointments = Appointment.objects.filter(patient=user)
#         elif hasattr(user, 'staff_id'):
#             appointments = Appointment.objects.filter(staff=user)
#         else:
#             return Response({"error": "Invalid user"}, status=403)

#         data = []
#         now = timezone.now()  # <-- correct timezone-aware now
#         for app in appointments:
#             data.append({
#                 "appointment_id": app.appointment_id,
#                 "date": app.created_at.date(),
#                 "slot_id": app.slot.slot_id,
#                 "staff_id": app.staff.staff_id,
#                 "patient_id": app.patient.patient_id,
#                 "status": "completed" if app.created_at < now else "upcoming"
#             })
#         return Response(data, status=200)

class AppointmentHistoryView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if hasattr(user, 'patient_id'):
            appointments = Appointment.objects.filter(patient=user)
        elif hasattr(user, 'staff_id'):
            appointments = Appointment.objects.filter(staff=user)
        else:
            return Response({"error": "Invalid user"}, status=403)

        # Update statuses for appointments that should be marked as missed
        now = timezone.now().date()  # Get current date
        for appointment in appointments:
            # If appointment date has passed and status is still 'upcoming', mark as 'missed'
            if appointment.status == 'upcoming' and appointment.appointment_date < now:
                appointment.status = 'missed'
                appointment.save()

        data = []
        for app in appointments:
            data.append({
                "appointment_id": app.appointment_id,
                "date": app.appointment_date,
                "slot_id": app.slot.slot_id,
                "staff_id": app.staff.staff_id,
                "patient_id": app.patient.patient_id,
                "status": app.status,
                "reason": app.reason
            })
        return Response(data, status=200)


# class AppointmentDetailView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def get(self, request, appointment_id):
#         appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
#         prescription = appointment.prescriptions.first()
#         prescription_data = None
#         if prescription:
#             prescription_data = {
#                 "prescription_id": prescription.prescription_id,
#                 "remarks": prescription.prescription_remarks,
#                 "medicines": [
#                     {
#                         "medicine_name": pm.medicine.medicine_name,
#                         "dosage": pm.medicine_dosage,
#                         "fasting_required": pm.fasting_required
#                     }
#                     for pm in prescription.prescribed_medicines.all()
#                 ]
#             }
#         data = {
#             "appointment_id": appointment.appointment_id,
#             "date": appointment.created_at.date(),
#             "slot_id": appointment.slot.slot_id,
#             "staff_id": appointment.staff.staff_id,
#             "patient_id": appointment.patient.patient_id,
#             "reason": appointment.reason,
#             "prescription": prescription_data
#         }
#         return Response(data, status=200)

class AppointmentDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, appointment_id):
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check if status needs updating (if it's 'upcoming' but date has passed)
        if appointment.status == 'upcoming' and appointment.created_at < timezone.now():
            appointment.status = 'missed'
            appointment.save()
            
        prescription = appointment.prescriptions.first()
        prescription_data = None
        if prescription:
            prescription_data = {
                "prescription_id": prescription.prescription_id,
                "remarks": prescription.prescription_remarks,
                "medicines": [
                    {
                        "medicine_name": pm.medicine.medicine_name,
                        "dosage": pm.medicine_dosage,
                        "fasting_required": pm.fasting_required
                    }
                    for pm in prescription.prescribed_medicines.all()
                ]
            }
            
        # Get diagnosis if it exists
        diagnosis = appointment.diagnoses.first()
        diagnosis_data = None
        if diagnosis:
            diagnosis_data = {
                "diagnosis_id": diagnosis.diagnosis_id,
                "diagnosis_data": diagnosis.diagnosis_data,
                "lab_test_required": diagnosis.lab_test_required,
                "follow_up_required": diagnosis.follow_up_required
            }
            
        data = {
            "appointment_id": appointment.appointment_id,
            "date": appointment.created_at.date(),
            "slot_id": appointment.slot.slot_id,
            "staff_id": appointment.staff.staff_id,
            "patient_id": appointment.patient.patient_id,
            "status": appointment.status,
            "reason": appointment.reason,
            "prescription": prescription_data,
            "diagnosis": diagnosis_data
        }
        return Response(data, status=200)

# class AllAppointmentsView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAdminStaff]  # Or doctor-specific permission

#     def get(self, request):
#         appointments = Appointment.objects.all()
#         data = [
#             {
#                 "appointment_id": app.appointment_id,
#                 "date": app.created_at.date(),
#                 "slot_id": app.slot.slot_id,
#                 "staff_id": app.staff.staff_id,
#                 "patient_id": app.patient.patient_id
#             }
#             for app in appointments
#         ]
#         return Response(data, status=200)

class AllAppointmentsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]  # Or doctor-specific permission

    def get(self, request):
        appointments = Appointment.objects.all()
        
        # Update statuses for appointments that should be marked as missed
        now = timezone.now()
        for appointment in appointments:
            if appointment.status == 'upcoming' and appointment.created_at < now:
                appointment.status = 'missed'
                appointment.save()
                
        data = [
            {
                "appointment_id": app.appointment_id,
                "date": app.created_at.date(),
                "slot_id": app.slot.slot_id,
                "staff_id": app.staff.staff_id,
                "patient_id": app.patient.patient_id,
                "status": app.status,
                "reason": app.reason
            }
            for app in appointments
        ]
        return Response(data, status=200)

class PatientDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        patient = get_object_or_404(Patient, patient_id=patient_id)
        try:
            details = patient.details
            data = {
                "patient_id": patient.patient_id,
                "patient_name": patient.patient_name,
                "patient_email": patient.patient_email,
                "patient_mobile": patient.patient_mobile,
                "dob": details.patient_dob,
                "gender": details.patient_gender,
                "blood_group": details.patient_blood_group,
                "address": details.patient_address,
                "profile_photo": request.build_absolute_uri(details.profile_photo.url) if details.profile_photo else None
            }
        except PatientDetails.DoesNotExist:
            data = {
                "patient_id": patient.patient_id,
                "patient_name": patient.patient_name,
                "patient_email": patient.patient_email,
                "patient_mobile": patient.patient_mobile
            }
        return Response(data, status=200)

class GetLatestPatientVitalsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        # Get the latest vitals for the patient
        latest_vitals = PatientVitals.objects.filter(patient_id=patient_id).order_by('-created_at').first()
        
        if not latest_vitals:
            return Response({"error": "No vitals found for this patient."}, status=status.HTTP_404_NOT_FOUND)

        data = {
            "patient_height": latest_vitals.patient_height,
            "patient_weight": latest_vitals.patient_weight,
            "patient_heartrate": latest_vitals.patient_heartrate,
            "patient_spo2": latest_vitals.patient_spo2,
            "patient_temperature": latest_vitals.patient_temperature,
            "created_at": latest_vitals.created_at,
            "appointment_id": latest_vitals.appointment_id.appointment_id
        }
        return Response(data, status=status.HTTP_200_OK)

class EnterPatientVitalsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, appointment_id):
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        data = request.data
        PatientVitals.objects.create(
            patient=appointment.patient,
            appointment_id=appointment,
            patient_height=data.get("height"),
            patient_weight=data.get("weight"),
            patient_heartrate=data.get("heartrate"),
            patient_spo2=data.get("spo2"),
            patient_temperature=data.get("temperature")
        )
        return Response({"message": "Vitals saved"}, status=201)

class MedicineListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        medicines = Medicine.objects.all()
        data = []
        for medicine in medicines:
            data.append({
                "medicine_id": medicine.medicine_id,
                "medicine_name": medicine.medicine_name,
                "medicine_remark": medicine.medicine_remark
            })
        return Response(data, status=status.HTTP_200_OK)
    
class SubmitPrescriptionView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, appointment_id):
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        remarks = request.data.get("remarks")
        medicines = request.data.get("medicines", [])
        prescription = Prescription.objects.create(
            appointment=appointment,
            prescription_remarks=remarks
        )
        prescription.save()


        for med in medicines:
            # Add this check before creating PrescribedMedicine
            if not isinstance(med["dosage"], dict):
                return Response({"error": "Dosage must be a JSON object"}, 
                    status=status.HTTP_400_BAD_REQUEST)
            try:
                medicine = Medicine.objects.get(medicine_id=med["medicine_id"])
            except Medicine.DoesNotExist:
                return Response({"error": f"Medicine with ID {med['medicine_id']} does not exist"}, 
                            status=status.HTTP_400_BAD_REQUEST)

            PrescribedMedicine.objects.create(
                prescription=prescription,
                medicine_id=med["medicine_id"],
                medicine_dosage=med["dosage"],
                fasting_required=med.get("fasting_required", False)
            )
        return Response({"message": "Prescription submitted"}, status=201)

class AssignDoctorShiftView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]#[IsAdminStaff]

    def post(self, request, staff_id):
        shift_id = request.data.get("shift_id")
        date_str = request.data.get("date")
        if not all([shift_id, date_str]):
            return Response({"error": "Missing fields"}, status=400)
        try:
            shift = Shift.objects.get(shift_id=shift_id)
            date = datetime.strptime(date_str, "%Y-%m-%d").date()
        except Shift.DoesNotExist:
            return Response({"error": "Invalid shift"}, status=400)
        Schedule.objects.create(
            staff_id=staff_id,
            shift=shift,
            schedule_date=date
        )
        return Response({"message": "Shift assigned"}, status=201)

class DoctorAllSlotsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, staff_id):
        schedules = Schedule.objects.filter(staff__staff_id=staff_id)
        slots = []
        for schedule in schedules:
            for slot in schedule.shift.slots.all():
                slots.append({
                    "slot_id": slot.slot_id,
                    "slot_start_time": slot.slot_start_time,
                    "slot_duration": slot.slot_duration,
                    "shift": schedule.shift.shift_name,
                    "date": schedule.schedule_date
                })
        return Response(slots, status=200)

class TargetOrganListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        organs = TargetOrgan.objects.all()
        data = [
            {
                "target_organ_id": organ.target_organ_id,
                "target_organ_name": organ.target_organ_name,
                "target_organ_remark": organ.target_organ_remark
            }
            for organ in organs
        ]
        return Response(data, status=status.HTTP_200_OK)
    
class DoctorScheduleView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, staff_id):
        # Get date range from query params
        start_date_str = request.GET.get('start_date')
        end_date_str = request.GET.get('end_date')
        
        if not start_date_str:
            # Default to current date if not provided
            start_date = datetime.now().date()
        else:
            try:
                start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
            except ValueError:
                return Response({"error": "Invalid start_date format. Use YYYY-MM-DD"}, status=400)
                
        if not end_date_str:
            # Default to 7 days from start_date if not provided
            end_date = start_date + timedelta(days=7)
        else:
            try:
                end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date()
            except ValueError:
                return Response({"error": "Invalid end_date format. Use YYYY-MM-DD"}, status=400)
                
        # Get all schedules for this doctor in the date range
        schedules = Schedule.objects.filter(
            staff__staff_id=staff_id,
            schedule_date__gte=start_date,
            schedule_date__lte=end_date
        ).order_by('schedule_date')
        
        # Get all appointments for this doctor in the date range
        appointments = Appointment.objects.filter(
            staff__staff_id=staff_id,
            created_at__date__gte=start_date,
            created_at__date__lte=end_date
        )
        
        # Organize appointments by date and slot
        appointment_map = {}
        for appointment in appointments:
            date_key = appointment.created_at.date().isoformat()
            slot_key = appointment.slot.slot_id
            
            if date_key not in appointment_map:
                appointment_map[date_key] = {}
                
            appointment_map[date_key][slot_key] = {
                "appointment_id": appointment.appointment_id,
                "patient_id": appointment.patient.patient_id,
                "patient_name": appointment.patient.patient_name,
                "status": appointment.status
            }
        
        # Build schedule data
        schedule_data = []
        for schedule in schedules:
            date_key = schedule.schedule_date.isoformat()
            shift_slots = []
            
            for slot in schedule.shift.slots.all():
                slot_data = {
                    "slot_id": slot.slot_id,
                    "start_time": slot.slot_start_time.strftime('%H:%M:%S'),
                    "duration": slot.slot_duration,
                    "is_booked": False
                }
                
                # Check if this slot has an appointment
                if date_key in appointment_map and slot.slot_id in appointment_map[date_key]:
                    slot_data["is_booked"] = True
                    slot_data["appointment"] = appointment_map[date_key][slot.slot_id]
                    
                shift_slots.append(slot_data)
                
            schedule_data.append({
                "date": date_key,
                "shift": {
                    "shift_id": schedule.shift.shift_id,
                    "shift_name": schedule.shift.shift_name,
                    "start_time": schedule.shift.start_time.strftime('%H:%M:%S'),
                    "end_time": schedule.shift.end_time.strftime('%H:%M:%S')
                },
                "slots": shift_slots
            })
            
        return Response(schedule_data, status=200)

class AllDoctorSchedulesView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request):
        # Get date from query params
        date_str = request.GET.get('date')
        
        if not date_str:
            # Default to current date if not provided
            date = datetime.now().date()
        else:
            try:
                date = datetime.strptime(date_str, "%Y-%m-%d").date()
            except ValueError:
                return Response({"error": "Invalid date format. Use YYYY-MM-DD"}, status=400)
                
        # Get all schedules for this date
        schedules = Schedule.objects.filter(schedule_date=date)
        
        # Get all appointments for this date
        appointments = Appointment.objects.filter(created_at__date=date)
        
        # Organize appointments by doctor and slot
        appointment_map = {}
        for appointment in appointments:
            doctor_key = appointment.staff.staff_id
            slot_key = appointment.slot.slot_id
            
            if doctor_key not in appointment_map:
                appointment_map[doctor_key] = {}
                
            appointment_map[doctor_key][slot_key] = {
                "appointment_id": appointment.appointment_id,
                "patient_id": appointment.patient.patient_id,
                "patient_name": appointment.patient.patient_name,
                "status": appointment.status
            }
        
        # Build schedule data
        schedule_data = []
        for schedule in schedules:
            doctor_key = schedule.staff.staff_id
            shift_slots = []
            
            for slot in schedule.shift.slots.all():
                slot_data = {
                    "slot_id": slot.slot_id,
                    "start_time": slot.slot_start_time.strftime('%H:%M:%S'),
                    "duration": slot.slot_duration,
                    "is_booked": False
                }
                
                # Check if this slot has an appointment
                if doctor_key in appointment_map and slot.slot_id in appointment_map[doctor_key]:
                    slot_data["is_booked"] = True
                    slot_data["appointment"] = appointment_map[doctor_key][slot.slot_id]
                    
                shift_slots.append(slot_data)
                
            schedule_data.append({
                "doctor": {
                    "staff_id": schedule.staff.staff_id,
                    "staff_name": schedule.staff.staff_name
                },
                "shift": {
                    "shift_id": schedule.shift.shift_id,
                    "shift_name": schedule.shift.shift_name,
                    "start_time": schedule.shift.start_time.strftime('%H:%M:%S'),
                    "end_time": schedule.shift.end_time.strftime('%H:%M:%S')
                },
                "slots": shift_slots
            })
            
        return Response(schedule_data, status=200)

class SetStaffScheduleView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Staff can only set their own schedule
        if not hasattr(request.user, 'staff_id'):
            return Response({"error": "Only staff can set schedules"}, status=403)
            
        staff = request.user
        shift_id = request.data.get("shift_id")
        date_str = request.data.get("date")
        
        if not all([shift_id, date_str]):
            return Response({"error": "Missing required fields"}, status=400)
            
        try:
            shift = Shift.objects.get(shift_id=shift_id)
            date = datetime.strptime(date_str, "%Y-%m-%d").date()
        except (Shift.DoesNotExist, ValueError):
            return Response({"error": "Invalid shift or date format"}, status=400)
            
        # Check if schedule already exists for this date
        if Schedule.objects.filter(staff=staff, schedule_date=date).exists():
            return Response({"error": "Schedule already exists for this date"}, status=409)
            
        # Create schedule
        schedule = Schedule.objects.create(
            staff=staff,
            shift=shift,
            schedule_date=date
        )
        
        return Response({
            "message": "Schedule set successfully",
            "schedule_id": schedule.schedule_id,
            "date": date.isoformat(),
            "shift": {
                "shift_id": shift.shift_id,
                "shift_name": shift.shift_name
            }
        }, status=201)

class SetStaffSlotsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def post(self, request):
        shift_id = request.data.get("shift_id")
        slots_data = request.data.get("slots", [])
        
        if not shift_id:
            return Response({"error": "Shift ID is required"}, status=400)
            
        try:
            shift = Shift.objects.get(shift_id=shift_id)
        except Shift.DoesNotExist:
            return Response({"error": "Invalid shift"}, status=400)
            
        # Delete existing slots for this shift
        Slot.objects.filter(shift=shift).delete()
        
        # Create new slots
        created_slots = []
        for slot_data in slots_data:
            start_time_str = slot_data.get("start_time")
            duration = slot_data.get("duration")
            remark = slot_data.get("remark", "")
            
            if not all([start_time_str, duration]):
                return Response({"error": "Each slot must have start_time and duration"}, status=400)
                
            try:
                # Parse time in format HH:MM:SS
                start_time = datetime.strptime(start_time_str, "%H:%M:%S").time()
                
                slot = Slot.objects.create(
                    slot_start_time=start_time,
                    slot_duration=duration,
                    shift=shift,
                    slot_remark=remark
                )
                
                created_slots.append({
                    "slot_id": slot.slot_id,
                    "start_time": slot.slot_start_time.strftime('%H:%M:%S'),
                    "duration": slot.slot_duration
                })
                
            except ValueError:
                return Response({"error": f"Invalid time format: {start_time_str}. Use HH:MM:SS"}, status=400)
        
        return Response({
            "message": f"Created {len(created_slots)} slots for shift {shift.shift_name}",
            "shift_id": shift.shift_id,
            "slots": created_slots
        }, status=201)

# class RecommendLabTestsView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def post(self, request, appointment_id):
#         # Check if user is a doctor
#         if not hasattr(request.user, 'staff_id'):
#             return Response({"error": "Only staff can recommend lab tests"}, status=403)
            
#         try:
#             doctor = request.user.doctor_details
#         except (AttributeError, DoctorDetails.DoesNotExist):
#             return Response({"error": "Only doctors can recommend lab tests"}, status=403)
            
#         # Get the appointment
#         appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
#         # Check if this doctor is assigned to this appointment
#         if appointment.staff.staff_id != request.user.staff_id:
#             return Response({"error": "You are not authorized to recommend tests for this appointment"}, status=403)
            
#         # Get lab tests data
#         lab_id = request.data.get("lab_id")
#         test_type_ids = request.data.get("test_type_ids", [])
#         priority = request.data.get("priority", "medium")
#         test_datetime_str = request.data.get("test_datetime")
        
#         if not all([lab_id, test_type_ids, test_datetime_str]):
#             return Response({"error": "Missing required fields"}, status=400)
            
#         try:
#             lab = Lab.objects.get(lab_id=lab_id)
#             test_datetime = datetime.strptime(test_datetime_str, "%Y-%m-%d %H:%M:%S")
#         except (Lab.DoesNotExist, ValueError):
#             return Response({"error": "Invalid lab or datetime format"}, status=400)
            
#         # Create lab tests
#         created_tests = []
#         for test_type_id in test_type_ids:
#             try:
#                 test_type = LabTestType.objects.get(test_type_id=test_type_id)
                
#                 lab_test = LabTest.objects.create(
#                     lab=lab,
#                     test_datetime=test_datetime,
#                     test_result=None,  # Will be filled by lab technician
#                     test_type=test_type,
#                     appointment=appointment,
#                     priority=priority
#                 )
                
#                 created_tests.append({
#                     "lab_test_id": lab_test.lab_test_id,
#                     "test_type": test_type.test_name
#                 })
                
#             except LabTestType.DoesNotExist:
#                 return Response({"error": f"Invalid test type ID: {test_type_id}"}, status=400)
        
#         # Update diagnosis to indicate lab tests are required
#         diagnosis = appointment.diagnoses.first()
#         if diagnosis:
#             diagnosis.lab_test_required = True
#             diagnosis.save()
        
#         return Response({
#             "message": f"Recommended {len(created_tests)} lab tests",
#             "lab_tests": created_tests
#         }, status=201)

# class RecommendLabTestsView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def post(self, request, appointment_id):
#         # Check if user is a doctor
#         if not hasattr(request.user, 'staff_id'):
#             return Response({"error": "Only staff can recommend lab tests"}, status=403)
            
#         try:
#             doctor = request.user.doctor_details
#         except (AttributeError, DoctorDetails.DoesNotExist):
#             return Response({"error": "Only doctors can recommend lab tests"}, status=403)
            
#         # Get the appointment
#         appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
#         # Check if this doctor is assigned to this appointment
#         if appointment.staff.staff_id != request.user.staff_id:
#             return Response({"error": "You are not authorized to recommend tests for this appointment"}, status=403)
            
#         # Get lab tests data
#         lab_type_id = request.data.get("lab_type_id")  # Now requiring lab_type instead of lab_id
#         test_type_ids = request.data.get("test_type_ids", [])
#         priority = request.data.get("priority", "medium")
#         test_datetime_str = request.data.get("test_datetime")
        
#         if not all([lab_type_id, test_type_ids, test_datetime_str]):
#             return Response({"error": "Missing required fields"}, status=400)
            
#         try:
#             # Get the lab type
#             lab_type = LabType.objects.get(lab_type_id=lab_type_id)
            
#             # Parse the datetime
#             test_datetime = datetime.strptime(test_datetime_str, "%Y-%m-%d %H:%M:%S")
            
#             # Check if datetime is in the future
#             if test_datetime < datetime.now():
#                 return Response({"error": "Test datetime must be in the future"}, status=400)
                
#         except LabType.DoesNotExist:
#             return Response({"error": "Invalid lab type"}, status=400)
#         except ValueError:
#             return Response({"error": "Invalid datetime format. Use YYYY-MM-DD HH:MM:SS"}, status=400)
            
#         # Find an available lab of the specified type
#         available_labs = Lab.objects.filter(lab_type=lab_type, functional=True)
        
#         if not available_labs.exists():
#             return Response({"error": f"No functional labs available for type: {lab_type.lab_type_name}"}, status=400)
            
#         # Simple load balancing - get the lab with the fewest tests scheduled for that time
#         # This is a basic implementation - in a real system, you might want more sophisticated scheduling
#         lab_loads = {}
#         for lab in available_labs:
#             # Count tests scheduled within 1 hour of the requested time
#             time_window_start = test_datetime - timedelta(hours=1)
#             time_window_end = test_datetime + timedelta(hours=1)
            
#             test_count = LabTest.objects.filter(
#                 lab=lab,
#                 test_datetime__gte=time_window_start,
#                 test_datetime__lte=time_window_end
#             ).count()
            
#             lab_loads[lab.lab_id] = test_count
            
#         # Find the lab with the minimum load
#         if lab_loads:
#             min_load_lab_id = min(lab_loads, key=lab_loads.get)
#             selected_lab = Lab.objects.get(lab_id=min_load_lab_id)
#         else:
#             # If no load data, just pick the first available lab
#             selected_lab = available_labs.first()
            
#         # Create lab tests
#         created_tests = []
#         for test_type_id in test_type_ids:
#             try:
#                 test_type = LabTestType.objects.get(test_type_id=test_type_id)
                
#                 # Check if this test type is compatible with the selected lab type
#                 if test_type.test_category.lab_type != lab_type:
#                     return Response({
#                         "error": f"Test type '{test_type.test_name}' is not compatible with lab type '{lab_type.lab_type_name}'"
#                     }, status=400)
                
#                 lab_test = LabTest.objects.create(
#                     lab=selected_lab,
#                     test_datetime=test_datetime,
#                     test_result=None,  # Will be filled by lab technician
#                     test_type=test_type,
#                     appointment=appointment,
#                     priority=priority
#                 )
                
#                 created_tests.append({
#                     "lab_test_id": lab_test.lab_test_id,
#                     "test_type": test_type.test_name,
#                     "lab_name": selected_lab.lab_name
#                 })
                
#             except LabTestType.DoesNotExist:
#                 return Response({"error": f"Invalid test type ID: {test_type_id}"}, status=400)
        
#         # Update diagnosis to indicate lab tests are required
#         diagnosis = appointment.diagnoses.first()
#         if diagnosis:
#             diagnosis.lab_test_required = True
#             diagnosis.save()
        
#         return Response({
#             "message": f"Recommended {len(created_tests)} lab tests",
#             "lab_tests": created_tests,
#             "selected_lab": {
#                 "lab_id": selected_lab.lab_id,
#                 "lab_name": selected_lab.lab_name,
#                 "lab_type": lab_type.lab_type_name
#             }
#         }, status=201)

class RecommendLabTestsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, appointment_id):
        # Check if user is a doctor
        if not hasattr(request.user, 'staff_id'):
            return Response({"error": "Only staff can recommend lab tests"}, status=403)
            
        try:
            doctor = request.user.doctor_details
        except (AttributeError, DoctorDetails.DoesNotExist):
            return Response({"error": "Only doctors can recommend lab tests"}, status=403)
            
        # Get the appointment
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check if this doctor is assigned to this appointment
        if appointment.staff.staff_id != request.user.staff_id:
            return Response({"error": "You are not authorized to recommend tests for this appointment"}, status=403)
            
        # Get lab tests data
        test_type_ids = request.data.get("test_type_ids", [])
        priority = request.data.get("priority", "medium")
        test_datetime_str = request.data.get("test_datetime")
        
        if not test_type_ids or not test_datetime_str:
            return Response({"error": "Missing required fields"}, status=400)
            
        try:
            # Parse the datetime
            test_datetime = datetime.strptime(test_datetime_str, "%Y-%m-%d %H:%M:%S")
            
            # Check if datetime is in the future
            if test_datetime < datetime.now():
                return Response({"error": "Test datetime must be in the future"}, status=400)
                
        except ValueError:
            return Response({"error": "Invalid datetime format. Use YYYY-MM-DD HH:MM:SS"}, status=400)
        
        # Get test types and verify they exist
        test_types = []
        for test_type_id in test_type_ids:
            try:
                test_type = LabTestType.objects.get(test_type_id=test_type_id)
                test_types.append(test_type)
            except LabTestType.DoesNotExist:
                return Response({"error": f"Invalid test type ID: {test_type_id}"}, status=400)
        
        # Find lab types that support these tests
        # Get all lab types
        lab_types = LabType.objects.all()
        
        # Map test types to lab types that support them
        test_to_lab_types = {}
        for test_type in test_types:
            supporting_lab_types = []
            for lab_type in lab_types:
                # Check if this test_type_id is in the supported_tests JSON field
                supported_tests = lab_type.supported_tests
                if str(test_type.test_type_id) in supported_tests or test_type.test_type_id in supported_tests:
                    supporting_lab_types.append(lab_type)
            
            if not supporting_lab_types:
                return Response({"error": f"No lab type supports test: {test_type.test_name}"}, status=400)
                
            test_to_lab_types[test_type.test_type_id] = supporting_lab_types
        
        # Group tests by lab type (prefer to keep tests together when possible)
        lab_type_to_tests = {}
        
        # First, try to find common lab types that support multiple tests
        for test_type in test_types:
            assigned = False
            for lab_type in test_to_lab_types[test_type.test_type_id]:
                # Check if this lab type already has tests assigned
                if lab_type in lab_type_to_tests:
                    lab_type_to_tests[lab_type].append(test_type)
                    assigned = True
                    break
            
            # If not assigned to an existing lab type, create a new entry
            if not assigned:
                lab_type = test_to_lab_types[test_type.test_type_id][0]  # Take the first supporting lab type
                lab_type_to_tests[lab_type] = [test_type]
        
        created_tests = []
        
        # Process each lab type separately
        for lab_type, tests_for_lab_type in lab_type_to_tests.items():
            # Find an available lab of this type
            available_labs = Lab.objects.filter(lab_type=lab_type, functional=True)
            
            if not available_labs.exists():
                return Response({"error": f"No functional labs available for type: {lab_type.lab_type_name}"}, status=400)
                
            # Simple load balancing - get the lab with the fewest tests scheduled for that time
            lab_loads = {}
            for lab in available_labs:
                # Count tests scheduled within 1 hour of the requested time
                time_window_start = test_datetime - timedelta(hours=1)
                time_window_end = test_datetime + timedelta(hours=1)
                
                test_count = LabTest.objects.filter(
                    lab=lab,
                    test_datetime__gte=time_window_start,
                    test_datetime__lte=time_window_end
                ).count()
                
                lab_loads[lab.lab_id] = test_count
                
            # Find the lab with the minimum load
            if lab_loads:
                min_load_lab_id = min(lab_loads, key=lab_loads.get)
                selected_lab = Lab.objects.get(lab_id=min_load_lab_id)
            else:
                # If no load data, just pick the first available lab
                selected_lab = available_labs.first()
                
            # Create lab tests for this lab type
            for test_type in tests_for_lab_type:
                lab_test = LabTest.objects.create(
                    lab=selected_lab,
                    test_datetime=test_datetime,
                    test_result=None,  # Will be filled by lab technician
                    test_type=test_type,
                    appointment=appointment,
                    priority=priority
                )
                
                created_tests.append({
                    "lab_test_id": lab_test.lab_test_id,
                    "test_type": test_type.test_name,
                    "lab_name": selected_lab.lab_name,
                    "lab_type": lab_type.lab_type_name
                })
        
        # Update diagnosis to indicate lab tests are required
        diagnosis = appointment.diagnoses.first()
        if diagnosis:
            diagnosis.lab_test_required = True
            diagnosis.save()
        
        return Response({
            "message": f"Recommended {len(created_tests)} lab tests",
            "lab_tests": created_tests
        }, status=201)


# class PayForLabTestsView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def post(self, request, lab_test_id):
#         # Check if user is a patient
#         if not hasattr(request.user, 'patient_id'):
#             return Response({"error": "Only patients can pay for lab tests"}, status=403)
            
#         patient = request.user
        
#         # Get the lab test
#         lab_test = get_object_or_404(LabTest, lab_test_id=lab_test_id)
        
#         # Check if this patient is authorized to pay for this test
#         if lab_test.appointment.patient.patient_id != patient.patient_id:
#             return Response({"error": "You are not authorized to pay for this test"}, status=403)
            
#         # Check if test is already paid for
#         if lab_test.tran:
#             return Response({"error": "This lab test is already paid for"}, status=400)
            
#         # Get payment details
#         payment_method_id = request.data.get("payment_method_id")
        
#         if not payment_method_id:
#             return Response({"error": "Payment method is required"}, status=400)
            
#         try:
#             payment_method = PaymentMethod.objects.get(payment_method_id=payment_method_id)
#             transaction_type = TransactionType.objects.get(transaction_type_name="payment")
#         except (PaymentMethod.DoesNotExist, TransactionType.DoesNotExist):
#             return Response({"error": "Invalid payment method or transaction type"}, status=400)
            
#         # Get lab test charge
#         try:
#             charge = LabTestCharge.objects.get(test=lab_test.test_type, is_active=True)
#         except LabTestCharge.DoesNotExist:
#             return Response({"error": "No charge found for this lab test"}, status=400)
            
#         # Create transaction
#         transaction = Transaction.objects.create(
#             transaction_reference=f"LABTEST-{uuid.uuid4().hex[:8].upper()}",
#             transaction_type=transaction_type,
#             payment_method=payment_method,
#             transaction_amount=charge.charge_amount,
#             transaction_unit=charge.charge_unit,
#             transaction_status="completed",  # Assuming payment is successful
#             patient=patient,
#             transaction_details={
#                 "lab_test_id": lab_test.lab_test_id,
#                 "test_type": lab_test.test_type.test_name,
#                 "lab": lab_test.lab.lab_name
#             }
#         )
        
#         # Update lab test with transaction
#         lab_test.tran = transaction
#         lab_test.save()
        
#         return Response({
#             "message": "Payment for lab test processed successfully",
#             "transaction_id": transaction.transaction_id,
#             "amount": f"{transaction.transaction_amount} {transaction.transaction_unit.unit_symbol}"
#         }, status=201)

class PayForLabTestsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, lab_test_id):
        # Check if user is a patient
        if not hasattr(request.user, 'patient_id'):
            return Response({"error": "Only patients can pay for lab tests"}, status=403)
            
        patient = request.user
        
        # Get the lab test
        lab_test = get_object_or_404(LabTest, lab_test_id=lab_test_id)
        
        # Check if this patient is authorized to pay for this test
        if lab_test.appointment.patient.patient_id != patient.patient_id:
            return Response({"error": "You are not authorized to pay for this test"}, status=403)
            
        # Check if test is already paid for
        if lab_test.tran:
            return Response({"error": "This lab test is already paid for"}, status=400)
            
        # Get payment details
        payment_method_id = request.data.get("payment_method_id")
        transaction_reference = request.data.get("transaction_reference")
        
        # Check required fields
        if not payment_method_id:
            return Response({"error": "Payment method is required"}, status=400)
            
        # Transaction reference is required for payment
        if not transaction_reference:
            return Response({"error": "Transaction reference is required"}, status=400)
            
        # Check if transaction reference is already used
        if Transaction.objects.filter(transaction_reference=transaction_reference).exists():
            return Response({"error": "Transaction reference already used"}, status=400)
            
        try:
            payment_method = PaymentMethod.objects.get(payment_method_id=payment_method_id)
            transaction_type = TransactionType.objects.get(transaction_type_name="Payment")
        except (PaymentMethod.DoesNotExist, TransactionType.DoesNotExist):
            return Response({"error": "Invalid payment method or transaction type"}, status=400)
            
        # Get lab test charge
        try:
            charge = LabTestCharge.objects.get(test=lab_test.test_type, is_active=True)
        except LabTestCharge.DoesNotExist:
            return Response({"error": "No charge found for this lab test"}, status=400)
            
        # Create transaction with the provided reference
        transaction = Transaction.objects.create(
            transaction_reference=transaction_reference,
            transaction_type=transaction_type,
            payment_method=payment_method,
            transaction_amount=charge.charge_amount,
            transaction_unit=charge.charge_unit,
            transaction_status="completed",  # Assuming payment is successful
            patient=patient,
            transaction_details={
                "lab_test_id": lab_test.lab_test_id,
                "test_type": lab_test.test_type.test_name,
                "lab": lab_test.lab.lab_name,
                "payment_gateway_response": request.data.get("payment_gateway_response", {})  # Optional additional payment details
            }
        )
        
        # Update lab test with transaction
        lab_test.tran = transaction
        lab_test.save()
        
        # Generate invoice for the lab test
        try:
            invoice_type = InvoiceType.objects.get(invoice_type_name='lab_test')
            
            # Calculate tax (assuming 5% tax)
            tax_rate = decimal.Decimal('0.05')
            subtotal = charge.charge_amount
            tax = subtotal * tax_rate
            total = subtotal + tax
            print(lab_test.test_datetime)
            # Create invoice
            # if lab_test.test_datetime:
            #     # Convert to string and fix timezone format if needed
            #     dt_str = str(lab_test.test_datetime)
            #     if '+00' in dt_str:
            #         dt_str = dt_str.replace('+00', '+0000')
                
            #     try:
            #         from datetime import datetime
            #         dt_obj = datetime.strptime(dt_str, '%Y-%m-%d %H:%M:%S%z')
            #         date_str = dt_obj.strftime('%Y-%m-%d')
            #     except Exception:
            #         # Fallback if parsing fails
            #         date_str = 'Unknown Date'
            # else:
            #     date_str = 'Unknown Date'

            # invoice_remark = f"Invoice for {lab_test.test_type.test_name} on {date_str}"
            #invoice_remark = "Invoice for Lab Test"

            # Then use invoice_remark in your Invoice.objects.create()

            invoice = Invoice.objects.create(
                tran=transaction,
                invoice_type=invoice_type,
                patient=patient,
                invoice_items=[lab_test.lab_test_id],
                invoice_subtotal=subtotal,
                invoice_tax=tax,
                invoice_total=total,
                invoice_unit=charge.charge_unit,
                invoice_status='paid',
                invoice_remark="Invoice for {lab_test.test_type.test_name} on {lab_test.test_datetime.strftime('%Y-%m-%d') if lab_test.test_datetime else 'Unknown Date'}"
            )
            
            return Response({
                "message": "Payment for lab test processed successfully",
                "transaction_id": transaction.transaction_id,
                "amount": f"{transaction.transaction_amount} {transaction.transaction_unit.unit_symbol}",
                "invoice_id": invoice.invoice_id,
                "invoice_number": invoice.invoice_number
            }, status=201)
            
        except Exception as e:
            # If invoice creation fails, still return success for the payment
            print(e)
            print(traceback.format_exc())
            return Response({
                "message": "Payment for lab test processed successfully, but invoice generation failed",
                "transaction_id": transaction.transaction_id,
                "amount": f"{transaction.transaction_amount} {transaction.transaction_unit.unit_symbol}",
                "error": str(e)
            }, status=201)

class AddLabTestResultsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def put(self, request, lab_test_id):
        # Check if user is a lab technician
        if not hasattr(request.user, 'staff_id'):
            return Response({"error": "Only staff can add lab test results"}, status=403)
            
        try:
            lab_tech = request.user.lab_tech_details
        except (AttributeError, LabTechnicianDetails.DoesNotExist):
            return Response({"error": "Only lab technicians can add lab test results"}, status=403)
            
        # Get the lab test
        lab_test = get_object_or_404(LabTest, lab_test_id=lab_test_id)
        
        # Check if test is paid for
        if not lab_test.tran:
            return Response({"error": "This lab test has not been paid for yet"}, status=400)
            
        # Get test results
        test_result = request.data.get("test_result", {})
        if isinstance(test_result, str):
            try:
                test_result = json.loads(test_result)
            except json.JSONDecodeError:
                return Response({"error": "Invalid JSON in test_result"}, status=400)
                
        # Handle test image if provided
        test_image = request.FILES.get('test_image')
        if lab_test.test_type.image_required and not test_image:
            return Response({"error": "Test image is required for this test type"}, status=400)
            
        # Update lab test
        lab_test.test_result = test_result
        if test_image:
            lab_test.test_image = test_image
        lab_test.save()
        
        return Response({
            "message": "Lab test results added successfully",
            "lab_test_id": lab_test.lab_test_id
        }, status=200)

class LabListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        labs = Lab.objects.filter(functional=True)
        serializer = LabSerializer(labs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class LabTestListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Optional filters
        lab_id = request.query_params.get('lab_id')
        test_type_id = request.query_params.get('test_type_id')

        queryset = LabTest.objects.all()
        if lab_id:
            queryset = queryset.filter(lab__lab_id=lab_id)
        if test_type_id:
            queryset = queryset.filter(test_type__test_type_id=test_type_id)

        serializer = LabTestSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
class PatientRecommendedLabTestsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        patient = request.user
        # Get recommended lab tests for this patient
        lab_tests = LabTest.objects.filter(appointment__patient=patient).order_by('-test_datetime')
        serializer = RecommendedLabTestSerializer(lab_tests, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
# class LabTechnicianAssignedPatientsView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         user = request.user
#         if not hasattr(user, 'staff_id'):
#             return Response({"error": "Only staff can access this endpoint"}, status=403)

#         # Get lab assigned to this lab technician
#         try:
#             lab_technician_details = user.lab_tech_details
#             assigned_lab = lab_technician_details.assigned_lab
#         except AttributeError:
#             return Response({"error": "Lab technician details not found"}, status=404)

#         # Filters
#         start_datetime_str = request.query_params.get('start_datetime')
#         end_datetime_str = request.query_params.get('end_datetime')

#         # Get lab tests for the assigned lab
#         lab_tests = LabTest.objects.filter(lab__lab_name=assigned_lab)

#         if start_datetime_str:
#             start_datetime = parse_datetime(start_datetime_str)
#             if start_datetime:
#                 lab_tests = lab_tests.filter(test_datetime__gte=start_datetime)

#         if end_datetime_str:
#             end_datetime = parse_datetime(end_datetime_str)
#             if end_datetime:
#                 lab_tests = lab_tests.filter(test_datetime__lte=end_datetime)

#         # Get distinct appointments from lab tests
#         appointment_ids = lab_tests.values_list('appointment_id', flat=True).distinct()
#         appointments = Appointment.objects.filter(appointment_id__in=appointment_ids)

#         serializer = AssignedPatientSerializer(appointments, many=True)
#         return Response(serializer.data, status=status.HTTP_200_OK)

class LabTechnicianAssignedPatientsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if not hasattr(user, 'staff_id'):
            return Response({"error": "Only staff can access this endpoint"}, status=403)

        # Get lab assigned to this lab technician
        try:
            lab_technician_details = user.lab_tech_details
            assigned_lab = lab_technician_details.assigned_lab
        except AttributeError:
            return Response({"error": "Lab technician details not found"}, status=404)

        # Filters
        start_datetime_str = request.query_params.get('start_datetime')
        end_datetime_str = request.query_params.get('end_datetime')

        # Get lab tests for the assigned lab
        lab_tests = LabTest.objects.filter(lab__lab_name=assigned_lab)

        if start_datetime_str:
            start_datetime = parse_datetime(start_datetime_str)
            if start_datetime:
                lab_tests = lab_tests.filter(test_datetime__gte=start_datetime)

        if end_datetime_str:
            end_datetime = parse_datetime(end_datetime_str)
            if end_datetime:
                lab_tests = lab_tests.filter(test_datetime__lte=end_datetime)

        # Get distinct appointments from lab tests
        appointment_ids = lab_tests.values_list('appointment_id', flat=True).distinct()
        appointments = Appointment.objects.filter(appointment_id__in=appointment_ids)

        # Create a map of appointment_id to lab tests
        from collections import defaultdict
        lab_tests_map = defaultdict(list)
        
        for lab_test in lab_tests:
            lab_tests_map[lab_test.appointment_id].append({
                "lab_test_id": lab_test.lab_test_id,
                "test_type": lab_test.test_type.test_name,
                "test_datetime": lab_test.test_datetime.isoformat() if lab_test.test_datetime else None,
                "priority": lab_test.priority,
                "test_result": lab_test.test_result,
                "is_paid": lab_test.tran is not None
            })

        # Serialize appointments
        appointment_data = AssignedPatientSerializer(appointments, many=True).data
        
        # Add lab tests to each appointment
        for appointment in appointment_data:
            appointment['lab_tests'] = lab_tests_map.get(appointment['appointment_id'], [])
            
        return Response(appointment_data, status=status.HTTP_200_OK)
