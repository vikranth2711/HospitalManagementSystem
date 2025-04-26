from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from accounts.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated
from .models import (Staff, StaffDetails, DoctorDetails, LabTechnicianDetails, Role, DoctorType, 
                     Schedule, Appointment, Slot, PatientDetails, Patient, PatientVitals,
                     PrescribedMedicine, Prescription, Shift)
from .permissions import IsAdminStaff
import uuid
import datetime
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

from datetime import datetime

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
        slot_datetime = datetime.strptime(date, "%Y-%m-%d")
        if Appointment.objects.filter(
            staff=staff, slot=slot, created_at__date=slot_datetime
        ).exists():
            return Response({"error": "Slot already booked"}, status=409)

        appointment = Appointment.objects.create(
            patient=patient,
            staff=staff,
            slot=slot,
        )
        # Optionally, save the reason in a remark field or a related model
        appointment.patient.patient_remark = reason
        appointment.patient.save()
        return Response({"message": "Appointment booked", "appointment_id": appointment.appointment_id}, status=201)

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

        data = []
        for app in appointments:
            data.append({
                "appointment_id": app.appointment_id,
                "date": app.created_at.date(),
                "slot_id": app.slot.slot_id,
                "staff_id": app.staff.staff_id,
                "patient_id": app.patient.patient_id,
                "status": "completed" if app.created_at < datetime.now() else "upcoming"
            })
        return Response(data, status=200)

class AppointmentDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, appointment_id):
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
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
        data = {
            "appointment_id": appointment.appointment_id,
            "date": appointment.created_at.date(),
            "slot_id": appointment.slot.slot_id,
            "staff_id": appointment.staff.staff_id,
            "patient_id": appointment.patient.patient_id,
            "prescription": prescription_data
        }
        return Response(data, status=200)

class AllAppointmentsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]  # Or doctor-specific permission

    def get(self, request):
        appointments = Appointment.objects.all()
        data = [
            {
                "appointment_id": app.appointment_id,
                "date": app.created_at.date(),
                "slot_id": app.slot.slot_id,
                "staff_id": app.staff.staff_id,
                "patient_id": app.patient.patient_id
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
        for med in medicines:
            PrescribedMedicine.objects.create(
                prescription=prescription,
                medicine_id=med["medicine_id"],
                medicine_dosage=med["dosage"],
                fasting_required=med.get("fasting_required", False)
            )
        return Response({"message": "Prescription submitted"}, status=201)

class AssignDoctorShiftView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

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
