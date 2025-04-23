# from django.shortcuts import render

# # Create your views here.

# # hospital/views.py
from rest_framework import viewsets
from .models import (
    Patient, PatientDetails, PatientVitals, Role, Staff, StaffDetails,
    LabTechnicianDetails, DoctorType, DoctorDetails, DoctorConsultationHours
)
from .serializers import (
    PatientSerializer, PatientDetailsSerializer, PatientVitalsSerializer,
    RoleSerializer, StaffSerializer, StaffDetailsSerializer,
    LabTechnicianDetailsSerializer, DoctorTypeSerializer, DoctorDetailsSerializer,
    DoctorConsultationHoursSerializer
)

class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer

class PatientDetailsViewSet(viewsets.ModelViewSet):
    queryset = PatientDetails.objects.all()
    serializer_class = PatientDetailsSerializer

class PatientVitalsViewSet(viewsets.ModelViewSet):
    queryset = PatientVitals.objects.all()
    serializer_class = PatientVitalsSerializer

class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.all()
    serializer_class = RoleSerializer

class StaffViewSet(viewsets.ModelViewSet):
    queryset = Staff.objects.all()
    serializer_class = StaffSerializer

class StaffDetailsViewSet(viewsets.ModelViewSet):
    queryset = StaffDetails.objects.all()
    serializer_class = StaffDetailsSerializer

class LabTechnicianDetailsViewSet(viewsets.ModelViewSet):
    queryset = LabTechnicianDetails.objects.all()
    serializer_class = LabTechnicianDetailsSerializer

class DoctorTypeViewSet(viewsets.ModelViewSet):
    queryset = DoctorType.objects.all()
    serializer_class = DoctorTypeSerializer

class DoctorDetailsViewSet(viewsets.ModelViewSet):
    queryset = DoctorDetails.objects.all()
    serializer_class = DoctorDetailsSerializer

class DoctorConsultationHoursViewSet(viewsets.ModelViewSet):
    queryset = DoctorConsultationHours.objects.all()
    serializer_class = DoctorConsultationHoursSerializer

# hospital/views.py (add these views to the existing file)
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import Patient, Staff, PatientDetails, StaffDetails
from .serializers import PatientSerializer, StaffSerializer, PatientDetailsSerializer, StaffDetailsSerializer
from accounts.authentication import JWTAuthentication

class PatientProfileView(APIView):
    authentication_classes = [JWTAuthentication]
    
    def get(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Patient):
            return Response({"error": "Authentication required or invalid user type."},
                           status=status.HTTP_403_FORBIDDEN)
        
        patient = request.user
        patient_data = PatientSerializer(patient).data
        
        # Get patient details if available
        try:
            details = patient.details
            details_data = PatientDetailsSerializer(details).data
            patient_data.update({"details": details_data})
        except PatientDetails.DoesNotExist:
            patient_data.update({"details": None})
        
        return Response(patient_data, status=status.HTTP_200_OK)
    
    # def put(self, request, *args, **kwargs):
    #     if not hasattr(request, 'user') or not isinstance(request.user, Patient):
    #         return Response({"error": "Authentication required or invalid user type."},
    #                        status=status.HTTP_403_FORBIDDEN)
        
    #     patient = request.user
        
    #     # Update patient basic info
    #     for key, value in request.data.items():
    #         if key in ['patient_name', 'patient_mobile', 'patient_remark']:
    #             setattr(patient, key, value)
        
    #     patient.save()
        
    #     # Handle patient details
    #     details_data = request.data.get('details', {})
    #     if details_data:
    #         details, created = PatientDetails.objects.get_or_create(patient=patient)
            
    #         for key, value in details_data.items():
    #             if key in ['patient_dob', 'patient_gender', 'patient_blood_group']:
    #                 setattr(details, key, value)
            
    #         details.save()
        
    #     return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)
    def put(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Patient):
            return Response({"error": "Authentication required or invalid user type."},
                        status=status.HTTP_403_FORBIDDEN)
        
        patient = request.user
        
        # Update patient basic info
        for key, value in request.data.items():
            if key in ['patient_name', 'patient_mobile', 'patient_remark']:
                setattr(patient, key, value)
        
        patient.save()
        
        # Handle patient details
        details_data = request.data.get('details', {})
        if details_data and all(k in details_data for k in ['patient_dob', 'patient_gender', 'patient_blood_group']):
            try:
                # Try to get existing details
                details = PatientDetails.objects.get(patient=patient)
                
                # Update existing details
                for key, value in details_data.items():
                    if key in ['patient_dob', 'patient_gender', 'patient_blood_group']:
                        setattr(details, key, value)
                
                details.save()
            except PatientDetails.DoesNotExist:
                # Create new details with all required fields
                PatientDetails.objects.create(
                    patient=patient,
                    patient_dob=details_data.get('patient_dob'),
                    patient_gender=details_data.get('patient_gender'),
                    patient_blood_group=details_data.get('patient_blood_group')
                )
        
        return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)

class StaffProfileView(APIView):
    authentication_classes = [JWTAuthentication]
    
    def get(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Staff):
            return Response({"error": "Authentication required or invalid user type."},
                           status=status.HTTP_403_FORBIDDEN)
        
        staff = request.user
        staff_data = StaffSerializer(staff).data
        
        # Get staff details if available
        try:
            details = staff.staff_details
            details_data = StaffDetailsSerializer(details).data
            staff_data.update({"details": details_data})
        except StaffDetails.DoesNotExist:
            staff_data.update({"details": None})
        
        return Response(staff_data, status=status.HTTP_200_OK)
    
    # def put(self, request, *args, **kwargs):
    #     if not hasattr(request, 'user') or not isinstance(request.user, Staff):
    #         return Response({"error": "Authentication required or invalid user type."},
    #                        status=status.HTTP_403_FORBIDDEN)
        
    #     staff = request.user
        
    #     # Update staff basic info (limited fields)
    #     for key, value in request.data.items():
    #         if key in ['staff_name', 'staff_mobile']:
    #             setattr(staff, key, value)
        
    #     staff.save()
        
    #     # Handle staff details
    #     details_data = request.data.get('details', {})
    #     if details_data:
    #         details, created = StaffDetails.objects.get_or_create(staff=staff)
            
    #         for key, value in details_data.items():
    #             if key in ['staff_address']:
    #                 setattr(details, key, value)
            
    #         details.save()
        
    #     return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)
    def put(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Staff):
            return Response({"error": "Authentication required or invalid user type."},
                        status=status.HTTP_403_FORBIDDEN)
        
        staff = request.user
        
        # Update staff basic info (limited fields)
        for key, value in request.data.items():
            if key in ['staff_name', 'staff_mobile']:
                setattr(staff, key, value)
        
        staff.save()
        
        # Handle staff details
        details_data = request.data.get('details', {})
        if details_data and all(k in details_data for k in ['staff_dob', 'staff_address']):
            try:
                # Try to get existing details
                details = StaffDetails.objects.get(staff=staff)
                
                # Update existing details
                for key, value in details_data.items():
                    if key in ['staff_dob', 'staff_address']:
                        setattr(details, key, value)
                
                details.save()
            except StaffDetails.DoesNotExist:
                # Create new details with all required fields
                StaffDetails.objects.create(
                    staff=staff,
                    staff_dob=details_data.get('staff_dob'),
                    staff_address=details_data.get('staff_address')
                )
        
        return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)