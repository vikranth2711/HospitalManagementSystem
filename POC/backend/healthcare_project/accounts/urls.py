# from django.urls import path
# from .views import RequestOTP, VerifyOTP

# urlpatterns = [
#     path('request-otp/', RequestOTP.as_view(), name='request-otp'),
#     path('verify-otp/', VerifyOTP.as_view(), name='verify-otp'),
# ]

# accounts/urls.py
from django.urls import path
from .views import RequestOTP, PatientSignup, UserLogin, VerifyOTP, CreateAdminStaffView, TokenRefreshView

urlpatterns = [
    path('request-otp/', RequestOTP.as_view(), name='request-otp'),
    path('verify-otp/', VerifyOTP.as_view(), name='verify-otp'),
    path('patient-signup/', PatientSignup.as_view(), name='patient-signup'),
    path('login/', UserLogin.as_view(), name='user-login'),
    path('create-admin/', CreateAdminStaffView.as_view(), name='create-admin'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]