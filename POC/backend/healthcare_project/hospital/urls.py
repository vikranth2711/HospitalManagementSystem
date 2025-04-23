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
# hospital/urls.py (add to existing urlpatterns)
from .views import PatientProfileView, StaffProfileView
from django.urls import path, include
urlpatterns = [
    # ... existing URLs
    path('patient-profile/', PatientProfileView.as_view(), name='patient-profile'),
    path('staff-profile/', StaffProfileView.as_view(), name='staff-profile'),
]