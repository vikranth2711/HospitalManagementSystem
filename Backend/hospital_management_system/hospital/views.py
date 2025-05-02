# hospital/views.py (Create this file if it doesn't exist)

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from accounts.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated
from .models import Staff, StaffDetails, DoctorDetails, LabTechnicianDetails, Role, DoctorType
from .permissions import IsAdminStaff
import uuid
import datetime
from django.contrib.auth.hashers import make_password
class StaffProfileView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, *args, **kwargs):
        # Check if authenticated user is a staff member
        if not hasattr(request.user, 'staff_id'):
            return Response({"error": "Not a staff account"}, 
                          status=status.HTTP_403_FORBIDDEN)
        
        staff = request.user
        
        # Basic staff data
        staff_data = {
            "staff_id": staff.staff_id,
            "staff_name": staff.staff_name,
            "staff_email": staff.staff_email,
            "staff_mobile": staff.staff_mobile,
            "role": {
                "role_id": staff.role.role_id,
                "role_name": staff.role.role_name
            },
            "created_at": staff.created_at,
            "on_leave": staff.on_leave
        }
        
        # Add staff details if they exist
        try:
            details = staff.staff_details
            staff_data.update({
                "staff_dob": details.staff_dob,
                "staff_address": details.staff_address,
                "staff_qualification": details.staff_qualification,
                "profile_photo": request.build_absolute_uri(details.profile_photo.url) if details.profile_photo else None
            })
        except (StaffDetails.DoesNotExist, AttributeError):
            pass
        
        # Add doctor details if they exist
        try:
            doctor = staff.doctor_details
            staff_data.update({
                "doctor_specialization": doctor.doctor_specialization,
                "doctor_license": doctor.doctor_license,
                "doctor_experience_years": doctor.doctor_experience_years,
                "doctor_type": {
                    "doctor_type_id": doctor.doctor_type.doctor_type_id,
                    "doctor_type": doctor.doctor_type.doctor_type
                }
            })
        except (DoctorDetails.DoesNotExist, AttributeError):
            pass
            
        # Add lab technician details if they exist
        try:
            lab_tech = staff.lab_tech_details
            staff_data.update({
                "certification": lab_tech.certification,
                "lab_experience_years": lab_tech.lab_experience_years,
                "assigned_lab": lab_tech.assigned_lab
            })
        except (LabTechnicianDetails.DoesNotExist, AttributeError):
            pass
            
        return Response(staff_data, status=status.HTTP_200_OK)
    
class AdminProfileView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, *args, **kwargs):
        # Check if authenticated user is a staff member
        if not hasattr(request.user, 'staff_id'):
            return Response({"error": "Not a staff account"}, 
                          status=status.HTTP_403_FORBIDDEN)
        
        # Check if user has admin permissions (either by user_type or role permissions)
        is_admin_user_type = getattr(request.user, 'user_type', '') == 'admin'
        
        try:
            has_admin_permissions = request.user.role.role_permissions.get('is_admin', False)
        except AttributeError:
            has_admin_permissions = False
        
        if not (is_admin_user_type or has_admin_permissions):
            return Response({"error": "Not authorized as admin"}, 
                          status=status.HTTP_403_FORBIDDEN)
        
        # Return admin profile
        staff = request.user
        
        admin_data = {
            "staff_id": staff.staff_id,
            "staff_name": staff.staff_name,
            "staff_email": staff.staff_email,
            "staff_mobile": staff.staff_mobile,
            "role": {
                "role_id": staff.role.role_id,
                "role_name": staff.role.role_name,
                "permissions": staff.role.role_permissions
            },
            "created_at": staff.created_at
        }
        
        # Add staff details if they exist
        try:
            details = staff.staff_details
            admin_data.update({
                "staff_dob": details.staff_dob,
                "staff_address": details.staff_address,
                "staff_qualification": details.staff_qualification,
                "profile_photo": request.build_absolute_uri(details.profile_photo.url) if details.profile_photo else None
            })
        except (StaffDetails.DoesNotExist, AttributeError):
            pass
            
        return Response(admin_data, status=status.HTTP_200_OK)
    
# Admin Lab Technician Management
class LabTechnicianListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def get(self, request, *args, **kwargs):
        # Get all staff with lab technician details
        lab_techs = Staff.objects.filter(lab_tech_details__isnull=False)
        
        result = []
        for staff in lab_techs:
            lab_tech_data = {
                "staff_id": staff.staff_id,
                "staff_name": staff.staff_name,
                "staff_email": staff.staff_email,
                "staff_mobile": staff.staff_mobile,
                "certification": staff.lab_tech_details.certification,
                "lab_experience_years": staff.lab_tech_details.lab_experience_years,
                "assigned_lab": staff.lab_tech_details.assigned_lab,
                "on_leave": staff.on_leave
            }
            result.append(lab_tech_data)
            
        return Response(result, status=status.HTTP_200_OK)

class LabTechnicianDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def get(self, request, staff_id, *args, **kwargs):
        try:
            staff = Staff.objects.get(staff_id=staff_id, lab_tech_details__isnull=False)
        except Staff.DoesNotExist:
            return Response({"error": "Lab technician not found"}, 
                          status=status.HTTP_404_NOT_FOUND)
                          
        lab_tech_data = {
            "staff_id": staff.staff_id,
            "staff_name": staff.staff_name,
            "staff_email": staff.staff_email,
            "staff_mobile": staff.staff_mobile,
            "created_at": staff.created_at,
            "certification": staff.lab_tech_details.certification,
            "lab_experience_years": staff.lab_tech_details.lab_experience_years,
            "assigned_lab": staff.lab_tech_details.assigned_lab,
            "on_leave": staff.on_leave
        }
        
        # Add staff details if they exist
        try:
            details = staff.staff_details
            lab_tech_data.update({
                "staff_dob": details.staff_dob,
                "staff_address": details.staff_address,
                "staff_qualification": details.staff_qualification,
                "profile_photo": request.build_absolute_uri(details.profile_photo.url) if details.profile_photo else None
            })
        except (StaffDetails.DoesNotExist, AttributeError):
            pass
            
        return Response(lab_tech_data, status=status.HTTP_200_OK)
        
    def put(self, request, staff_id, *args, **kwargs):
        try:
            staff = Staff.objects.get(staff_id=staff_id, lab_tech_details__isnull=False)
        except Staff.DoesNotExist:
            return Response({"error": "Lab technician not found"}, 
                          status=status.HTTP_404_NOT_FOUND)
        
        # Update staff fields
        staff_name = request.data.get('staff_name')
        staff_email = request.data.get('staff_email')
        staff_mobile = request.data.get('staff_mobile')
        on_leave = request.data.get('on_leave')
        
        if staff_name:
            staff.staff_name = staff_name
        if staff_email:
            staff.staff_email = staff_email
        if staff_mobile:
            staff.staff_mobile = staff_mobile
        if on_leave is not None:
            staff.on_leave = on_leave == True or on_leave == 'true' or on_leave == '1'
            
        staff.save()
        
        # Update lab technician details
        certification = request.data.get('certification')
        lab_experience_years = request.data.get('lab_experience_years')
        assigned_lab = request.data.get('assigned_lab')
        
        if certification:
            staff.lab_tech_details.certification = certification
        if lab_experience_years:
            staff.lab_tech_details.lab_experience_years = int(lab_experience_years)
        if assigned_lab:
            staff.lab_tech_details.assigned_lab = assigned_lab
            
        staff.lab_tech_details.save()
        
        return Response({"message": "Lab technician updated successfully"}, 
                      status=status.HTTP_200_OK)
                      
    def delete(self, request, staff_id, *args, **kwargs):
        try:
            staff = Staff.objects.get(staff_id=staff_id, lab_tech_details__isnull=False)
        except Staff.DoesNotExist:
            return Response({"error": "Lab technician not found"}, 
                          status=status.HTTP_404_NOT_FOUND)
                          
        staff.delete()  # This will cascade delete related lab tech details
        
        return Response({"message": "Lab technician deleted successfully"}, 
                      status=status.HTTP_204_NO_CONTENT)

