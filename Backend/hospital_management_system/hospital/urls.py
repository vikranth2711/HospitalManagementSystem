from django.urls import path
from . import views

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
    
]