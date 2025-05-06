# hospital/views.py (Create this file if it doesn't exist)
from django.db.models import Avg
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from accounts.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated
from .models import Staff, StaffDetails, DoctorDetails, LabTechnicianDetails, Role, DoctorType, AppointmentRating, AppointmentCharge, LabTestCharge
from .permissions import IsAdminStaff
import uuid
import datetime
from django.contrib.auth.hashers import make_password
from .serializers import LabSerializer, LabTestTypeSerializer, LabTestChargeSerializer
from .models import Lab, LabType, LabTestType, Appointment
from .serializers import AppointmentRatingSerializer, AppointmentChargeSerializer
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
    parser_classes = [MultiPartParser, FormParser]
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
        
    # def put(self, request, staff_id, *args, **kwargs):
    #     try:
    #         staff = Staff.objects.get(staff_id=staff_id, lab_tech_details__isnull=False)
    #     except Staff.DoesNotExist:
    #         return Response({"error": "Lab technician not found"}, 
    #                       status=status.HTTP_404_NOT_FOUND)
        
    #     # Update staff fields
    #     staff_name = request.data.get('staff_name')
    #     staff_email = request.data.get('staff_email')
    #     staff_mobile = request.data.get('staff_mobile')
    #     on_leave = request.data.get('on_leave')
        
    #     if staff_name:
    #         staff.staff_name = staff_name
    #     if staff_email:
    #         staff.staff_email = staff_email
    #     if staff_mobile:
    #         staff.staff_mobile = staff_mobile
    #     if on_leave is not None:
    #         staff.on_leave = on_leave == True or on_leave == 'true' or on_leave == '1'
            
    #     staff.save()
        
    #     # Update lab technician details
    #     certification = request.data.get('certification')
    #     lab_experience_years = request.data.get('lab_experience_years')
    #     assigned_lab = request.data.get('assigned_lab')
        
    #     if certification:
    #         staff.lab_tech_details.certification = certification
    #     if lab_experience_years:
    #         staff.lab_tech_details.lab_experience_years = int(lab_experience_years)
    #     if assigned_lab:
    #         staff.lab_tech_details.assigned_lab = assigned_lab
            
    #     staff.lab_tech_details.save()
        
    #     return Response({"message": "Lab technician updated successfully"}, 
    #                   status=status.HTTP_200_OK)
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
        
        # Update staff details if they exist
        try:
            details = staff.staff_details
            
            # Update basic details
            staff_dob = request.data.get('staff_dob')
            staff_address = request.data.get('staff_address')
            staff_qualification = request.data.get('staff_qualification')
            
            if staff_dob:
                details.staff_dob = datetime.datetime.strptime(staff_dob, '%Y-%m-%d').date()
            if staff_address:
                details.staff_address = staff_address
            if staff_qualification:
                details.staff_qualification = staff_qualification
                
            # Handle profile photo upload
            profile_photo = request.FILES.get('profile_photo')
            if profile_photo:
                details.profile_photo = profile_photo
                
            details.save()
            
        except StaffDetails.DoesNotExist:
            # Create staff details if they don't exist
            if any([request.data.get('staff_dob'), request.data.get('staff_address'), 
                   request.data.get('staff_qualification'), request.FILES.get('profile_photo')]):
                
                staff_dob = request.data.get('staff_dob')
                dob_date = datetime.datetime.strptime(staff_dob, '%Y-%m-%d').date() if staff_dob else None
                
                StaffDetails.objects.create(
                    staff=staff,
                    staff_dob=dob_date,
                    staff_address=request.data.get('staff_address', ''),
                    staff_qualification=request.data.get('staff_qualification', ''),
                    profile_photo=request.FILES.get('profile_photo')
                )
        
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
    parser_classes = [MultiPartParser, FormParser]
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
        
    # def put(self, request, staff_id, *args, **kwargs):
    #     try:
    #         staff = Staff.objects.get(staff_id=staff_id, doctor_details__isnull=False)
    #     except Staff.DoesNotExist:
    #         return Response({"error": "Doctor not found"}, 
    #                       status=status.HTTP_404_NOT_FOUND)
        
    #     # Update staff fields
    #     staff_name = request.data.get('staff_name')
    #     staff_email = request.data.get('staff_email')
    #     staff_mobile = request.data.get('staff_mobile')
    #     on_leave = request.data.get('on_leave')
        
    #     if staff_name:
    #         staff.staff_name = staff_name
    #     if staff_email:
    #         staff.staff_email = staff_email
    #     if staff_mobile:
    #         staff.staff_mobile = staff_mobile
    #     if on_leave is not None:
    #         staff.on_leave = on_leave == True or on_leave == 'true' or on_leave == '1'
            
    #     staff.save()
        
    #     # Update doctor details
    #     specialization = request.data.get('specialization')
    #     license = request.data.get('license')
    #     experience_years = request.data.get('experience_years')
    #     doctor_type_id = request.data.get('doctor_type_id')
        
    #     if specialization:
    #         staff.doctor_details.doctor_specialization = specialization
    #     if license:
    #         staff.doctor_details.doctor_license = license
    #     if experience_years:
    #         staff.doctor_details.doctor_experience_years = int(experience_years)
    #     if doctor_type_id:
    #         try:
    #             doctor_type = DoctorType.objects.get(doctor_type_id=doctor_type_id)
    #             staff.doctor_details.doctor_type = doctor_type
    #         except DoctorType.DoesNotExist:
    #             return Response({"error": f"Doctor type with ID {doctor_type_id} not found"}, 
    #                           status=status.HTTP_400_BAD_REQUEST)
            
    #     staff.doctor_details.save()
        
    #     return Response({"message": "Doctor updated successfully"}, 
    #                   status=status.HTTP_200_OK)
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
        
        # Update staff details if they exist
        try:
            details = staff.staff_details
            
            # Update basic details
            staff_dob = request.data.get('staff_dob')
            staff_address = request.data.get('staff_address')
            staff_qualification = request.data.get('staff_qualification')
            
            if staff_dob:
                details.staff_dob = datetime.datetime.strptime(staff_dob, '%Y-%m-%d').date()
            if staff_address:
                details.staff_address = staff_address
            if staff_qualification:
                details.staff_qualification = staff_qualification
                
            # Handle profile photo upload
            profile_photo = request.FILES.get('profile_photo')
            if profile_photo:
                details.profile_photo = profile_photo
                
            details.save()
            
        except StaffDetails.DoesNotExist:
            # Create staff details if they don't exist
            if any([request.data.get('staff_dob'), request.data.get('staff_address'), 
                   request.data.get('staff_qualification'), request.FILES.get('profile_photo')]):
                
                staff_dob = request.data.get('staff_dob')
                dob_date = datetime.datetime.strptime(staff_dob, '%Y-%m-%d').date() if staff_dob else None
                
                StaffDetails.objects.create(
                    staff=staff,
                    staff_dob=dob_date,
                    staff_address=request.data.get('staff_address', ''),
                    staff_qualification=request.data.get('staff_qualification', ''),
                    profile_photo=request.FILES.get('profile_photo')
                )
        
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

