# accounts/management/commands/create_initial_admin.py
from django.core.management.base import BaseCommand
from hospital.models import Role, Staff
from datetime import date
import uuid
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.hashers import make_password
class Command(BaseCommand):
    help = 'Creates the initial admin user and role'

    def handle(self, *args, **options):
        # Check if any roles exist
        if Role.objects.exists():
            self.stdout.write(self.style.WARNING('Roles already exist. Skipping creation.'))
        else:
            # Create admin role
            admin_role = Role.objects.create(
                role_name="Super Admin",
                role_permissions={
                    "is_admin": True,
                    "can_manage_doctors": True,
                    "can_manage_lab_techs": True,
                    "can_manage_roles": True,
                    "can_create_admin": True
                }
            )
            self.stdout.write(self.style.SUCCESS(f'Created Super Admin role with ID: {admin_role.role_id}'))

        # Check if any staff exists
        if Staff.objects.exists():
            self.stdout.write(self.style.WARNING('Staff already exist. Skipping creation.'))
        else:
            # Create admin staff
            staff_id = f"ADMIN{uuid.uuid4().hex[:8].upper()}"
            admin_role = Role.objects.get(role_name="Super Admin")
            
            admin = Staff.objects.create(
                staff_id=staff_id,
                staff_name="Akshat Kaushik",
                role=admin_role,
                created_at=date.today(),
                staff_email="ak4425@srmist.edu.in",
                staff_mobile="9455276501",
                password=make_password("admin123")
            )
            
            # Generate token
            refresh = RefreshToken()
            refresh['user_id'] = admin.staff_id
            refresh['user_type'] = 'staff'
            refresh['email'] = admin.staff_email
            
            self.stdout.write(self.style.SUCCESS(f'Created Super Admin staff with ID: {admin.staff_id}'))
            self.stdout.write(self.style.SUCCESS(f'Email: {admin.staff_email}'))
            self.stdout.write(self.style.SUCCESS(f'Access Token: {refresh.access_token}'))
            self.stdout.write(self.style.SUCCESS(f'Refresh Token: {refresh}'))
            self.stdout.write("\nIMPORTANT: Save these tokens! You'll need them for initial access.")