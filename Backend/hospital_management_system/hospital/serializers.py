# hospital/serializers.py
from rest_framework import serializers
from .models import Lab, LabType, LabTestType, LabTestCategory, TargetOrgan, AppointmentRating, AppointmentCharge, LabTestCharge

class LabTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabType
        fields = ['lab_type_id', 'lab_type_name']

class LabSerializer(serializers.ModelSerializer):
    lab_type_name = serializers.CharField(source='lab_type.lab_type_name', read_only=True)
    
    class Meta:
        model = Lab
        fields = ['lab_id', 'lab_name', 'lab_type', 'lab_type_name', 'functional']

class LabTestCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LabTestCategory
        fields = ['test_category_id', 'test_category_name']

class TargetOrganSerializer(serializers.ModelSerializer):
    class Meta:
        model = TargetOrgan
        fields = ['target_organ_id', 'target_organ_name']

class LabTestTypeSerializer(serializers.ModelSerializer):
    test_category = LabTestCategorySerializer(read_only=True)
    test_target_organ = TargetOrganSerializer(read_only=True)
    
    class Meta:
        model = LabTestType
        fields = [
            'test_type_id', 'test_name', 'test_schema', 
            'test_category', 'test_target_organ', 
            'image_required', 'test_remark'
        ]

class AppointmentRatingSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='appointment.patient.patient_name', read_only=True)
    doctor_name = serializers.CharField(source='appointment.staff.staff_name', read_only=True)
    appointment_date = serializers.DateField(source='appointment.appointment_date', read_only=True)
    
    class Meta:
        model = AppointmentRating
        fields = [
            'rating_id', 'appointment', 'rating', 'rating_comment',
            'patient_name', 'doctor_name', 'appointment_date'
        ]
        read_only_fields = ['rating_id']

class AppointmentChargeSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='doctor.staff_name', read_only=True)
    charge_unit_symbol = serializers.CharField(source='charge_unit.unit_symbol', read_only=True)

    class Meta:
        model = AppointmentCharge
        fields = ['appointment_charge_id', 'doctor', 'doctor_name', 'charge_amount', 
                  'charge_unit', 'charge_unit_symbol', 'charge_remark', 'is_active', 
                  'created_at', 'updated_at']
        read_only_fields = ['appointment_charge_id', 'created_at', 'updated_at']

class LabTestChargeSerializer(serializers.ModelSerializer):
    test_name = serializers.CharField(source='test.test_name', read_only=True)
    charge_unit_symbol = serializers.CharField(source='charge_unit.unit_symbol', read_only=True)

    class Meta:
        model = LabTestCharge
        fields = ['test_charge_id', 'test', 'test_name', 'charge_amount', 'charge_unit', 'charge_unit_symbol', 'charge_remark', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['test_charge_id', 'created_at', 'updated_at']