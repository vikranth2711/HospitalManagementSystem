# from django.urls import path
# from . import views
# from . import functional_views
# urlpatterns = [
#     # Staff URLs
#     path('staff/profile/', views.StaffProfileView.as_view(), name='staff-profile'),
#     path('admin/profile/', views.AdminProfileView.as_view(), name='admin-profile'),
    
#     # Lab Technician URLs
#     path('admin/lab-technicians/create/', views.CreateLabTechnicianView.as_view(), name='create-lab-technician'),
#     path('admin/lab-technicians/', views.LabTechnicianListView.as_view(), name='lab-technician-list'),
#     path('admin/lab-technicians/<str:staff_id>/', views.LabTechnicianDetailView.as_view(), name='lab-technician-detail'),
    
    
#     # Doctor URLs
#     path('admin/doctors/create/', views.CreateDoctorView.as_view(), name='create-doctor'),
#     path('admin/doctors/', views.DoctorListView.as_view(), name='doctor-list'),
#     path('admin/doctors/<str:staff_id>/', views.DoctorDetailView.as_view(), name='doctor-detail'),
    
#     # New Appointment System URLs
#     path('general/doctors/', functional_views.DoctorListView.as_view(), name='doctor-list'),
#     path('general/doctors/<str:staff_id>/', functional_views.DoctorDetailView.as_view(), name='doctor-detail'),
#     path('general/doctors/<str:staff_id>/slots/', functional_views.DoctorSlotsView.as_view(), name='doctor-slots'),
#     path('general/appointments/', functional_views.BookAppointmentView.as_view(), name='book-appointment'),
#     path('general/appointments/history/', functional_views.AppointmentHistoryView.as_view(), name='appointment-history'),
#     path('general/appointments/<int:appointment_id>/', functional_views.AppointmentDetailView.as_view(), name='appointment-detail'),
#     path('general/appointments/admin/', functional_views.AllAppointmentsView.as_view(), name='all-appointments'),
#     path('general/patients/<str:patient_id>/', functional_views.PatientDetailView.as_view(), name='patient-details'),
#     path('general/appointments/<int:appointment_id>/vitals/', functional_views.EnterPatientVitalsView.as_view(), name='enter-vitals'),
#     path('general/appointments/<int:appointment_id>/prescription/', functional_views.SubmitPrescriptionView.as_view(), name='submit-prescription'),
#     path('general/doctors/<str:staff_id>/shifts/', functional_views.AssignDoctorShiftView.as_view(), name='assign-shift'),
#     path('general/doctors/<str:staff_id>/all-slots/', functional_views.DoctorAllSlotsView.as_view(), name='doctor-all-slots'),

#     path('general/appointments/<int:appointment_id>/diagnosis/', functional_views.DiagnosisCreateView.as_view(), name='create-diagnosis'),
#     path('general/diagnosis/<int:diagnosis_id>/', functional_views.DiagnosisDetailView.as_view(), name='diagnosis-detail'),
    
#     # In your urls.py
#     path('general/patients/<int:patient_id>/latest-vitals/', functional_views.GetLatestPatientVitalsView.as_view(), name='latest-patient-vitals'),
#     path('general/shifts/', functional_views.ShiftListView.as_view(), name='shift-list'),
    
#     path('general/medicines/', functional_views.MedicineListView.as_view(), name='medicine-list'),
#     path('general/target-organs/', functional_views.TargetOrganListView.as_view(), name='target-organ-list'),
#     path('general/appointments/book-with-payment/', functional_views.BookAppointmentWithPaymentView.as_view(), name='book-appointment-with-payment'),
#     path('general/appointments/<int:appointment_id>/reschedule/', functional_views.RescheduleAppointmentView.as_view(), name='reschedule-appointment'),
    
#     # Schedule Management
#     path('general/doctors/<str:staff_id>/schedule/', functional_views.DoctorScheduleView.as_view(), name='doctor-schedule'),
#     path('general/doctors/schedules/', functional_views.AllDoctorSchedulesView.as_view(), name='all-doctor-schedules'),
#     path('general/staff/set-schedule/', functional_views.SetStaffScheduleView.as_view(), name='set-staff-schedule'),
#     path('general/admin/set-slots/', functional_views.SetStaffSlotsView.as_view(), name='set-staff-slots'),
    
#     # Lab Tests
#     path('general/appointments/<int:appointment_id>/recommend-lab-tests/', functional_views.RecommendLabTestsView.as_view(), name='recommend-lab-tests'),
#     path('general/lab-tests/<int:lab_test_id>/pay/', functional_views.PayForLabTestsView.as_view(), name='pay-for-lab-test'),
#     path('general/lab-tests/<int:lab_test_id>/results/', functional_views.AddLabTestResultsView.as_view(), name='add-lab-test-results'),

#     # Lab Test Type API
#     path('general/lab-test-types/', views.LabTestTypeListView.as_view(), name='lab-test-type-list'),
    
#     # Lab Management
#     path('admin/labs/', views.LabListCreateView.as_view(), name='lab-list-create'),
#     path('admin/labs/<int:lab_id>/', views.LabDetailView.as_view(), name='lab-detail'),

#     path('general/appointments/<int:appointment_id>/rating/', views.AppointmentRatingView.as_view(), name='appointment-rating'),
#     path('general/doctors/<str:staff_id>/ratings/', views.DoctorRatingsView.as_view(), name='doctor-ratings'),
#     path('general/patient/ratings/', views.PatientRatingsView.as_view(), name='patient-ratings'),

