from django.urls import path
from . import views
from . import functional_views
urlpatterns = [
    # Staff URLs
    path('staff/profile/', views.StaffProfileView.as_view(), name='staff-profile'),
    path('admin/profile/', views.AdminProfileView.as_view(), name='admin-profile'),
    
    # Lab Technician URLs
    path('admin/lab-technicians/create/', views.CreateLabTechnicianView.as_view(), name='create-lab-technician'),
    path('admin/lab-technicians/', views.LabTechnicianListView.as_view(), name='lab-technician-list'),
    path('admin/lab-technicians/<str:staff_id>/', views.LabTechnicianDetailView.as_view(), name='lab-technician-detail'),
    
    
    # Doctor URLs
    path('admin/doctors/create/', views.CreateDoctorView.as_view(), name='create-doctor'),
    path('admin/doctors/', views.DoctorListView.as_view(), name='doctor-list'),
    path('admin/doctors/<str:staff_id>/', views.DoctorDetailView.as_view(), name='doctor-detail'),
    
    # New Appointment System URLs
    path('general/doctors/', functional_views.DoctorListView.as_view(), name='doctor-list'),
    path('general/doctors/<str:staff_id>/', functional_views.DoctorDetailView.as_view(), name='doctor-detail'),
    path('general/doctors/<str:staff_id>/slots/', functional_views.DoctorSlotsView.as_view(), name='doctor-slots'),
    path('general/appointments/', functional_views.BookAppointmentView.as_view(), name='book-appointment'),
    path('general/appointments/history/', functional_views.AppointmentHistoryView.as_view(), name='appointment-history'),
    path('general/appointments/<int:appointment_id>/', functional_views.AppointmentDetailView.as_view(), name='appointment-detail'),
    path('general/appointments/admin/', functional_views.AllAppointmentsView.as_view(), name='all-appointments'),
    path('general/patients/<str:patient_id>/', functional_views.PatientDetailView.as_view(), name='patient-details'),
    path('general/appointments/<int:appointment_id>/vitals/', functional_views.EnterPatientVitalsView.as_view(), name='enter-vitals'),
    path('general/appointments/<int:appointment_id>/prescription/', functional_views.SubmitPrescriptionView.as_view(), name='submit-prescription'),
    path('general/doctors/<str:staff_id>/shifts/', functional_views.AssignDoctorShiftView.as_view(), name='assign-shift'),
    path('general/doctors/<str:staff_id>/all-slots/', functional_views.DoctorAllSlotsView.as_view(), name='doctor-all-slots'),

    path('general/appointments/<int:appointment_id>/diagnosis/', functional_views.DiagnosisCreateView.as_view(), name='create-diagnosis'),
    path('general/diagnosis/<int:diagnosis_id>/', functional_views.DiagnosisDetailView.as_view(), name='diagnosis-detail'),
    
    # In your urls.py
    path('general/patients/<int:patient_id>/latest-vitals/', functional_views.GetLatestPatientVitalsView.as_view(), name='latest-patient-vitals'),
    path('general/shifts/', functional_views.ShiftListView.as_view(), name='shift-list'),
    
    path('general/medicines/', functional_views.MedicineListView.as_view(), name='medicine-list'),
    path('general/target-organs/', functional_views.TargetOrganListView.as_view(), name='target-organ-list'),
    # # Staff Management URLs (existing)
    # path('api/staff/profile/', views.StaffProfileView.as_view(), name='staff-profile'),
    # path('api/admin/profile/', views.AdminProfileView.as_view(), name='admin-profile'),
    # path('api/lab-technicians/', views.LabTechnicianListView.as_view(), name='lab-tech-list'),
    # path('api/lab-technicians/<str:staff_id>/', views.LabTechnicianDetailView.as_view(), name='lab-tech-detail'),
]