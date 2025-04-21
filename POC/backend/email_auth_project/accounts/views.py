# Create your views here.
# accounts/views.py
import random, string
from django.core.mail import send_mail
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import EmailOTP

def generate_otp(length=6):
    """Generate a random OTP consisting of digits."""
    return ''.join(random.choices(string.digits, k=length))

class RequestOTP(APIView):
    def post(self, request, *args, **kwargs):
        email = request.data.get("email")
        if not email:
            return Response({"error": "Email is required."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        otp = generate_otp()
        
        # Update or create OTP record for the email
        otp_record, created = EmailOTP.objects.update_or_create(
            email=email,
            defaults={'otp': otp, 'verified': False}
        )
        
        subject = "Your Verification OTP"
        message = f"Your OTP for email verification is: {otp}"
        from_email = settings.EMAIL_HOST_USER
        recipient_list = [email]
        
        try:
            send_mail(subject, message, from_email, recipient_list, fail_silently=False)
        except Exception as e:
            return Response({"error": "Failed to send email.", "details": str(e)},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({"message": "OTP sent successfully."},
                        status=status.HTTP_200_OK)

class VerifyOTP(APIView):
    def post(self, request, *args, **kwargs):
        email = request.data.get("email")
        otp_provided = request.data.get("otp")
        
        if not email or not otp_provided:
            return Response({"error": "Email and OTP are required."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        try:
            otp_record = EmailOTP.objects.get(email=email)
        except EmailOTP.DoesNotExist:
            return Response({"error": "OTP not requested for this email."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        if otp_record.otp == otp_provided:
            otp_record.verified = True
            otp_record.save()
            return Response({"message": "OTP verified successfully."},
                            status=status.HTTP_200_OK)
        else:
            return Response({"error": "Invalid OTP."},
                            status=status.HTTP_400_BAD_REQUEST)
