from django.db import models

# Create your models here.
class Transaction(models.Model):
    TRAN_MODE_CHOICES = [
        ('UPI', 'UPI'),
        ('Credit', 'Credit'),
        ('Debit', 'Debit'),
    ]
    TRAN_STATUS_CHOICES = [
        ('success', 'Success'),
        ('failure', 'Failure'),
        ('pending', 'Pending'),
    ]

    tran_id = models.AutoField(primary_key=True)
    tran_mode = models.CharField(max_length=10, choices=TRAN_MODE_CHOICES)
    tran_time = models.DateTimeField()
    tran_status = models.CharField(max_length=10, choices=TRAN_STATUS_CHOICES)
    tran_remarks = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Transaction {self.tran_id} - {self.tran_status}"

    class Meta:
        db_table = 'transactions'