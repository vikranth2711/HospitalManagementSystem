# hospital/serializers.py
from rest_framework import serializers
from .models import Lab, LabType

class LabTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabType
        fields = ['lab_type_id', 'lab_type_name']

class LabSerializer(serializers.ModelSerializer):
    lab_type_name = serializers.CharField(source='lab_type.lab_type_name', read_only=True)
    
    class Meta:
        model = Lab
        fields = ['lab_id', 'lab_name', 'lab_type', 'lab_type_name', 'functional']
