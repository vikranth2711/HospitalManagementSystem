from django.shortcuts import render
from accounts.authentication import JWTAuthentication
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from django.utils import timezone
from datetime import timedelta
from django.db.models import Sum
from hospital.permissions import IsAdminStaff
from transactions.models import Transaction
from hospital.models import Appointment, AppointmentRating, Staff, Patient
from django.db.models import Avg, Count
# Create your views here.
class RevenueAnalyticsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request):
        # Get time period from query params (default to last 30 days)
        period = request.query_params.get('period', 'month')
        
        # Calculate date range based on period
        today = timezone.now().date()
        if period == 'week':
            start_date = today - timedelta(days=7)
        elif period == 'month':
            start_date = today - timedelta(days=30)
        elif period == 'year':
            start_date = today - timedelta(days=365)
        else:
            return Response({"error": "Invalid period"}, status=400)
            
        # Get all completed transactions in the period
        transactions = Transaction.objects.filter(
            transaction_datetime__date__gte=start_date,
            transaction_datetime__date__lte=today,
            transaction_status='completed'
        )
        
        # Calculate total revenue
        total_revenue = transactions.aggregate(
            total=Sum('transaction_amount')
        )['total'] or 0
        
        # Group by date for historical data
        historical_data = []
        
        # Group by day, week, or month depending on period
        if period == 'week':
            # Daily data for week view
            for i in range(7):
                date = today - timedelta(days=i)
                daily_revenue = transactions.filter(
                    transaction_datetime__date=date
                ).aggregate(total=Sum('transaction_amount'))['total'] or 0
                
                historical_data.append({
                    'date': date.isoformat(),
                    'revenue': daily_revenue
                })
        elif period == 'month':
            # Weekly data for month view
            for i in range(4):
                week_end = today - timedelta(days=i*7)
                week_start = week_end - timedelta(days=6)
                weekly_revenue = transactions.filter(
                    transaction_datetime__date__gte=week_start,
                    transaction_datetime__date__lte=week_end
                ).aggregate(total=Sum('transaction_amount'))['total'] or 0
                
                historical_data.append({
                    'period': f"{week_start.isoformat()} to {week_end.isoformat()}",
                    'revenue': weekly_revenue
                })
        else:
            # Monthly data for year view
            for i in range(12):
                month_end = today.replace(day=1) - timedelta(days=1)
                month_end = month_end.replace(month=month_end.month-i if month_end.month > i else 12-(i-month_end.month))
                month_start = month_end.replace(day=1)
                
                monthly_revenue = transactions.filter(
                    transaction_datetime__date__gte=month_start,
                    transaction_datetime__date__lte=month_end
                ).aggregate(total=Sum('transaction_amount'))['total'] or 0
                
                historical_data.append({
                    'month': month_start.strftime('%B %Y'),
                    'revenue': monthly_revenue
                })
        
        # Reverse to get chronological order
        historical_data.reverse()
        
        return Response({
            'total_revenue': total_revenue,
            'period': period,
            'historical_data': historical_data
        }, status=200)

class RatingAnalyticsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request):
        # Get time period from query params
        period = request.query_params.get('period', 'month')
        
        # Calculate date range
        today = timezone.now().date()
        if period == 'week':
            start_date = today - timedelta(days=7)
        elif period == 'month':
            start_date = today - timedelta(days=30)
        elif period == 'year':
            start_date = today - timedelta(days=365)
        else:
            return Response({"error": "Invalid period"}, status=400)
            
        # Get all ratings in the period
        ratings = AppointmentRating.objects.filter(
            appointment__created_at__date__gte=start_date,
            appointment__created_at__date__lte=today
        )
        
        # Calculate average rating
        avg_rating = ratings.aggregate(avg=Avg('rating'))['avg'] or 0
        
        # Rating distribution
        rating_distribution = {
            '5': ratings.filter(rating=5).count(),
            '4': ratings.filter(rating=4).count(),
            '3': ratings.filter(rating=3).count(),
            '2': ratings.filter(rating=2).count(),
            '1': ratings.filter(rating=1).count()
        }
        
        # Top rated doctors
        top_doctors = Staff.objects.filter(
            appointments__ratings__isnull=False
        ).annotate(
            avg_rating=Avg('appointments__ratings__rating'),
            rating_count=Count('appointments__ratings')
        ).filter(
            rating_count__gte=5  # Minimum 5 ratings
        ).order_by('-avg_rating')[:5]
        
        top_doctors_data = [{
            'staff_id': doctor.staff_id,
            'staff_name': doctor.staff_name,
            'avg_rating': doctor.avg_rating,
            'rating_count': doctor.rating_count
        } for doctor in top_doctors]
        
        # Historical rating data
        historical_data = []
        
        # Group by appropriate time period
        if period == 'week':
            for i in range(7):
                date = today - timedelta(days=i)
                daily_ratings = ratings.filter(
                    appointment__created_at__date=date
                )
                avg = daily_ratings.aggregate(avg=Avg('rating'))['avg'] or 0
                
                historical_data.append({
                    'date': date.isoformat(),
                    'avg_rating': avg,
                    'count': daily_ratings.count()
                })
        elif period == 'month':
            for i in range(4):
                week_end = today - timedelta(days=i*7)
                week_start = week_end - timedelta(days=6)
                weekly_ratings = ratings.filter(
                    appointment__created_at__date__gte=week_start,
                    appointment__created_at__date__lte=week_end
                )
                avg = weekly_ratings.aggregate(avg=Avg('rating'))['avg'] or 0
                
                historical_data.append({
                    'period': f"{week_start.isoformat()} to {week_end.isoformat()}",
                    'avg_rating': avg,
                    'count': weekly_ratings.count()
                })
        else:
            for i in range(12):
                month_end = today.replace(day=1) - timedelta(days=1)
                month_end = month_end.replace(month=month_end.month-i if month_end.month > i else 12-(i-month_end.month))
                month_start = month_end.replace(day=1)
                
                monthly_ratings = ratings.filter(
                    appointment__created_at__date__gte=month_start,
                    appointment__created_at__date__lte=month_end
                )
                avg = monthly_ratings.aggregate(avg=Avg('rating'))['avg'] or 0
                
                historical_data.append({
                    'month': month_start.strftime('%B %Y'),
                    'avg_rating': avg,
                    'count': monthly_ratings.count()
                })
        
        historical_data.reverse()
        
        return Response({
            'average_rating': avg_rating,
            'total_ratings': ratings.count(),
            'rating_distribution': rating_distribution,
            'top_rated_doctors': top_doctors_data,
            'historical_data': historical_data
        }, status=200)

class DoctorSpecializationAnalyticsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request):
        # Get all doctors with their specializations
        doctors = Staff.objects.filter(doctor_details__isnull=False)
        
        # Count doctors by specialization
        specialization_counts = {}
        for doctor in doctors:
            specialization = doctor.doctor_details.doctor_specialization
            if specialization in specialization_counts:
                specialization_counts[specialization] += 1
            else:
                specialization_counts[specialization] = 1
        
        # Convert to list for response
        specialization_data = [
            {'specialization': spec, 'count': count}
            for spec, count in specialization_counts.items()
        ]
        
        # Sort by count (descending)
        specialization_data.sort(key=lambda x: x['count'], reverse=True)
        
        # Get appointment distribution by specialization
        appointment_distribution = []
        for spec in specialization_counts.keys():
            spec_doctors = doctors.filter(doctor_details__doctor_specialization=spec)
            spec_doctor_ids = spec_doctors.values_list('staff_id', flat=True)
            
            appointment_count = Appointment.objects.filter(
                staff__staff_id__in=spec_doctor_ids
            ).count()
            
            appointment_distribution.append({
                'specialization': spec,
                'appointment_count': appointment_count
            })
        
        # Sort by appointment count (descending)
        appointment_distribution.sort(key=lambda x: x['appointment_count'], reverse=True)
        
        return Response({
            'total_doctors': doctors.count(),
            'specialization_distribution': specialization_data,
            'appointment_distribution': appointment_distribution
        }, status=200)

class AppointmentAnalyticsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request):
        period = request.query_params.get('period', 'month')
        
        today = timezone.now().date()
        if period == 'week':
            start_date = today - timedelta(days=7)
        elif period == 'month':
            start_date = today - timedelta(days=30)
        elif period == 'year':
            start_date = today - timedelta(days=365)
        else:
            return Response({"error": "Invalid period"}, status=400)
            
        # Get appointments in the period
        appointments = Appointment.objects.filter(
            appointment_date__gte=start_date,
            appointment_date__lte=today
        )
        
        # Total appointments
        total_appointments = appointments.count()
        
        # Get total number of patients in the database
        total_patients = Patient.objects.count()

        # Appointments by status
        status_distribution = {
            'upcoming': appointments.filter(status='upcoming').count(),
            'completed': appointments.filter(status='completed').count(),
            'missed': appointments.filter(status='missed').count()
        }
        
        # Historical booking data
        historical_data = []
        
        if period == 'week':
            for i in range(7):
                date = today - timedelta(days=i)
                daily_count = appointments.filter(appointment_date=date).count()
                
                historical_data.append({
                    'date': date.isoformat(),
                    'count': daily_count
                })
        elif period == 'month':
            for i in range(4):
                week_end = today - timedelta(days=i*7)
                week_start = week_end - timedelta(days=6)
                weekly_count = appointments.filter(
                    appointment_date__gte=week_start,
                    appointment_date__lte=week_end
                ).count()
                
                historical_data.append({
                    'period': f"{week_start.isoformat()} to {week_end.isoformat()}",
                    'count': weekly_count
                })
        else:
            for i in range(12):
                month_end = today.replace(day=1) - timedelta(days=1)
                month_end = month_end.replace(month=month_end.month-i if month_end.month > i else 12-(i-month_end.month))
                month_start = month_end.replace(day=1)
                
                monthly_count = appointments.filter(
                    appointment_date__gte=month_start,
                    appointment_date__lte=month_end
                ).count()
                
                historical_data.append({
                    'month': month_start.strftime('%B %Y'),
                    'count': monthly_count
                })
        
        historical_data.reverse()
        
        return Response({
            'total_appointments': total_appointments,
            'total_patients': total_patients,
            'status_distribution': status_distribution,
            'historical_data': historical_data
        }, status=200)
