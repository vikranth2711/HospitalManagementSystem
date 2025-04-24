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
# from .views import PatientProfileView, StaffProfileView
# from django.urls import path, include
# urlpatterns = [
#     # ... existing URLs
#     path('patient-profile/', PatientProfileView.as_view(), name='patient-profile'),
#     path('staff-profile/', StaffProfileView.as_view(), name='staff-profile'),
# ]
# hospital/urls.py (update your existing urlpatterns)
from .views import (PatientProfileView, StaffProfileView, 
                    DoctorManagementView, LabTechManagementView, RoleManagementView)
from .views import (StaffManagementView, DoctorCreationView, LabTechnicianCreationView)

urlpatterns = [
    # ... existing URLs
    path('patient-profile/', PatientProfileView.as_view(), name='patient-profile'),
    path('staff-profile/', StaffProfileView.as_view(), name='staff-profile'),
    
    # Doctor management endpoints
    path('doctors/', DoctorManagementView.as_view(), name='doctors-list'),
    path('doctors/<str:doctor_id>/', DoctorManagementView.as_view(), name='doctor-detail'),
    
    # Lab Technician management endpoints
    path('lab-techs/', LabTechManagementView.as_view(), name='lab-techs-list'),
    path('lab-techs/<str:tech_id>/', LabTechManagementView.as_view(), name='lab-tech-detail'),
    path('roles/', RoleManagementView.as_view(), name='roles-list'),
    path('roles/<int:role_id>/', RoleManagementView.as_view(), name='role-detail'),
    path('admin/staff/create/', StaffManagementView.as_view(), name='create-staff'),
    path('admin/doctors/create/', DoctorCreationView.as_view(), name='create-doctor'),
    path('admin/lab-techs/create/', LabTechnicianCreationView.as_view(), name='create-lab-tech'),
    path('admin/staff/', StaffManagementView.as_view(), name='staff-list'),
    path('admin/staff/<str:staff_id>/', StaffManagementView.as_view(), name='staff-detail'),
]