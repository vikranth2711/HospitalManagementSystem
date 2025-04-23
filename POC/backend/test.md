Below is a complete example of a Django project that implements REST APIs for the tables you provided (patients, staff, lab technicians, doctors, etc.) as well as an OTP‐based signup/login system. You can follow these steps to create, configure, and run the project.

──────────────────────────────
Step 1. Set Up Your Environment
──────────────────────────────
1. Create and activate a virtual environment (optional but recommended):

  $ python -m venv venv  
  $ source venv/bin/activate                            (Linux/Mac)  
  > venv\Scripts\activate                             (Windows)

2. Install Django and Django REST Framework:

  (venv) $ pip install django djangorestframework

──────────────────────────────
Step 2. Create the Project and Apps
──────────────────────────────
1. Start a new Django project (we’ll name it “healthcare_project”):

  (venv) $ django-admin startproject healthcare_project

2. Change directory and create two apps – one for accounts (OTP system) and one for all hospital-related models and APIs:
```
  (venv) $ cd healthcare_project  
  (venv) $ python manage.py startapp accounts  
  (venv) $ python manage.py startapp hospital
```
Your folder structure should look like this:
```
  healthcare_project/  
   manage.py  
   healthcare_project/  
    __init__.py  
    settings.py  
    urls.py  
    wsgi.py  
   accounts/  
    __init__.py  
    admin.py  
    apps.py  
    models.py  
    views.py  
    urls.py  
    migrations/ …  
   hospital/  
    __init__.py  
    admin.py  
    apps.py  
    models.py  
    serializers.py  
    views.py  
    urls.py  
    migrations/ …
```
──────────────────────────────
Step 3. Configure Settings
──────────────────────────────
Edit healthcare_project/settings.py and add the new apps and REST framework to INSTALLED_APPS. Also, configure your email (for example, using a dummy SMTP server for testing).

Example healthcare_project/settings.py (only the relevant parts are shown):

---------------------------------------------------------
```
# healthcare_project/settings.py

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'your-secret-key'  # Replace with a unique key

DEBUG = True

ALLOWED_HOSTS = []

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'accounts',
    'hospital',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'healthcare_project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'healthcare_project.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Email settings for sending OTP mails (for development, you may use the console backend)
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
# For a production SMTP server, you might set:
# EMAIL_HOST = 'smtp.gmail.com'
# EMAIL_PORT = 587
# EMAIL_HOST_USER = 'your-email@example.com'
# EMAIL_HOST_PASSWORD = 'your-email-password'
# EMAIL_USE_TLS = True

STATIC_URL = '/static/'
```
---------------------------------------------------------

──────────────────────────────
Step 4. Create Models, Serializers, Views, and URLs
──────────────────────────────
Below is the full code for each app.

──────────────────────────────
A. accounts App (OTP Functionality)
──────────────────────────────
1. accounts/models.py  
Create an EmailOTP model to store the OTPs.

---------------------------------------------------------
```
# accounts/models.py
from django.db import models

class EmailOTP(models.Model):
    email = models.EmailField(unique=True)
    otp = models.CharField(max_length=6)
    verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.email
```
---------------------------------------------------------

2. accounts/views.py  
Use the reference code you provided to implement OTP request and verification.

---------------------------------------------------------
# accounts/views.py
```
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
        from_email = settings.EMAIL_HOST_USER if hasattr(settings, "EMAIL_HOST_USER") else 'noreply@example.com'
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
```
---------------------------------------------------------

3. accounts/urls.py  
Map URL endpoints for OTP requests and verification.

---------------------------------------------------------
# accounts/urls.py
```
from django.urls import path
from .views import RequestOTP, VerifyOTP

urlpatterns = [
    path('request-otp/', RequestOTP.as_view(), name='request-otp'),
    path('verify-otp/', VerifyOTP.as_view(), name='verify-otp'),
]
```
---------------------------------------------------------

4. accounts/admin.py  
(Optional) Register your model so you can manage it via the Django admin.

---------------------------------------------------------
# accounts/admin.py
```
from django.contrib import admin
from .models import EmailOTP

admin.site.register(EmailOTP)
```
---------------------------------------------------------

──────────────────────────────
B. hospital App (Models and REST APIs)
──────────────────────────────
1. hospital/models.py  
Define your models corresponding to the provided tables.

