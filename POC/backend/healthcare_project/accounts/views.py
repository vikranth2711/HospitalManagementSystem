# from django.shortcuts import render

# # Create your views here.
# import random, string
# from django.core.mail import send_mail
# from django.conf import settings
# from rest_framework.views import APIView
# from rest_framework.response import Response
# from rest_framework import status
# from .models import EmailOTP

# def generate_otp(length=6):
#     """Generate a random OTP consisting of digits."""
#     return ''.join(random.choices(string.digits, k=length))

# class RequestOTP(APIView):
#     def post(self, request, *args, **kwargs):
#         email = request.data.get("email")
#         if not email:
#             return Response({"error": "Email is required."},
#                             status=status.HTTP_400_BAD_REQUEST)
        
#         otp = generate_otp()
        
#         # Update or create OTP record for the email
#         otp_record, created = EmailOTP.objects.update_or_create(
#             email=email,
#             defaults={'otp': otp, 'verified': False}
#         )
        
#         subject = "Your Verification OTP"
#         message = f"Your OTP for email verification is: {otp}"
#         from_email = settings.EMAIL_HOST_USER if hasattr(settings, "EMAIL_HOST_USER") else 'noreply@example.com'
#         recipient_list = [email]
        
#         try:
#             send_mail(subject, message, from_email, recipient_list, fail_silently=False)
#         except Exception as e:
#             return Response({"error": "Failed to send email.", "details": str(e)},
#                             status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
#         return Response({"message": "OTP sent successfully."},
#                         status=status.HTTP_200_OK)

# accounts/views.py
import random, string
from django.core.mail import send_mail
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import EmailOTP
from hospital.models import Patient, Staff
from rest_framework_simplejwt.tokens import RefreshToken
import json

def generate_otp(length=6):
    """Generate a random OTP consisting of digits."""
    return ''.join(random.choices(string.digits, k=length))

class RequestOTP(APIView):
    def post(self, request, *args, **kwargs):
        email = request.data.get("email")
        user_type = request.data.get("user_type", "patient")  # Default to patient
        
        if not email:
            return Response({"error": "Email is required."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        # For staff login, verify email exists in the system
        if user_type == 'staff':
            if not Staff.objects.filter(staff_email=email).exists():
                return Response({"error": "Staff email not found in the system."},
                                status=status.HTTP_404_NOT_FOUND)
        
        otp = generate_otp()
        
        # Update or create OTP record for the email and user type
        otp_record, created = EmailOTP.objects.update_or_create(
            email=email,
            user_type=user_type,
            defaults={'otp': otp, 'verified': False}
        )
        
        subject = "Your Verification OTP"
        message = f"Your OTP for email verification is: {otp}"
        from_email = settings.EMAIL_HOST_USER if hasattr(settings, "EMAIL_HOST_USER") else 'noreply@example.com'
        recipient_list = [email]
        
        try:
            send_mail(subject, message, from_email, recipient_list, fail_silently=False)
        except Exception as e:
            return Response({"error": "Failed to send email.", "details": str(e)},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({"message": "OTP sent successfully."},
                        status=status.HTTP_200_OK)

class PatientSignup(APIView):
    def post(self, request, *args, **kwargs):
        email = request.data.get("email")
        otp_provided = request.data.get("otp")
        patient_name = request.data.get("patient_name")
        patient_mobile = request.data.get("patient_mobile")
        
        if not all([email, otp_provided, patient_name, patient_mobile]):
            return Response({"error": "Email, OTP, name and mobile are required."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        # Check if patient already exists
        if Patient.objects.filter(patient_email=email).exists():
            return Response({"error": "Patient with this email already exists."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        # Verify OTP
        try:
            otp_record = EmailOTP.objects.get(email=email, user_type='patient')
        except EmailOTP.DoesNotExist:
            return Response({"error": "OTP not requested for this email."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        if otp_record.otp != otp_provided:
            return Response({"error": "Invalid OTP."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        # Create new patient
        patient = Patient.objects.create(
            patient_name=patient_name,
            patient_email=email,
            patient_mobile=patient_mobile
        )
        
        # Mark OTP as verified
        otp_record.verified = True
        otp_record.save()
        
        # Generate tokens
        refresh = RefreshToken()
        refresh['user_id'] = patient.patient_id
        refresh['user_type'] = 'patient'
        refresh['email'] = email
        
        return Response({
            "message": "Patient registered successfully.",
            "patient_id": patient.patient_id,
            "access_token": str(refresh.access_token),
            "refresh_token": str(refresh)
        }, status=status.HTTP_201_CREATED)

class UserLogin(APIView):
    def post(self, request, *args, **kwargs):
        email = request.data.get("email")
        otp_provided = request.data.get("otp")
        user_type = request.data.get("user_type", "patient")
        
        if not email or not otp_provided:
            return Response({"error": "Email and OTP are required."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        # Verify user exists
        if user_type == 'patient':
            try:
                user = Patient.objects.get(patient_email=email)
                user_id = user.patient_id
            except Patient.DoesNotExist:
                return Response({"error": "Patient not found."},
                                status=status.HTTP_404_NOT_FOUND)
        else:  # staff
            try:
                user = Staff.objects.get(staff_email=email)
                user_id = user.staff_id
            except Staff.DoesNotExist:
                return Response({"error": "Staff not found."},
                                status=status.HTTP_404_NOT_FOUND)
        
        # Verify OTP
        try:
            otp_record = EmailOTP.objects.get(email=email, user_type=user_type)
        except EmailOTP.DoesNotExist:
            return Response({"error": "OTP not requested for this email."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        if otp_record.otp != otp_provided:
            return Response({"error": "Invalid OTP."},
                            status=status.HTTP_400_BAD_REQUEST)
        
        # Mark OTP as verified
        otp_record.verified = True
        otp_record.save()
        
        # Generate tokens
        refresh = RefreshToken()
        refresh['user_id'] = user_id
        refresh['user_type'] = user_type
        refresh['email'] = email
        
        return Response({
            "message": "Login successful.",
            "user_id": user_id,
            "user_type": user_type,
            "access_token": str(refresh.access_token),
            "refresh_token": str(refresh)
        }, status=status.HTTP_200_OK)
    
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