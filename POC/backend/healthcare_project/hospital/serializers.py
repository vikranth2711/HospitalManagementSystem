# hospital/serializers.py
from rest_framework import serializers
from .models import (
    Patient, PatientDetails, PatientVitals, Role, Staff, StaffDetails,
    LabTechnicianDetails, DoctorType, DoctorDetails, DoctorConsultationHours
)

class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = '__all__'

class PatientDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientDetails
        fields = '__all__'

class PatientVitalsSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientVitals
        fields = '__all__'

class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = '__all__'

class StaffSerializer(serializers.ModelSerializer):
    class Meta:
        model = Staff
        fields = '__all__'

class StaffDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = StaffDetails
        fields = '__all__'

class LabTechnicianDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabTechnicianDetails
        fields = '__all__'

class DoctorTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorType
        fields = '__all__'

class DoctorDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorDetails
        fields = '__all__'

class DoctorConsultationHoursSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorConsultationHours
        fields = '__all__'