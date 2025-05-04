# transactions/serializers.py
from rest_framework import serializers
from .models import Invoice, InvoiceType, Transaction, Unit

class InvoiceSerializer(serializers.ModelSerializer):
    invoice_type_name = serializers.CharField(source='invoice_type.invoice_type_name', read_only=True)
    patient_name = serializers.CharField(source='patient.patient_name', read_only=True)
    unit_symbol = serializers.CharField(source='invoice_unit.unit_symbol', read_only=True)
    
    class Meta:
        model = Invoice
        fields = [
            'invoice_id', 'invoice_number', 'invoice_datetime', 
            'tran', 'invoice_type', 'invoice_type_name', 'patient', 'patient_name',
            'invoice_items', 'invoice_subtotal', 'invoice_tax', 'invoice_total',
            'invoice_unit', 'unit_symbol', 'invoice_status', 'invoice_remark'
        ]
        read_only_fields = ['invoice_id', 'invoice_number', 'invoice_datetime']
