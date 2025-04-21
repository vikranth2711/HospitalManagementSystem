# accounts/urls.py
from django.urls import path
from .views import RequestOTP, VerifyOTP

urlpatterns = [
    path('send-otp/', RequestOTP.as_view(), name='send-otp'),
    path('verify-otp/', VerifyOTP.as_view(), name='verify-otp'),
]
