from django.urls import path
from . import views

urlpatterns = [
    # Existing URLs
    path('request-otp/', views.RequestOTP.as_view(), name='request-otp'),
    path('verify-otp/', views.VerifyOTP.as_view(), name='verify-otp'),
    path('patient-signup/', views.PatientSignup.as_view(), name='patient-signup'),
    path('login/', views.UserLogin.as_view(), name='user-login'),
    path('create-admin-staff/', views.CreateAdminStaffView.as_view(), name='create-admin-staff'),
    
    # New URLs
    path('patient/profile/', views.PatientProfileView.as_view(), name='patient-profile'),
    path('patient/update-profile/', views.UpdatePatientProfileView.as_view(), name='update-patient-profile'),
    path('patient/update-photo/', views.UpdatePatientPhotoView.as_view(), name='update-patient-photo'),
]