class LabListCreateView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def get(self, request):
        """List all labs"""
        labs = Lab.objects.all()
        serializer = LabSerializer(labs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def post(self, request):
        """Create a new lab"""
        serializer = LabSerializer(data=request.data)
        if serializer.is_valid():
            # Verify that lab_type exists
            try:
                LabType.objects.get(lab_type_id=request.data.get('lab_type'))
            except LabType.DoesNotExist:
                return Response({"error": "Invalid lab type ID"}, status=status.HTTP_400_BAD_REQUEST)
                
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LabDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def get(self, request, lab_id):
        """Retrieve a lab by ID"""
        lab = get_object_or_404(Lab, lab_id=lab_id)
        serializer = LabSerializer(lab)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def put(self, request, lab_id):
        """Update a lab"""
        lab = get_object_or_404(Lab, lab_id=lab_id)
        serializer = LabSerializer(lab, data=request.data)
        if serializer.is_valid():
            # Verify that lab_type exists if it's being updated
            if 'lab_type' in request.data:
                try:
                    LabType.objects.get(lab_type_id=request.data.get('lab_type'))
                except LabType.DoesNotExist:
                    return Response({"error": "Invalid lab type ID"}, status=status.HTTP_400_BAD_REQUEST)
                    
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, lab_id):
        """Delete a lab"""
        lab = get_object_or_404(Lab, lab_id=lab_id)
        lab.delete()
        return Response({"message": "Lab deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
    
class LabTestTypeListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """List all lab test types with optional filtering"""
        # Get query parameters for filtering
        category_id = request.query_params.get('category_id')
        target_organ_id = request.query_params.get('target_organ_id')
        
        # Start with all test types
        queryset = LabTestType.objects.all()
        
        # Apply filters if provided
        if category_id:
            queryset = queryset.filter(test_category_id=category_id)
        if target_organ_id:
            queryset = queryset.filter(test_target_organ_id=target_organ_id)
            
        serializer = LabTestTypeSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
class AppointmentRatingView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def post(self, request, appointment_id):
        """Create a rating for an appointment"""
        # Check if appointment exists
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check if user is authorized to rate this appointment
        if hasattr(request.user, 'patient_id'):
            if appointment.patient.patient_id != request.user.patient_id:
                return Response({"error": "You can only rate your own appointments"}, status=403)
        else:
            return Response({"error": "Only patients can rate appointments"}, status=403)
            
        # Check if appointment is completed
        if appointment.status != 'completed':
            return Response({"error": "You can only rate completed appointments"}, status=400)
            
        # Check if rating already exists
        if AppointmentRating.objects.filter(appointment=appointment).exists():
            return Response({"error": "You have already rated this appointment"}, status=400)
            
        # Get rating data
        rating = request.data.get('rating')
        rating_comment = request.data.get('rating_comment', '')
        
        # Validate rating
        try:
            rating = int(rating)
            if rating < 1 or rating > 5:
                return Response({"error": "Rating must be between 1 and 5"}, status=400)
        except (ValueError, TypeError):
            return Response({"error": "Invalid rating value"}, status=400)
            
        # Create rating
        appointment_rating = AppointmentRating.objects.create(
            appointment=appointment,
            rating=rating,
            rating_comment=rating_comment
        )
        
        serializer = AppointmentRatingSerializer(appointment_rating)
        return Response(serializer.data, status=201)
    
    def get(self, request, appointment_id):
        """Get rating for an appointment"""
        # Check if appointment exists
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check permissions
        if hasattr(request.user, 'patient_id'):
            if appointment.patient.patient_id != request.user.patient_id:
                return Response({"error": "You can only view ratings for your own appointments"}, status=403)
        elif hasattr(request.user, 'staff_id'):
            if appointment.staff.staff_id != request.user.staff_id:
                # Check if admin
                try:
                    is_admin = request.user.role.role_permissions.get('is_admin', False)
                    if not is_admin:
                        return Response({"error": "You can only view ratings for your own appointments"}, status=403)
                except:
                    return Response({"error": "You can only view ratings for your own appointments"}, status=403)
        else:
            return Response({"error": "Invalid user"}, status=403)
            
        # Get rating
        try:
            rating = AppointmentRating.objects.get(appointment=appointment)
            serializer = AppointmentRatingSerializer(rating)
            return Response(serializer.data, status=200)
        except AppointmentRating.DoesNotExist:
            return Response({"error": "No rating found for this appointment"}, status=404)
    
    def put(self, request, appointment_id):
        """Update rating for an appointment"""
        # Check if appointment exists
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check if user is authorized to update this rating
        if hasattr(request.user, 'patient_id'):
            if appointment.patient.patient_id != request.user.patient_id:
                return Response({"error": "You can only update your own ratings"}, status=403)
        else:
            return Response({"error": "Only patients can update ratings"}, status=403)
            
        # Check if rating exists
        try:
            rating = AppointmentRating.objects.get(appointment=appointment)
        except AppointmentRating.DoesNotExist:
            return Response({"error": "No rating found for this appointment"}, status=404)
            
        # Get rating data
        rating_value = request.data.get('rating')
        rating_comment = request.data.get('rating_comment')
        
        # Validate rating
        if rating_value is not None:
            try:
                rating_value = int(rating_value)
                if rating_value < 1 or rating_value > 5:
                    return Response({"error": "Rating must be between 1 and 5"}, status=400)
                rating.rating = rating_value
            except (ValueError, TypeError):
                return Response({"error": "Invalid rating value"}, status=400)
                
        # Update comment if provided
        if rating_comment is not None:
            rating.rating_comment = rating_comment
            
        rating.save()
        
        serializer = AppointmentRatingSerializer(rating)
        return Response(serializer.data, status=200)
    
    def delete(self, request, appointment_id):
        """Delete rating for an appointment"""
        # Check if appointment exists
        appointment = get_object_or_404(Appointment, appointment_id=appointment_id)
        
        # Check if user is authorized to delete this rating
        if hasattr(request.user, 'patient_id'):
            if appointment.patient.patient_id != request.user.patient_id:
                return Response({"error": "You can only delete your own ratings"}, status=403)
        else:
            return Response({"error": "Only patients can delete ratings"}, status=403)
            
        # Check if rating exists
        try:
            rating = AppointmentRating.objects.get(appointment=appointment)
        except AppointmentRating.DoesNotExist:
            return Response({"error": "No rating found for this appointment"}, status=404)
            
        # Delete rating
        rating.delete()
        
        return Response({"message": "Rating deleted successfully"}, status=204)
    
class DoctorRatingsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, staff_id):
        """Get all ratings for a doctor"""
        # Get page number for pagination
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 10))
        
        # Get ratings
        ratings = AppointmentRating.objects.filter(
            appointment__staff__staff_id=staff_id,
            appointment__status='completed'
        ).order_by('-appointment__appointment_date')
        
        # Calculate average rating
        avg_rating = ratings.aggregate(Avg('rating'))['rating__avg'] or 0
        
        # Paginate results
        start = (page - 1) * page_size
        end = start + page_size
        paginated_ratings = ratings[start:end]
        
        # Serialize data
        serializer = AppointmentRatingSerializer(paginated_ratings, many=True)
        
        # Build response
        response_data = {
            'average_rating': round(avg_rating, 1),
            'total_ratings': ratings.count(),
            'page': page,
            'page_size': page_size,
            'total_pages': (ratings.count() + page_size - 1) // page_size,
            'ratings': serializer.data
        }
        
        return Response(response_data, status=200)

