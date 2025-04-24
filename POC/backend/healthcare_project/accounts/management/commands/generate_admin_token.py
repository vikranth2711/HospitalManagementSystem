# accounts/management/commands/generate_admin_token.py
from django.core.management.base import BaseCommand
from hospital.models import Staff
from rest_framework_simplejwt.tokens import RefreshToken

class Command(BaseCommand):
    help = 'Generates a new JWT token for an existing staff'

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help='Email of the staff member')

    def handle(self, *args, **options):
        email = options['email']
        
        try:
            staff = Staff.objects.get(staff_email=email)
        except Staff.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'No staff found with email: {email}'))
            return
            
        # Generate token
        refresh = RefreshToken()
        refresh['user_id'] = staff.staff_id
        refresh['user_type'] = 'staff'
        refresh['email'] = staff.staff_email
        
        self.stdout.write(self.style.SUCCESS(f'Generated token for: {staff.staff_name}'))
        self.stdout.write(self.style.SUCCESS(f'Access Token: {refresh.access_token}'))
        self.stdout.write(self.style.SUCCESS(f'Refresh Token: {refresh}'))