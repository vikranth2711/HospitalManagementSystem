from . import views
# Add to hospital/urls.py
from django.urls import path


urlpatterns = [
    # ... existing URLs ...
    
    # Analytics APIs
    path('admin/analytics/revenue/', views.RevenueAnalyticsView.as_view(), name='revenue-analytics'),
    path('admin/analytics/ratings/', views.RatingAnalyticsView.as_view(), name='rating-analytics'),
    path('admin/analytics/appointments/', views.AppointmentAnalyticsView.as_view(), name='appointment-analytics'),
    path('admin/analytics/doctor-specializations/', views.DoctorSpecializationAnalyticsView.as_view(), name='doctor-specialization-analytics'),
]
