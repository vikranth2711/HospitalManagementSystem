from django.urls import path
from . import views

urlpatterns = [
    # Invoice endpoints
    path('invoices/', views.InvoiceListView.as_view(), name='invoice-list'),
    path('invoices/<int:invoice_id>/', views.InvoiceDetailView.as_view(), name='invoice-detail'),
    path('invoices/<int:invoice_id>/status/', views.UpdateInvoiceStatusView.as_view(), name='update-invoice-status'),
    path('invoices/<int:invoice_id>/pdf/', views.GenerateInvoicePDFView.as_view(), name='generate-invoice-pdf'),
    path('patients/<int:patient_id>/invoices/', views.PatientInvoicesView.as_view(), name='patient-invoices'),
    path('appointments/<int:appointment_id>/generate-invoice/', views.GenerateAppointmentInvoiceView.as_view(), name='generate-appointment-invoice'),
    path('lab-tests/<int:lab_test_id>/generate-invoice/', views.GenerateLabTestInvoiceView.as_view(), name='generate-lab-test-invoice'),
    path('lab-tests/generate-multiple-invoice/', views.GenerateMultipleLabTestsInvoiceView.as_view(), name='generate-multiple-lab-tests-invoice'),
]
