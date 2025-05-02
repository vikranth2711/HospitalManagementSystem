# accounts/management/commands/create_system_admin.py
from django.core.management.base import BaseCommand
from hospital.models import Role, Staff
from datetime import date
import uuid
from django.contrib.auth.hashers import make_password

class Command(BaseCommand):
    help = 'Creates a new system administrator'

    def add_arguments(self, parser):
        parser.add_argument('--name', type=str, help='Admin name')
        parser.add_argument('--email', type=str, help='Admin email')
        parser.add_argument('--mobile', type=str, help='Admin mobile number')
        parser.add_argument('--password', type=str, help='Admin password')

    def handle(self, *args, **options):
        # Get or create admin role
        admin_role, created = Role.objects.get_or_create(
            role_name="Super Admin",
            defaults={
                'role_permissions': {
                    "is_admin": True,
                    "can_manage_doctors": True,
                    "can_manage_lab_techs": True,
                    "can_manage_roles": True,
                    "can_create_admin": True
                }
            }
        )
        
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created Super Admin role with ID: {admin_role.role_id}'))
        else:
            self.stdout.write(self.style.SUCCESS(f'Using existing Super Admin role with ID: {admin_role.role_id}'))

        # Get admin details from arguments or use defaults
        name = options['name'] or "Hariharan Mudaliar"
        email = options['email'] or "hrhn.mudaliar251@gmail.com"
        mobile = options['mobile'] or "9429199029"
        password = options['password'] or "admin123"
        
        # Check if staff with this email already exists
        if Staff.objects.filter(staff_email=email).exists():
            self.stdout.write(self.style.WARNING(f'Staff with email {email} already exists. Please use a different email.'))
            return

        # Generate a unique staff ID
        staff_id = f"ADMIN{uuid.uuid4().hex[:8].upper()}"
        while Staff.objects.filter(staff_id=staff_id).exists():
            staff_id = f"ADMIN{uuid.uuid4().hex[:8].upper()}"
        
        # Create admin staff
        admin = Staff.objects.create(
            staff_id=staff_id,
            staff_name=name,
            role=admin_role,
            created_at=date.today(),
            staff_email=email,
            staff_mobile=mobile,
            password=make_password(password)
        )
        
        self.stdout.write(self.style.SUCCESS(f'Created new system admin:'))
        self.stdout.write(self.style.SUCCESS(f'  ID: {admin.staff_id}'))
        self.stdout.write(self.style.SUCCESS(f'  Name: {admin.staff_name}'))
        self.stdout.write(self.style.SUCCESS(f'  Email: {admin.staff_email}'))
        self.stdout.write(self.style.SUCCESS(f'  Password: {password} (stored securely as hash)'))
        self.stdout.write(self.style.SUCCESS(f'  Role: {admin.role.role_name}'))
        
        self.stdout.write("\nLogin using the email and password provided.")