---------------------------------------------------------
```
# hospital/models.py
from django.db import models

class Patient(models.Model):
    patient_id = models.AutoField(primary_key=True)
    patient_name = models.CharField(max_length=255)
    patient_email = models.EmailField()
    patient_mobile = models.CharField(max_length=20)
    patient_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.patient_name

class PatientDetails(models.Model):
    patient = models.OneToOneField(Patient, on_delete=models.CASCADE, related_name='details')
    patient_dob = models.DateField()
    patient_gender = models.BooleanField()
    patient_blood_group = models.CharField(max_length=5)

    def __str__(self):
        return f"Details for {self.patient.patient_name}"

class PatientVitals(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='vitals')
    patient_height = models.FloatField()
    patient_weight = models.FloatField()
    patient_heartrate = models.IntegerField()
    patient_spo2 = models.FloatField()
    patient_temperature = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Vitals for {self.patient.patient_name} at {self.created_at}"

class Role(models.Model):
    role_id = models.AutoField(primary_key=True)
    role_name = models.CharField(max_length=100)
    role_permissions = models.JSONField()

    def __str__(self):
        return self.role_name

class Staff(models.Model):
    staff_id = models.CharField(primary_key=True, max_length=50)
    staff_name = models.CharField(max_length=255)
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='staff')
    staff_joining_date = models.DateField()
    staff_email = models.EmailField()
    staff_mobile = models.CharField(max_length=20)

    def __str__(self):
        return self.staff_name

class StaffDetails(models.Model):
    staff = models.OneToOneField(Staff, on_delete=models.CASCADE, related_name='staff_details')
    staff_dob = models.DateField()
    staff_address = models.TextField()

    def __str__(self):
        return f"Details for {self.staff.staff_name}"

class LabTechnicianDetails(models.Model):
    staff = models.OneToOneField(Staff, on_delete=models.CASCADE, primary_key=True, related_name='lab_tech_details')
    certification = models.CharField(max_length=255)
    lab_experience_years = models.IntegerField()
    assigned_lab = models.CharField(max_length=255)

    def __str__(self):
        return f"Lab Technician: {self.staff.staff_name}"

class DoctorType(models.Model):
    doctor_type_id = models.AutoField(primary_key=True)
    doctor_type = models.CharField(max_length=100)

    def __str__(self):
        return self.doctor_type

class DoctorDetails(models.Model):
    staff = models.OneToOneField(Staff, on_delete=models.CASCADE, primary_key=True, related_name='doctor_details')
    doctor_specialization = models.CharField(max_length=255)
    doctor_license = models.CharField(max_length=255)
    doctor_experience_years = models.IntegerField()
    doctor_qualification = models.CharField(max_length=255)
    doctor_type = models.ForeignKey(DoctorType, on_delete=models.CASCADE, related_name='doctor_details')

    def __str__(self):
        return f"Doctor: {self.staff.staff_name}"

class DoctorConsultationHours(models.Model):
    consultation_id = models.AutoField(primary_key=True)
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='consultation_hours')
    day_of_week = models.CharField(max_length=20)
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_available = models.BooleanField(default=True)

    def __str__(self):
        return f"Consultation for {self.staff.staff_name} on {self.day_of_week}"
```
---------------------------------------------------------

2. hospital/serializers.py  
Create serializers for each model.

---------------------------------------------------------
```
# hospital/serializers.py
from rest_framework import serializers
from .models import (
    Patient, PatientDetails, PatientVitals, Role, Staff, StaffDetails,
    LabTechnicianDetails, DoctorType, DoctorDetails, DoctorConsultationHours
)

class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = '__all__'

class PatientDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientDetails
        fields = '__all__'

class PatientVitalsSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientVitals
        fields = '__all__'

class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = '__all__'

class StaffSerializer(serializers.ModelSerializer):
    class Meta:
        model = Staff
        fields = '__all__'

class StaffDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = StaffDetails
        fields = '__all__'

class LabTechnicianDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabTechnicianDetails
        fields = '__all__'

class DoctorTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorType
        fields = '__all__'

class DoctorDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorDetails
        fields = '__all__'

class DoctorConsultationHoursSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorConsultationHours
        fields = '__all__'
```
---------------------------------------------------------

3. hospital/views.py  
Create API viewsets for each model using DRF’s ModelViewSet.