class CreateLabTechnicianView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def post(self, request, *args, **kwargs):
        # Extract and validate required fields
        staff_name = request.data.get('staff_name')
        staff_email = request.data.get('staff_email')
        staff_mobile = request.data.get('staff_mobile')
        certification = request.data.get('certification')
        lab_experience_years = request.data.get('lab_experience_years')
        assigned_lab = request.data.get('assigned_lab')
        staff_joining_date = request.data.get('staff_joining_date')
        staff_password = "abc123"

        # Validate required fields
        if not all([staff_name, staff_email, staff_mobile, certification, 
                   lab_experience_years, assigned_lab, staff_joining_date]):
            return Response({"error": "Missing required fields"}, 
                          status=status.HTTP_400_BAD_REQUEST)
                          
        # Check if email already exists
        if Staff.objects.filter(staff_email=staff_email).exists():
            return Response({"error": "Staff with this email already exists"}, 
                          status=status.HTTP_400_BAD_REQUEST)
                          
        # Get lab technician role
        try:
            role = Role.objects.get(role_name='Lab Technician')
        except Role.DoesNotExist:
            return Response({"error": "Lab Technician role not found"}, 
                          status=status.HTTP_400_BAD_REQUEST)
                          
        # Generate unique staff ID
        staff_id = f"LABTECH{uuid.uuid4().hex[:8].upper()}"
        while Staff.objects.filter(staff_id=staff_id).exists():
            staff_id = f"LABTECH{uuid.uuid4().hex[:8].upper()}"
            
        # Create the staff
        try:
            # Parse date
            joining_date = datetime.datetime.strptime(staff_joining_date, '%Y-%m-%d').date()
            
            staff = Staff.objects.create(
                staff_id=staff_id,
                staff_name=staff_name,
                role=role,
                created_at=joining_date,
                staff_email=staff_email,
                staff_mobile=staff_mobile,
                password=make_password(staff_password)
            )
            
            # Create lab technician details
            LabTechnicianDetails.objects.create(
                staff=staff,
                certification=certification,
                lab_experience_years=int(lab_experience_years),
                assigned_lab=assigned_lab
            )
            
            return Response({
                "message": "Lab technician created successfully",
                "staff_id": staff.staff_id
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({"error": str(e)}, 
                          status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Admin Doctor Management
class DoctorListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def get(self, request, *args, **kwargs):
        # Get all staff with doctor details
        doctors = Staff.objects.filter(doctor_details__isnull=False)
        
        result = []
        for staff in doctors:
            doctor_data = {
                "staff_id": staff.staff_id,
                "staff_name": staff.staff_name,
                "staff_email": staff.staff_email,
                "staff_mobile": staff.staff_mobile,
                "specialization": staff.doctor_details.doctor_specialization,
                "license": staff.doctor_details.doctor_license,
                "experience_years": staff.doctor_details.doctor_experience_years,
                "doctor_type": staff.doctor_details.doctor_type.doctor_type,
                "on_leave": staff.on_leave
            }
            result.append(doctor_data)
            
        return Response(result, status=status.HTTP_200_OK)

class DoctorDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def get(self, request, staff_id, *args, **kwargs):
        try:
            staff = Staff.objects.get(staff_id=staff_id, doctor_details__isnull=False)
        except Staff.DoesNotExist:
            return Response({"error": "Doctor not found"}, 
                          status=status.HTTP_404_NOT_FOUND)
                          
        doctor_data = {
            "staff_id": staff.staff_id,
            "staff_name": staff.staff_name,
            "staff_email": staff.staff_email,
            "staff_mobile": staff.staff_mobile,
            "created_at": staff.created_at,
            "specialization": staff.doctor_details.doctor_specialization,
            "license": staff.doctor_details.doctor_license,
            "experience_years": staff.doctor_details.doctor_experience_years,
            "doctor_type": {
                "id": staff.doctor_details.doctor_type.doctor_type_id,
                "name": staff.doctor_details.doctor_type.doctor_type
            },
            "on_leave": staff.on_leave
        }
        
        # Add staff details if they exist
        try:
            details = staff.staff_details
            doctor_data.update({
                "staff_dob": details.staff_dob,
                "staff_address": details.staff_address,
                "staff_qualification": details.staff_qualification,
                "profile_photo": request.build_absolute_uri(details.profile_photo.url) if details.profile_photo else None
            })
        except (StaffDetails.DoesNotExist, AttributeError):
            pass
            
        return Response(doctor_data, status=status.HTTP_200_OK)
        
    def put(self, request, staff_id, *args, **kwargs):
        try:
            staff = Staff.objects.get(staff_id=staff_id, doctor_details__isnull=False)
        except Staff.DoesNotExist:
            return Response({"error": "Doctor not found"}, 
                          status=status.HTTP_404_NOT_FOUND)
        
        # Update staff fields
        staff_name = request.data.get('staff_name')
        staff_email = request.data.get('staff_email')
        staff_mobile = request.data.get('staff_mobile')
        on_leave = request.data.get('on_leave')
        
        if staff_name:
            staff.staff_name = staff_name
        if staff_email:
            staff.staff_email = staff_email
        if staff_mobile:
            staff.staff_mobile = staff_mobile
        if on_leave is not None:
            staff.on_leave = on_leave == True or on_leave == 'true' or on_leave == '1'
            
        staff.save()
        
        # Update doctor details
        specialization = request.data.get('specialization')
        license = request.data.get('license')
        experience_years = request.data.get('experience_years')
        doctor_type_id = request.data.get('doctor_type_id')
        
        if specialization:
            staff.doctor_details.doctor_specialization = specialization
        if license:
            staff.doctor_details.doctor_license = license
        if experience_years:
            staff.doctor_details.doctor_experience_years = int(experience_years)
        if doctor_type_id:
            try:
                doctor_type = DoctorType.objects.get(doctor_type_id=doctor_type_id)
                staff.doctor_details.doctor_type = doctor_type
            except DoctorType.DoesNotExist:
                return Response({"error": f"Doctor type with ID {doctor_type_id} not found"}, 
                              status=status.HTTP_400_BAD_REQUEST)
            
        staff.doctor_details.save()
        
        return Response({"message": "Doctor updated successfully"}, 
                      status=status.HTTP_200_OK)
                      
    def delete(self, request, staff_id, *args, **kwargs):
        try:
            staff = Staff.objects.get(staff_id=staff_id, doctor_details__isnull=False)
        except Staff.DoesNotExist:
            return Response({"error": "Doctor not found"}, 
                          status=status.HTTP_404_NOT_FOUND)
                          
        staff.delete()  # This will cascade delete related doctor details
        
        return Response({"message": "Doctor deleted successfully"}, 
                      status=status.HTTP_204_NO_CONTENT)

class CreateDoctorView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    #parser_classes = [MultiPartParser, FormParser]
    def post(self, request, *args, **kwargs):
        # Extract and validate required fields
        print(request.data)
        staff_name = request.data.get('staff_name')
        staff_email = request.data.get('staff_email')
        staff_mobile = request.data.get('staff_mobile')
        specialization = request.data.get('specialization')
        license = request.data.get('license')
        experience_years = request.data.get('experience_years')
        doctor_type_id = request.data.get('doctor_type_id')
        staff_joining_date = request.data.get('staff_joining_date')
        staff_qualification = request.data.get('staff_qualification')
        staff_dob = request.data.get('staff_dob')
        staff_address = request.data.get('staff_address')
        staff_password = "abc123"
        # Validate required fields
        if not all([
            staff_name, staff_email, staff_mobile, specialization,
            license, experience_years, doctor_type_id, staff_joining_date,
            staff_qualification, staff_dob, staff_address
        ]):
            return Response({"error": "Missing required fields"},
                            status=status.HTTP_400_BAD_REQUEST)

        # Check if email already exists
        if Staff.objects.filter(staff_email=staff_email).exists():
            return Response({"error": "Staff with this email already exists"},
                            status=status.HTTP_400_BAD_REQUEST)

        # Get doctor role
        try:
            role = Role.objects.get(role_name='Doctor')
        except Role.DoesNotExist:
            return Response({"error": "Doctor role not found"},
                            status=status.HTTP_400_BAD_REQUEST)

        # Verify doctor type exists
        try:
            doctor_type = DoctorType.objects.get(doctor_type_id=doctor_type_id)
        except DoctorType.DoesNotExist:
            return Response({"error": f"Doctor type with ID {doctor_type_id} not found"},
                            status=status.HTTP_400_BAD_REQUEST)

        # Generate unique staff ID
        staff_id = f"DOC{uuid.uuid4().hex[:8].upper()}"
        while Staff.objects.filter(staff_id=staff_id).exists():
            staff_id = f"DOC{uuid.uuid4().hex[:8].upper()}"

        try:
            # Parse dates
            joining_date = datetime.datetime.strptime(staff_joining_date, '%Y-%m-%d').date()
            dob = datetime.datetime.strptime(staff_dob, '%Y-%m-%d').date()

            # Create the staff
            staff = Staff.objects.create(
                staff_id=staff_id,
                staff_name=staff_name,
                role=role,
                created_at=joining_date,
                staff_email=staff_email,
                staff_mobile=staff_mobile,
                password=make_password(staff_password)
            )

            # Create doctor details
            DoctorDetails.objects.create(
                staff=staff,
                doctor_specialization=specialization,
                doctor_license=license,
                doctor_experience_years=int(experience_years),
                doctor_type=doctor_type
            )

            # Create staff details with DOB, address, and qualification
            StaffDetails.objects.create(
                staff=staff,
                staff_dob=dob,
                staff_address=staff_address,
                staff_qualification=staff_qualification
            )

            return Response({
                "message": "Doctor created successfully",
                "staff_id": staff.staff_id
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({"error": str(e)},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)