class PatientRatingsView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Get all ratings by the authenticated patient"""
        # Check if user is a patient
        if not hasattr(request.user, 'patient_id'):
            return Response({"error": "Only patients can access this endpoint"}, status=403)
            
        # Get page number for pagination
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 10))
        
        # Get ratings
        ratings = AppointmentRating.objects.filter(
            appointment__patient=request.user,
            appointment__status='completed'
        ).order_by('-appointment__appointment_date')
        
        # Paginate results
        start = (page - 1) * page_size
        end = start + page_size
        paginated_ratings = ratings[start:end]
        
        # Serialize data
        serializer = AppointmentRatingSerializer(paginated_ratings, many=True)
        
        # Build response
        response_data = {
            'total_ratings': ratings.count(),
            'page': page,
            'page_size': page_size,
            'total_pages': (ratings.count() + page_size - 1) // page_size,
            'ratings': serializer.data
        }
        
        return Response(response_data, status=200)

class AppointmentChargeListCreateView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request):
        charges = AppointmentCharge.objects.all()
        serializer = AppointmentChargeSerializer(charges, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = AppointmentChargeSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AppointmentChargeDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request, appointment_charge_id):
        charge = get_object_or_404(AppointmentCharge, appointment_charge_id=appointment_charge_id)
        serializer = AppointmentChargeSerializer(charge)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, appointment_charge_id):
        charge = get_object_or_404(AppointmentCharge, appointment_charge_id=appointment_charge_id)
        serializer = AppointmentChargeSerializer(charge, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, appointment_charge_id):
        charge = get_object_or_404(AppointmentCharge, appointment_charge_id=appointment_charge_id)
        charge.delete()
        return Response({"message": "Appointment charge deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
    
class DoctorChargeView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, staff_id):
        try:
            charge = AppointmentCharge.objects.get(doctor__staff_id=staff_id, is_active=True)
            serializer = AppointmentChargeSerializer(charge)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except AppointmentCharge.DoesNotExist:
            return Response({"error": "No charge found for this doctor"}, status=status.HTTP_404_NOT_FOUND)

class LabTestChargeListCreateView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request):
        """List all lab test charges"""
        charges = LabTestCharge.objects.all()
        serializer = LabTestChargeSerializer(charges, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        """Create a new lab test charge"""
        serializer = LabTestChargeSerializer(data=request.data)
        if serializer.is_valid():
            # Check if there's already an active charge for this test
            if 'is_active' in request.data and request.data['is_active']:
                # Deactivate all other charges for this test
                LabTestCharge.objects.filter(
                    test=request.data['test'], 
                    is_active=True
                ).update(is_active=False)
                
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LabTestChargeDetailView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]

    def get(self, request, test_charge_id):
        """Retrieve a specific lab test charge"""
        charge = get_object_or_404(LabTestCharge, test_charge_id=test_charge_id)
        serializer = LabTestChargeSerializer(charge)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, test_charge_id):
        """Update a lab test charge"""
        charge = get_object_or_404(LabTestCharge, test_charge_id=test_charge_id)
        serializer = LabTestChargeSerializer(charge, data=request.data)
        if serializer.is_valid():
            # If setting this charge to active, deactivate all other charges for this test
            if 'is_active' in request.data and request.data['is_active']:
                LabTestCharge.objects.filter(
                    test=charge.test, 
                    is_active=True
                ).exclude(test_charge_id=test_charge_id).update(is_active=False)
                
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, test_charge_id):
        """Delete a lab test charge"""
        charge = get_object_or_404(LabTestCharge, test_charge_id=test_charge_id)
        charge.delete()
        return Response({"message": "Lab test charge deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
    
class LabTestChargeForPatientView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, test_type_id):
        try:
            charge = LabTestCharge.objects.get(test__test_type_id=test_type_id, is_active=True)
            serializer = LabTestChargeSerializer(charge)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except LabTestCharge.DoesNotExist:
            return Response({"error": "No charge found for this lab test"}, status=status.HTTP_404_NOT_FOUND)

class AllLabTestChargesView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        charges = LabTestCharge.objects.filter(is_active=True)
        serializer = LabTestChargeSerializer(charges, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
