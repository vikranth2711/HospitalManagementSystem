from django.db import models

class EmailOTP(models.Model):
    USER_TYPE_CHOICES = [
        ('patient', 'Patient'),
        ('staff', 'Staff'),
    ]
    
    email = models.EmailField()
    otp = models.CharField(max_length=6)
    verified = models.BooleanField(default=False)
    user_type = models.CharField(max_length=10, choices=USER_TYPE_CHOICES, default='patient')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['email', 'user_type']
    
    def __str__(self):
        return f"{self.email} ({self.user_type})"