from django.db import models
from django.utils import timezone

class Unit(models.Model):
    unit_id = models.AutoField(primary_key=True)
    unit_name = models.CharField(max_length=50)  # e.g., USD, EUR, INR
    unit_symbol = models.CharField(max_length=10)  # e.g., $, €, ₹
    unit_remark = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return f"{self.unit_name} ({self.unit_symbol})"
    
class TransactionType(models.Model):
    transaction_type_id = models.AutoField(primary_key=True)
    transaction_type_name = models.CharField(max_length=100)  # e.g., payment, refund
    transaction_type_remark = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return self.transaction_type_name

class PaymentMethod(models.Model):
    payment_method_id = models.AutoField(primary_key=True)
    payment_method_name = models.CharField(max_length=100)  # e.g., cash, credit card, UPI
    payment_method_remark = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return self.payment_method_name

class Transaction(models.Model):
    transaction_id = models.AutoField(primary_key=True)
    transaction_reference = models.CharField(max_length=100, null=True, blank=True, unique=True)  # External reference number
    transaction_datetime = models.DateTimeField(auto_now_add=True)
    transaction_type = models.ForeignKey(TransactionType, on_delete=models.PROTECT, related_name='transactions')
    #transaction_type = models.ForeignKey(TransactionType, null=True, blank=True, on_delete=models.PROTECT, related_name='transactions')
    payment_method = models.ForeignKey(PaymentMethod, on_delete=models.PROTECT, related_name='transactions')
    #payment_method = models.ForeignKey('transactions.PaymentMethod', on_delete=models.PROTECT, null=True, blank=True, related_name='transactions')
    transaction_amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_unit = models.ForeignKey(Unit, on_delete=models.PROTECT, related_name='transactions')
    transaction_status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded')
    ], default='pending')
    transaction_details = models.JSONField(null=True, blank=True, help_text='Additional payment details')
    patient = models.ForeignKey("hospital.Patient", on_delete=models.CASCADE, related_name='transactions')
    #patient = models.ForeignKey('hospital.Patient', on_delete=models.CASCADE, null=True, blank=True, related_name='transactions')
    transaction_remark = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Transaction {self.transaction_reference}: {self.transaction_amount} {self.transaction_unit.unit_symbol}"
    


class InvoiceType(models.Model):
    invoice_type_id = models.AutoField(primary_key=True)
    invoice_type_name = models.CharField(max_length=100)  # appointment or lab_test
    invoice_type_remark = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return self.invoice_type_name

class Invoice(models.Model):
    invoice_id = models.AutoField(primary_key=True)
    invoice_number = models.CharField(max_length=50, unique=True)  # Human-readable invoice number
    invoice_datetime = models.DateTimeField(auto_now_add=True)
    tran = models.ForeignKey(Transaction, on_delete=models.SET_NULL, null=True, blank=True, related_name='invoices')
    invoice_type = models.ForeignKey(InvoiceType, on_delete=models.PROTECT, related_name='invoices')
    patient = models.ForeignKey("hospital.Patient", on_delete=models.CASCADE, related_name='invoices')
    invoice_items = models.JSONField(help_text='List of charge IDs')
    invoice_subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    invoice_tax = models.DecimalField(max_digits=10, decimal_places=2)
    invoice_total = models.DecimalField(max_digits=10, decimal_places=2)
    invoice_unit = models.ForeignKey(Unit, on_delete=models.PROTECT, related_name='invoices')
    invoice_status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded')
    ], default='pending')
    invoice_remark = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Invoice #{self.invoice_number} - {self.invoice_total} {self.invoice_unit.unit_symbol}"
    
    def save(self, *args, **kwargs):
        # Generate invoice number if not provided
        if not self.invoice_number:
            # Format: INV-YYYYMMDD-XXXX where XXXX is a sequential number
            today = timezone.now().strftime('%Y%m%d')
            last_invoice = Invoice.objects.filter(invoice_number__startswith=f'INV-{today}').order_by('invoice_number').last()
            
            if last_invoice:
                # Extract the last sequence number and increment
                last_seq = int(last_invoice.invoice_number.split('-')[-1])
                new_seq = last_seq + 1
            else:
                new_seq = 1
                
            self.invoice_number = f'INV-{today}-{new_seq:04d}'
            
        super().save(*args, **kwargs)

