# hospital/serializers.py
from rest_framework import serializers
from .models import Lab, LabType, LabTestType, LabTestCategory, TargetOrgan

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
        fields = ['category_id', 'category_name']

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
