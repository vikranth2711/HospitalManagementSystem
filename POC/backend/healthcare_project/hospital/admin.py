from django.contrib import admin

# Register your models here.
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