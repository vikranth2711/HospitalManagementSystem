from django.urls import path
from . import views

urlpatterns = [
    # Existing URLs
    path('request-otp/', views.RequestOTP.as_view(), name='request-otp'),
    path('verify-otp/', views.VerifyOTP.as_view(), name='verify-otp'),
    path('patient-signup/', views.PatientSignup.as_view(), name='patient-signup'),
    #path('login/', views.UserLogin.as_view(), name='user-login'),
    #path('verify-login-otp/', views.VerifyLoginOTP.as_view(), name='verify-login-otp'),
    path('create-admin-staff/', views.CreateAdminStaffView.as_view(), name='create-admin-staff'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change-password'),
    
    # New multi-step registration URLs
    path('initiate-email-verification/', views.InitiateEmailVerification.as_view(), name='initiate-email-verification'),
    path('verify-email-create-patient/', views.VerifyEmailAndCreatePatient.as_view(), name='verify-email-create-patient'),
    path('complete-patient-profile/', views.CompletePatientProfile.as_view(), name='complete-patient-profile'),
    
    # New 2FA login URLs
    path('login/', views.UserLogin.as_view(), name='user-login'),
    path('verify-login-otp/', views.VerifyLoginOTP.as_view(), name='verify-login-otp'),

    # New URLs
    path('patient/profile/', views.PatientProfileView.as_view(), name='patient-profile'),
    path('patient/update-profile/', views.UpdatePatientProfileView.as_view(), name='update-patient-profile'),
    path('patient/update-photo/', views.UpdatePatientPhotoView.as_view(), name='update-patient-photo'),
]