---------------------------------------------------------
```
# hospital/views.py
from rest_framework import viewsets
from .models import (
    Patient, PatientDetails, PatientVitals, Role, Staff, StaffDetails,
    LabTechnicianDetails, DoctorType, DoctorDetails, DoctorConsultationHours
)
from .serializers import (
    PatientSerializer, PatientDetailsSerializer, PatientVitalsSerializer,
    RoleSerializer, StaffSerializer, StaffDetailsSerializer,
    LabTechnicianDetailsSerializer, DoctorTypeSerializer, DoctorDetailsSerializer,
    DoctorConsultationHoursSerializer
)

class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer

class PatientDetailsViewSet(viewsets.ModelViewSet):
    queryset = PatientDetails.objects.all()
    serializer_class = PatientDetailsSerializer

class PatientVitalsViewSet(viewsets.ModelViewSet):
    queryset = PatientVitals.objects.all()
    serializer_class = PatientVitalsSerializer

class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.all()
    serializer_class = RoleSerializer

class StaffViewSet(viewsets.ModelViewSet):
    queryset = Staff.objects.all()
    serializer_class = StaffSerializer

class StaffDetailsViewSet(viewsets.ModelViewSet):
    queryset = StaffDetails.objects.all()
    serializer_class = StaffDetailsSerializer

class LabTechnicianDetailsViewSet(viewsets.ModelViewSet):
    queryset = LabTechnicianDetails.objects.all()
    serializer_class = LabTechnicianDetailsSerializer

class DoctorTypeViewSet(viewsets.ModelViewSet):
    queryset = DoctorType.objects.all()
    serializer_class = DoctorTypeSerializer

class DoctorDetailsViewSet(viewsets.ModelViewSet):
    queryset = DoctorDetails.objects.all()
    serializer_class = DoctorDetailsSerializer

class DoctorConsultationHoursViewSet(viewsets.ModelViewSet):
    queryset = DoctorConsultationHours.objects.all()
    serializer_class = DoctorConsultationHoursSerializer
```
---------------------------------------------------------

4. hospital/urls.py  
Register these viewsets using a DRF router.

---------------------------------------------------------
```
# hospital/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PatientViewSet, PatientDetailsViewSet, PatientVitalsViewSet, RoleViewSet,
    StaffViewSet, StaffDetailsViewSet, LabTechnicianDetailsViewSet, DoctorTypeViewSet,
    DoctorDetailsViewSet, DoctorConsultationHoursViewSet
)

router = DefaultRouter()
router.register(r'patients', PatientViewSet)
router.register(r'patient-details', PatientDetailsViewSet)
router.register(r'patient-vitals', PatientVitalsViewSet)
router.register(r'roles', RoleViewSet)
router.register(r'staff', StaffViewSet)
router.register(r'staff-details', StaffDetailsViewSet)
router.register(r'lab-technicians', LabTechnicianDetailsViewSet)
router.register(r'doctor-types', DoctorTypeViewSet)
router.register(r'doctor-details', DoctorDetailsViewSet)
router.register(r'doctor-consultation-hours', DoctorConsultationHoursViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
```
---------------------------------------------------------

5. hospital/admin.py  
(Optional) Register hospital models in the admin interface.

---------------------------------------------------------
```
# hospital/admin.py
from django.contrib import admin
from .models import (
    Patient, PatientDetails, PatientVitals, Role, Staff, StaffDetails,
    LabTechnicianDetails, DoctorType, DoctorDetails, DoctorConsultationHours
)

admin.site.register(Patient)
admin.site.register(PatientDetails)
admin.site.register(PatientVitals)
admin.site.register(Role)
admin.site.register(Staff)
admin.site.register(StaffDetails)
admin.site.register(LabTechnicianDetails)
admin.site.register(DoctorType)
admin.site.register(DoctorDetails)
admin.site.register(DoctorConsultationHours)
```
---------------------------------------------------------

──────────────────────────────
Step 5. Configure Project URLs
──────────────────────────────
Edit the main urls.py file (healthcare_project/urls.py) to include the URLs for both apps.

---------------------------------------------------------
```
# healthcare_project/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.urls')),      # OTP signup/login endpoints
    path('api/hospital/', include('hospital.urls')),        # Hospital API endpoints
]
```
---------------------------------------------------------

──────────────────────────────
Step 6. Run Migrations and Start the Server
──────────────────────────────
1. Make migrations and migrate your database:

  (venv) $ python manage.py makemigrations  
  (venv) $ python manage.py migrate

2. Create a superuser (optional, to access the admin):

  (venv) $ python manage.py createsuperuser

3. Run the development server:

  (venv) $ python manage.py runserver

You should now be able to access:
 -  The Django admin at http://127.0.0.1:8000/admin/  
 -  OTP endpoints at http://127.0.0.1:8000/api/accounts/request-otp/ and …/verify-otp/  
 -  Hospital API endpoints prefixed with http://127.0.0.1:8000/api/hospital/

──────────────────────────────
Step 7. Testing the APIs
──────────────────────────────
You can test the APIs using tools such as Postman or cURL. For example, to request an OTP send a POST request with a JSON body:
  {
   "email": "user@example.com"
  }
Then verify the OTP similarly.

──────────────────────────────
Final Notes
──────────────────────────────
-  This example uses SQLite but you can configure any database in settings.py.
-  The Email OTP sending currently uses the console backend so email content will be printed to the console. For production, configure a real SMTP server.
-  You can extend the serializers and viewsets to include nested relationships or custom querysets as needed.
-  Since this is a backend API for a Swift app, you can now consume these endpoints from your mobile app.

This complete code and guide sets up the Django backend with REST APIs for your hospital system and an OTP signup/login system. Enjoy coding!