#     path('admin/lab-test-charges/', views.LabTestChargeListCreateView.as_view(), name='labtestcharge-list-create'),
#     path('admin/lab-test-charges/<int:test_charge_id>/', views.LabTestChargeDetailView.as_view(), name='labtestcharge-detail'),
#     path('admin/appointment-charges/', views.AppointmentChargeListCreateView.as_view(), name='appointmentcharge-list-create'),
#     path('admin/appointment-charges/<int:appointment_charge_id>/', views.AppointmentChargeDetailView.as_view(), name='appointmentcharge-detail'),
    
#     # Patient-facing APIs
#     path('general/doctors/<str:staff_id>/charge/', views.DoctorChargeView.as_view(), name='doctor-charge'),
#     path('general/lab-tests/<int:test_type_id>/charge/', views.LabTestChargeForPatientView.as_view(), name='lab-test-charge'),
#     path('general/lab-tests/charges/', views.AllLabTestChargesView.as_view(), name='all-lab-test-charges'),

#     # Doctor APIs
#     path('general/labs/', functional_views.LabListView.as_view(), name='lab-list'),
#     path('general/lab-tests/', functional_views.LabTestListView.as_view(), name='lab-test-list'),
    
#     # Patient APIs
#     path('general/patient/recommended-lab-tests/', functional_views.PatientRecommendedLabTestsView.as_view(), name='patient-recommended-lab-tests'),
    
#     # Lab Technician APIs
#     path('general/lab-technician/assigned-patients/', views.LabTechnicianAssignedPatientsView.as_view(), name='lab-tech-assigned-patients'),
# ]

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
    
    # Patient APIs
    path('general/patient/recommended-lab-tests/', functional_views.PatientRecommendedLabTestsView.as_view(), name='patient-recommended-lab-tests'),

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
    path('general/appointments/book-with-payment/', functional_views.BookAppointmentWithPaymentView.as_view(), name='book-appointment-with-payment'),
    path('general/appointments/<int:appointment_id>/reschedule/', functional_views.RescheduleAppointmentView.as_view(), name='reschedule-appointment'),
    
    # Schedule Management
    path('general/doctors/<str:staff_id>/schedule/', functional_views.DoctorScheduleView.as_view(), name='doctor-schedule'),
    path('general/doctors/schedules/', functional_views.AllDoctorSchedulesView.as_view(), name='all-doctor-schedules'),
    path('general/staff/set-schedule/', functional_views.SetStaffScheduleView.as_view(), name='set-staff-schedule'),
    path('general/admin/set-slots/', functional_views.SetStaffSlotsView.as_view(), name='set-staff-slots'),
    
    # Lab Tests
    path('general/appointments/<int:appointment_id>/recommend-lab-tests/', functional_views.RecommendLabTestsView.as_view(), name='recommend-lab-tests'),
    path('general/lab-tests/<int:lab_test_id>/pay/', functional_views.PayForLabTestsView.as_view(), name='pay-for-lab-test'),
    path('general/lab-tests/<int:lab_test_id>/results/', functional_views.AddLabTestResultsView.as_view(), name='add-lab-test-results'),
    path('general/lab-tests/<int:lab_test_id>/status/', functional_views.UpdateLabTestStatusView.as_view(), name='update-lab-test-status'),

    # Lab Test Type API
    path('general/lab-test-types/', views.LabTestTypeListView.as_view(), name='lab-test-type-list'),
    
    # Lab Management
    path('admin/labs/', views.LabListCreateView.as_view(), name='lab-list-create'),
    path('admin/labs/<int:lab_id>/', views.LabDetailView.as_view(), name='lab-detail'),

    path('general/appointments/<int:appointment_id>/rating/', views.AppointmentRatingView.as_view(), name='appointment-rating'),
    path('general/doctors/<str:staff_id>/ratings/', views.DoctorRatingsView.as_view(), name='doctor-ratings'),
    path('general/patient/ratings/', views.PatientRatingsView.as_view(), name='patient-ratings'),

    path('admin/lab-test-charges/', views.LabTestChargeListCreateView.as_view(), name='labtestcharge-list-create'),
    path('admin/lab-test-charges/<int:test_charge_id>/', views.LabTestChargeDetailView.as_view(), name='labtestcharge-detail'),
    path('admin/appointment-charges/', views.AppointmentChargeListCreateView.as_view(), name='appointmentcharge-list-create'),
    path('admin/appointment-charges/<int:appointment_charge_id>/', views.AppointmentChargeDetailView.as_view(), name='appointmentcharge-detail'),
    
    # Patient-facing APIs
    path('general/doctors/<str:staff_id>/charge/', views.DoctorChargeView.as_view(), name='doctor-charge'),
    path('general/lab-tests/<int:test_type_id>/charge/', views.LabTestChargeForPatientView.as_view(), name='lab-test-charge'),
    path('general/lab-tests/charges/', views.AllLabTestChargesView.as_view(), name='all-lab-test-charges'),

    # Doctor APIs
    path('general/labs/', functional_views.LabListView.as_view(), name='lab-list'),
    path('general/lab-tests/', functional_views.LabTestListView.as_view(), name='lab-test-list'),
    
    
    
    # Lab Technician APIs
    path('general/lab-technician/assigned-patients/', functional_views.LabTechnicianAssignedPatientsView.as_view(), name='lab-tech-assigned-patients'),
]