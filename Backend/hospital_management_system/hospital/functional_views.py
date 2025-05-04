from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from accounts.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated
from .models import (Staff, StaffDetails, DoctorDetails, LabTechnicianDetails, Role, DoctorType, 
                     Schedule, Appointment, Slot, PatientDetails, Patient, PatientVitals,
                     PrescribedMedicine, Prescription, Shift, Diagnosis, Medicine,
                     TargetOrgan, AppointmentCharge, LabTestType, LabTest, Lab, LabTestCharge)
from .permissions import IsAdminStaff
import uuid
import datetime
from transactions.models import Transaction, PaymentMethod, TransactionType, Unit
import json

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
            staff=staff, slot=slot, created_at__date=appointment_date
        ).exists():
            return Response({"error": "Slot already booked"}, status=409)

        appointment = Appointment.objects.create(
            patient=patient,
            staff=staff,
            slot=slot,
            reason=reason,
            status='upcoming'
        )
        
        return Response({
            "message": "Appointment booked", 
            "appointment_id": appointment.appointment_id
        }, status=201)

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

        if not all([date, staff_id, slot_id, reason, payment_method_id]):
            return Response({"error": "Missing required fields"}, status=400)

        try:
            slot = Slot.objects.get(slot_id=slot_id)
            staff = Staff.objects.get(staff_id=staff_id)
            payment_method = PaymentMethod.objects.get(payment_method_id=payment_method_id)
            transaction_type = TransactionType.objects.get(transaction_type_name="payment")
            default_unit = Unit.objects.get(unit_name="USD")  # Adjust as needed
        except (Slot.DoesNotExist, Staff.DoesNotExist, PaymentMethod.DoesNotExist, 
                TransactionType.DoesNotExist, Unit.DoesNotExist) as e:
            return Response({"error": f"Invalid reference: {str(e)}"}, status=400)

        # Check if slot is available
        try:
            appointment_date = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "Invalid date format. Use YYYY-MM-DD"}, status=400)
            
        if Appointment.objects.filter(
            staff=staff, slot=slot, created_at__date=appointment_date
        ).exists():
            return Response({"error": "Slot already booked"}, status=409)

        # Get appointment charge for this doctor
        try:
            charge = AppointmentCharge.objects.get(doctor=staff, is_active=True)
        except AppointmentCharge.DoesNotExist:
            return Response({"error": "No appointment charge set for this doctor"}, status=400)

        # Create transaction
        transaction = Transaction.objects.create(
            transaction_reference=f"APP-{uuid.uuid4().hex[:8].upper()}",
            transaction_type=transaction_type,
            payment_method=payment_method,
            transaction_amount=charge.charge_amount,
            transaction_unit=charge.charge_unit,
            transaction_status="completed",  # Assuming payment is successful
            patient=patient,
            transaction_details={"appointment_date": date, "doctor": staff.staff_name}
        )

        # Create appointment
        appointment = Appointment.objects.create(
            patient=patient,
            staff=staff,
            slot=slot,
            tran=transaction,
            charge=charge,
            reason=reason,
            status='upcoming'
        )
        
        return Response({
            "message": "Appointment booked and payment processed", 
            "appointment_id": appointment.appointment_id,
            "transaction_id": transaction.transaction_id
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

class DiagnosisCreateView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

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
                
        lab_test_required = request.data.get("lab_test_required", "false").lower() == "true"
        follow_up_required = request.data.get("follow_up_required", "false").lower() == "true"
        
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
        now = timezone.now()
        for appointment in appointments:
            # If appointment date has passed and status is still 'upcoming', mark as 'missed'
            appointment_datetime = appointment.created_at
            if appointment.status == 'upcoming' and appointment_datetime < now:
                appointment.status = 'missed'
                appointment.save()

        data = []
        for app in appointments:
            data.append({
                "appointment_id": app.appointment_id,
                "date": app.created_at.date(),
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
        lab_id = request.data.get("lab_id")
        test_type_ids = request.data.get("test_type_ids", [])
        priority = request.data.get("priority", "medium")
        test_datetime_str = request.data.get("test_datetime")
        
        if not all([lab_id, test_type_ids, test_datetime_str]):
            return Response({"error": "Missing required fields"}, status=400)
            
        try:
            lab = Lab.objects.get(lab_id=lab_id)
            test_datetime = datetime.strptime(test_datetime_str, "%Y-%m-%d %H:%M:%S")
        except (Lab.DoesNotExist, ValueError):
            return Response({"error": "Invalid lab or datetime format"}, status=400)
            
        # Create lab tests
        created_tests = []
        for test_type_id in test_type_ids:
            try:
                test_type = LabTestType.objects.get(test_type_id=test_type_id)
                
                lab_test = LabTest.objects.create(
                    lab=lab,
                    test_datetime=test_datetime,
                    test_result=None,  # Will be filled by lab technician
                    test_type=test_type,
                    appointment=appointment,
                    priority=priority
                )
                
                created_tests.append({
                    "lab_test_id": lab_test.lab_test_id,
                    "test_type": test_type.test_name
                })
                
            except LabTestType.DoesNotExist:
                return Response({"error": f"Invalid test type ID: {test_type_id}"}, status=400)
        
        # Update diagnosis to indicate lab tests are required
        diagnosis = appointment.diagnoses.first()
        if diagnosis:
            diagnosis.lab_test_required = True
            diagnosis.save()
        
        return Response({
            "message": f"Recommended {len(created_tests)} lab tests",
            "lab_tests": created_tests
        }, status=201)

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
        
        if not payment_method_id:
            return Response({"error": "Payment method is required"}, status=400)
            
        try:
            payment_method = PaymentMethod.objects.get(payment_method_id=payment_method_id)
            transaction_type = TransactionType.objects.get(transaction_type_name="payment")
        except (PaymentMethod.DoesNotExist, TransactionType.DoesNotExist):
            return Response({"error": "Invalid payment method or transaction type"}, status=400)
            
        # Get lab test charge
        try:
            charge = LabTestCharge.objects.get(test=lab_test.test_type, is_active=True)
        except LabTestCharge.DoesNotExist:
            return Response({"error": "No charge found for this lab test"}, status=400)
            
        # Create transaction
        transaction = Transaction.objects.create(
            transaction_reference=f"LABTEST-{uuid.uuid4().hex[:8].upper()}",
            transaction_type=transaction_type,
            payment_method=payment_method,
            transaction_amount=charge.charge_amount,
            transaction_unit=charge.charge_unit,
            transaction_status="completed",  # Assuming payment is successful
            patient=patient,
            transaction_details={
                "lab_test_id": lab_test.lab_test_id,
                "test_type": lab_test.test_type.test_name,
                "lab": lab_test.lab.lab_name
            }
        )
        
        # Update lab test with transaction
        lab_test.tran = transaction
        lab_test.save()
        
        return Response({
            "message": "Payment for lab test processed successfully",
            "transaction_id": transaction.transaction_id,
            "amount": f"{transaction.transaction_amount} {transaction.transaction_unit.unit_symbol}"
        }, status=201)

class AddLabTestResultsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

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

