# from django.shortcuts import render

# # Create your views here.

# # hospital/views.py
from rest_framework import viewsets
from .models import (
    Patient, PatientDetails, PatientVitals, Role, Staff, StaffDetails,
    LabTechnicianDetails, DoctorType, DoctorDetails, DoctorConsultationHours
)
from .serializers import (
    PatientSerializer, PatientDetailsSerializer, PatientVitalsSerializer,
    RoleSerializer, StaffSerializer, StaffDetailsSerializer,
    LabTechnicianDetailsSerializer, DoctorTypeSerializer, DoctorDetailsSerializer,
    DoctorConsultationHoursSerializer
)

class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer

class PatientDetailsViewSet(viewsets.ModelViewSet):
    queryset = PatientDetails.objects.all()
    serializer_class = PatientDetailsSerializer

class PatientVitalsViewSet(viewsets.ModelViewSet):
    queryset = PatientVitals.objects.all()
    serializer_class = PatientVitalsSerializer

class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.all()
    serializer_class = RoleSerializer

class StaffViewSet(viewsets.ModelViewSet):
    queryset = Staff.objects.all()
    serializer_class = StaffSerializer

class StaffDetailsViewSet(viewsets.ModelViewSet):
    queryset = StaffDetails.objects.all()
    serializer_class = StaffDetailsSerializer

class LabTechnicianDetailsViewSet(viewsets.ModelViewSet):
    queryset = LabTechnicianDetails.objects.all()
    serializer_class = LabTechnicianDetailsSerializer

class DoctorTypeViewSet(viewsets.ModelViewSet):
    queryset = DoctorType.objects.all()
    serializer_class = DoctorTypeSerializer

class DoctorDetailsViewSet(viewsets.ModelViewSet):
    queryset = DoctorDetails.objects.all()
    serializer_class = DoctorDetailsSerializer

class DoctorConsultationHoursViewSet(viewsets.ModelViewSet):
    queryset = DoctorConsultationHours.objects.all()
    serializer_class = DoctorConsultationHoursSerializer

# hospital/views.py (add these views to the existing file)
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import Patient, Staff, PatientDetails, StaffDetails
from .serializers import PatientSerializer, StaffSerializer, PatientDetailsSerializer, StaffDetailsSerializer
from accounts.authentication import JWTAuthentication
from rest_framework.parsers import MultiPartParser, FormParser

class PatientProfileView(APIView):
    authentication_classes = [JWTAuthentication]
    parser_classes = [MultiPartParser, FormParser]
    def get(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Patient):
            return Response({"error": "Authentication required or invalid user type."},
                           status=status.HTTP_403_FORBIDDEN)
        
        patient = request.user
        patient_data = PatientSerializer(patient).data
        
        # Get patient details if available
        try:
            details = patient.details
            details_data = PatientDetailsSerializer(details).data
            patient_data.update({"details": details_data})
        except PatientDetails.DoesNotExist:
            patient_data.update({"details": None})
        
        return Response(patient_data, status=status.HTTP_200_OK)
    
    # def put(self, request, *args, **kwargs):
    #     if not hasattr(request, 'user') or not isinstance(request.user, Patient):
    #         return Response({"error": "Authentication required or invalid user type."},
    #                     status=status.HTTP_403_FORBIDDEN)
        
    #     patient = request.user
        
    #     # Update patient basic info
    #     for key, value in request.data.items():
    #         if key in ['patient_name', 'patient_mobile', 'patient_remark']:
    #             setattr(patient, key, value)
        
    #     patient.save()
        
    #     # Handle patient details
    #     details_data = request.data.get('details', {})
    #     if details_data and all(k in details_data for k in ['patient_dob', 'patient_gender', 'patient_blood_group']):
    #         try:
    #             # Try to get existing details
    #             details = PatientDetails.objects.get(patient=patient)
                
    #             # Update existing details
    #             for key, value in details_data.items():
    #                 if key in ['patient_dob', 'patient_gender', 'patient_blood_group']:
    #                     setattr(details, key, value)
                
    #             details.save()
    #         except PatientDetails.DoesNotExist:
    #             # Create new details with all required fields
    #             PatientDetails.objects.create(
    #                 patient=patient,
    #                 patient_dob=details_data.get('patient_dob'),
    #                 patient_gender=details_data.get('patient_gender'),
    #                 patient_blood_group=details_data.get('patient_blood_group')
    #             )
        
    #     return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)
    # def put(self, request, *args, **kwargs):
    #     if not hasattr(request, 'user') or not isinstance(request.user, Patient):
    #         return Response({"error": "Authentication required or invalid user type."},
    #                        status=status.HTTP_403_FORBIDDEN)
        
    #     patient = request.user
        
    #     # Update patient basic info
    #     for key, value in request.data.items():
    #         if key in ['patient_name', 'patient_mobile', 'patient_remark']:
    #             setattr(patient, key, value)
        
    #     patient.save()
        
    #     # Handle patient details
    #     details_data = {}
    #     for key, value in request.data.items():
    #         if key in ['patient_dob', 'patient_gender', 'patient_blood_group']:
    #             details_data[key] = value
        
    #     if details_data or 'profile_photo' in request.FILES:
    #         details, created = PatientDetails.objects.get_or_create(patient=patient)
            
    #         for key, value in details_data.items():
    #             setattr(details, key, value)
            
    #         # Handle profile photo upload
    #         if 'profile_photo' in request.FILES:
    #             details.profile_photo = request.FILES['profile_photo']
            
    #         details.save()
        
    #     return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)
    def put(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Patient):
            return Response({"error": "Authentication required or invalid user type."},
                            status=status.HTTP_403_FORBIDDEN)

        patient = request.user

        # Update patient basic info
        for key, value in request.data.items():
            if key in ['patient_name', 'patient_mobile', 'patient_remark']:
                setattr(patient, key, value)

        patient.save()

        # Extract patient details from request
        details_data = {}
        for key in ['patient_dob', 'patient_gender', 'patient_blood_group']:
            if key in request.data:
                details_data[key] = request.data[key]

        # Try to get existing details without creating a new one prematurely
        details = PatientDetails.objects.filter(patient=patient).first()

        # If details exist or data is provided to create them
        if details or details_data or 'profile_photo' in request.FILES:
            if not details:
                # Validate that required fields exist before creating
                missing_fields = [field for field in ['patient_dob'] if field not in details_data]
                if missing_fields:
                    return Response(
                        {"error": f"Missing required fields for profile creation: {', '.join(missing_fields)}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                details = PatientDetails(patient=patient)

            # Update details
            for key, value in details_data.items():
                setattr(details, key, value)

            if 'profile_photo' in request.FILES:
                details.profile_photo = request.FILES['profile_photo']

            details.save()

        return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)
    
class StaffProfileView(APIView):
    authentication_classes = [JWTAuthentication]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Staff):
            return Response({"error": "Authentication required or invalid user type."},
                           status=status.HTTP_403_FORBIDDEN)
        
        staff = request.user
        staff_data = StaffSerializer(staff).data
        
        staff = request.user
        staff_data = StaffSerializer(staff).data
        
        # Get staff details if available
        try:
            details = staff.staff_details
            details_data = StaffDetailsSerializer(details).data
            staff_data.update({"details": details_data})
        except StaffDetails.DoesNotExist:
            staff_data.update({"details": None})
            
        # Check if staff is a doctor
        try:
            doctor_details = staff.doctor_details
            doctor_data = DoctorDetailsSerializer(doctor_details).data
            staff_data.update({"doctor_details": doctor_data})
        except:
            staff_data.update({"doctor_details": None})
            
        # Check if staff is a lab technician
        try:
            tech_details = staff.lab_tech_details
            tech_data = LabTechnicianDetailsSerializer(tech_details).data
            staff_data.update({"lab_tech_details": tech_data})
        except:
            staff_data.update({"lab_tech_details": None})
        
        return Response(staff_data, status=status.HTTP_200_OK)
    
    # def put(self, request, *args, **kwargs):
    #     if not hasattr(request, 'user') or not isinstance(request.user, Staff):
    #         return Response({"error": "Authentication required or invalid user type."},
    #                        status=status.HTTP_403_FORBIDDEN)
        
    #     staff = request.user
        
    #     # Update staff basic info (limited fields)
    #     for key, value in request.data.items():
    #         if key in ['staff_name', 'staff_mobile']:
    #             setattr(staff, key, value)
        
    #     staff.save()
        
    #     # Handle staff details
    #     details_data = request.data.get('details', {})
    #     if details_data:
    #         details, created = StaffDetails.objects.get_or_create(staff=staff)
            
    #         for key, value in details_data.items():
    #             if key in ['staff_address']:
    #                 setattr(details, key, value)
            
    #         details.save()
        
    #     return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)
    # def put(self, request, *args, **kwargs):
    #     if not hasattr(request, 'user') or not isinstance(request.user, Staff):
    #         return Response({"error": "Authentication required or invalid user type."},
    #                     status=status.HTTP_403_FORBIDDEN)
        
    #     staff = request.user
        
    #     # Update staff basic info (limited fields)
    #     for key, value in request.data.items():
    #         if key in ['staff_name', 'staff_mobile']:
    #             setattr(staff, key, value)
        
    #     staff.save()
        
    #     # Handle staff details
    #     details_data = request.data.get('details', {})
    #     if details_data and all(k in details_data for k in ['staff_dob', 'staff_address']):
    #         try:
    #             # Try to get existing details
    #             details = StaffDetails.objects.get(staff=staff)
                
    #             # Update existing details
    #             for key, value in details_data.items():
    #                 if key in ['staff_dob', 'staff_address']:
    #                     setattr(details, key, value)
                
    #             details.save()
    #         except StaffDetails.DoesNotExist:
    #             # Create new details with all required fields
    #             StaffDetails.objects.create(
    #                 staff=staff,
    #                 staff_dob=details_data.get('staff_dob'),
    #                 staff_address=details_data.get('staff_address')
    #             )
        
    #     return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)
    def put(self, request, *args, **kwargs):
        if not hasattr(request, 'user') or not isinstance(request.user, Staff):
            return Response({"error": "Authentication required or invalid user type."},
                           status=status.HTTP_403_FORBIDDEN)
        
        staff = request.user
        
        # Update staff basic info (limited fields)
        for key, value in request.data.items():
            if key in ['staff_name', 'staff_mobile']:
                setattr(staff, key, value)
        
        staff.save()
        
        # Handle staff details and profile photo
        details_data = {}
        for key, value in request.data.items():
            if key in ['staff_address', 'staff_dob']:
                details_data[key] = value
                
        if details_data or 'profile_photo' in request.FILES:
            details, created = StaffDetails.objects.get_or_create(staff=staff)
            
            for key, value in details_data.items():
                setattr(details, key, value)
                
            # Handle profile photo upload
            if 'profile_photo' in request.FILES:
                details.profile_photo = request.FILES['profile_photo']
                
            details.save()
            
        # If staff is a doctor, handle doctor-specific profile photo
        try:
            doctor = staff.doctor_details
            if 'doctor_profile_photo' in request.FILES:
                doctor.profile_photo = request.FILES['doctor_profile_photo']
                doctor.save()
        except:
            pass
            
        # If staff is a lab technician, handle tech-specific profile photo
        try:
            tech = staff.lab_tech_details
            if 'tech_profile_photo' in request.FILES:
                tech.profile_photo = request.FILES['tech_profile_photo']
                tech.save()
        except:
            pass
        
        return Response({"message": "Profile updated successfully."}, status=status.HTTP_200_OK)    
# hospital/views.py (add these to your existing views)

from .permissions import IsAdminStaff, IsDoctorAdmin, IsLabTechAdmin

class DoctorManagementView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsDoctorAdmin]
    parser_classes = [MultiPartParser, FormParser]
    
    def get(self, request, doctor_id=None):
        """Fetch doctor details by ID or get list of all doctors"""
        if doctor_id:
            try:
                doctor = DoctorDetails.objects.get(staff_id=doctor_id)
                doctor_data = DoctorDetailsSerializer(doctor).data
                
                # Add staff details
                staff_data = StaffSerializer(doctor.staff).data
                doctor_data['staff_info'] = staff_data
                
                return Response(doctor_data, status=status.HTTP_200_OK)
            except DoctorDetails.DoesNotExist:
                return Response({"error": "Doctor not found"}, status=status.HTTP_404_NOT_FOUND)
        else:
            # Get all doctors with staff info
            doctors = DoctorDetails.objects.all()
            data = []
            
            for doctor in doctors:
                doctor_data = DoctorDetailsSerializer(doctor).data
                doctor_data['staff_info'] = StaffSerializer(doctor.staff).data
                data.append(doctor_data)
                
            return Response(data, status=status.HTTP_200_OK)
    
    def put(self, request, doctor_id):
        """Update doctor details"""
        try:
            doctor = DoctorDetails.objects.get(staff_id=doctor_id)
        except DoctorDetails.DoesNotExist:
            return Response({"error": "Doctor not found"}, status=status.HTTP_404_NOT_FOUND)
        
        # Handle doctor fields
        for key, value in request.data.items():
            if key in ['doctor_specialization', 'doctor_license', 'doctor_experience_years', 
                      'doctor_qualification']:
                setattr(doctor, key, value)
            
            # Handle doctor_type as special case
            if key == 'doctor_type_id':
                try:
                    doctor_type = DoctorType.objects.get(doctor_type_id=value)
                    doctor.doctor_type = doctor_type
                except DoctorType.DoesNotExist:
                    return Response({"error": f"Doctor type with ID {value} not found"},
                                   status=status.HTTP_400_BAD_REQUEST)
                
        # Handle profile photo upload
        if 'profile_photo' in request.FILES:
            doctor.profile_photo = request.FILES['profile_photo']
        
        doctor.save()
        
        # Update staff details if provided
        staff_data = {}
        for key, value in request.data.items():
            if key in ['staff_name', 'staff_email', 'staff_mobile']:
                staff_data[key] = value
        
        if staff_data:
            staff = doctor.staff
            for key, value in staff_data.items():
                setattr(staff, key, value)
            staff.save()
        
        return Response({"message": "Doctor details updated successfully"}, 
                       status=status.HTTP_200_OK)

class LabTechManagementView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsLabTechAdmin]
    parser_classes = [MultiPartParser, FormParser]
    
    def get(self, request, tech_id=None):
        """Fetch lab technician details by ID or get list of all lab technicians"""
        if tech_id:
            try:
                tech = LabTechnicianDetails.objects.get(staff_id=tech_id)
                tech_data = LabTechnicianDetailsSerializer(tech).data
                
                # Add staff details
                staff_data = StaffSerializer(tech.staff).data
                tech_data['staff_info'] = staff_data
                
                return Response(tech_data, status=status.HTTP_200_OK)
            except LabTechnicianDetails.DoesNotExist:
                return Response({"error": "Lab technician not found"}, status=status.HTTP_404_NOT_FOUND)
        else:
            # Get all lab technicians with staff info
            techs = LabTechnicianDetails.objects.all()
            data = []
            
            for tech in techs:
                tech_data = LabTechnicianDetailsSerializer(tech).data
                tech_data['staff_info'] = StaffSerializer(tech.staff).data
                data.append(tech_data)
                
            return Response(data, status=status.HTTP_200_OK)
    
    def put(self, request, tech_id):
        """Update lab technician details"""
        try:
            tech = LabTechnicianDetails.objects.get(staff_id=tech_id)
        except LabTechnicianDetails.DoesNotExist:
            return Response({"error": "Lab technician not found"}, status=status.HTTP_404_NOT_FOUND)
        
        # Handle lab technician fields
        for key, value in request.data.items():
            if key in ['certification', 'lab_experience_years', 'assigned_lab']:
                setattr(tech, key, value)
        
        # Handle profile photo upload
        if 'profile_photo' in request.FILES:
            tech.profile_photo = request.FILES['profile_photo']
        
        tech.save()
        
        # Update staff details if provided
        staff_data = {}
        for key, value in request.data.items():
            if key in ['staff_name', 'staff_email', 'staff_mobile']:
                staff_data[key] = value
        
        if staff_data:
            staff = tech.staff
            for key, value in staff_data.items():
                setattr(staff, key, value)
            staff.save()
        
        return Response({"message": "Lab technician details updated successfully"}, 
                       status=status.HTTP_200_OK)
    
# hospital/views.py (add this new view)
class RoleManagementView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    
    def get(self, request, role_id=None):
        """Get all roles or a specific role"""
        if role_id:
            try:
                role = Role.objects.get(role_id=role_id)
                return Response(RoleSerializer(role).data, status=status.HTTP_200_OK)
            except Role.DoesNotExist:
                return Response({"error": "Role not found"}, status=status.HTTP_404_NOT_FOUND)
        else:
            roles = Role.objects.all()
            return Response(RoleSerializer(roles, many=True).data, status=status.HTTP_200_OK)
    
    def post(self, request):
        """Create a new role"""
        role_name = request.data.get('role_name')
        role_permissions = request.data.get('role_permissions', {})
        
        if not role_name:
            return Response({"error": "Role name is required"}, status=status.HTTP_400_BAD_REQUEST)
            
        # Ensure role_permissions is a dictionary/JSON
        if isinstance(role_permissions, str):
            try:
                import json
                role_permissions = json.loads(role_permissions)
            except:
                return Response({"error": "Invalid role permissions format"}, 
                              status=status.HTTP_400_BAD_REQUEST)
        
        role = Role.objects.create(
            role_name=role_name,
            role_permissions=role_permissions
        )
        
        return Response({
            "message": "Role created successfully",
            "role_id": role.role_id,
            "role_name": role.role_name
        }, status=status.HTTP_201_CREATED)
    
    def put(self, request, role_id):
        """Update an existing role"""
        try:
            role = Role.objects.get(role_id=role_id)
        except Role.DoesNotExist:
            return Response({"error": "Role not found"}, status=status.HTTP_404_NOT_FOUND)
            
        if 'role_name' in request.data:
            role.role_name = request.data['role_name']
            
        if 'role_permissions' in request.data:
            role_permissions = request.data['role_permissions']
            
            # Ensure role_permissions is a dictionary/JSON
            if isinstance(role_permissions, str):
                try:
                    import json
                    role_permissions = json.loads(role_permissions)
                except:
                    return Response({"error": "Invalid role permissions format"}, 
                                  status=status.HTTP_400_BAD_REQUEST)
                                  
            role.role_permissions = role_permissions
            
        role.save()
        
        return Response({
            "message": "Role updated successfully",
            "role": RoleSerializer(role).data
        }, status=status.HTTP_200_OK)
    
    def delete(self, request, role_id):
        """Delete a role"""
        try:
            role = Role.objects.get(role_id=role_id)
        except Role.DoesNotExist:
            return Response({"error": "Role not found"}, status=status.HTTP_404_NOT_FOUND)
            
        # Check if the role is assigned to any staff
        if Staff.objects.filter(role=role).exists():
            return Response({
                "error": "Cannot delete role as it is assigned to staff members"
            }, status=status.HTTP_400_BAD_REQUEST)
            
        role.delete()
        
        return Response({"message": "Role deleted successfully"}, status=status.HTTP_200_OK)
    
# hospital/views.py (add these new views)

class StaffManagementView(APIView):
    """Admin API for creating and managing general staff"""
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request):
        """Create new staff member"""
        # Check required fields
        print(request.data)
        required_fields = ['staff_id', 'staff_name', 'role_id', 'staff_joining_date', 
                         'staff_email', 'staff_mobile']
        for field in required_fields:
            if field not in request.data:
                return Response({"error": f"Missing required field: {field}"}, 
                              status=status.HTTP_400_BAD_REQUEST)
        
        # Check if email already exists
        if Staff.objects.filter(staff_email=request.data['staff_email']).exists():
            return Response({"error": "Staff with this email already exists"},
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Check if staff ID already exists
        if Staff.objects.filter(staff_id=request.data['staff_id']).exists():
            return Response({"error": "Staff with this ID already exists"},
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Validate role exists
        try:
            role = Role.objects.get(role_id=request.data['role_id'])
        except Role.DoesNotExist:
            return Response({"error": "Role does not exist"}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Create staff member
        staff_data = {
            'staff_id': request.data['staff_id'],
            'staff_name': request.data['staff_name'],
            'role': role,
            'staff_joining_date': request.data['staff_joining_date'],
            'staff_email': request.data['staff_email'],
            'staff_mobile': request.data['staff_mobile']
        }
        
        staff = Staff.objects.create(**staff_data)
        
        # Create staff details if provided
        staff_details_data = {}
        if 'staff_dob' in request.data:
            staff_details_data['staff_dob'] = request.data['staff_dob']
        if 'staff_address' in request.data:
            staff_details_data['staff_address'] = request.data['staff_address']
        
        if staff_details_data:
            staff_details = StaffDetails.objects.create(staff=staff, **staff_details_data)
            
            # Handle profile photo
            if 'profile_photo' in request.FILES:
                staff_details.profile_photo = request.FILES['profile_photo']
                staff_details.save()
        
        return Response({
            "message": "Staff created successfully",
            "staff_id": staff.staff_id
        }, status=status.HTTP_201_CREATED)
    
    def get(self, request, staff_id=None):
        """Get all staff or a specific staff member"""
        if staff_id:
            try:
                staff = Staff.objects.get(staff_id=staff_id)
                staff_data = StaffSerializer(staff).data
                
                # Include staff details if available
                try:
                    details = staff.staff_details
                    details_data = StaffDetailsSerializer(details).data
                    staff_data['details'] = details_data
                except StaffDetails.DoesNotExist:
                    staff_data['details'] = None
                
                # Check if staff is a doctor
                try:
                    doctor_details = staff.doctor_details
                    doctor_data = DoctorDetailsSerializer(doctor_details).data
                    staff_data['doctor_details'] = doctor_data
                except:
                    staff_data['doctor_details'] = None
                
                # Check if staff is a lab technician
                try:
                    lab_tech_details = staff.lab_tech_details
                    tech_data = LabTechnicianDetailsSerializer(lab_tech_details).data
                    staff_data['lab_tech_details'] = tech_data
                except:
                    staff_data['lab_tech_details'] = None
                
                return Response(staff_data, status=status.HTTP_200_OK)
            except Staff.DoesNotExist:
                return Response({"error": "Staff not found"}, status=status.HTTP_404_NOT_FOUND)
        else:
            # Get all staff with basic info
            staff_members = Staff.objects.all()
            data = []
            
            for staff in staff_members:
                staff_data = StaffSerializer(staff).data
                
                # Add role name
                staff_data['role_name'] = staff.role.role_name
                
                # Determine staff type
                if hasattr(staff, 'doctor_details'):
                    staff_data['staff_type'] = 'Doctor'
                    staff_data['specialization'] = staff.doctor_details.doctor_specialization
                elif hasattr(staff, 'lab_tech_details'):
                    staff_data['staff_type'] = 'Lab Technician'
                    staff_data['lab'] = staff.lab_tech_details.assigned_lab
                else:
                    staff_data['staff_type'] = 'General Staff'
                
                data.append(staff_data)
            
            return Response(data, status=status.HTTP_200_OK)
        
    def delete(self, request, staff_id):
        """Delete a staff member"""
        if not staff_id:
            return Response({"error": "Staff ID is required"},
                         status=status.HTTP_400_BAD_REQUEST)
        
        try:
            staff = Staff.objects.get(staff_id=staff_id)
            staff.delete()
            return Response({"message": "Staff deleted successfully"},
                         status=status.HTTP_200_OK)
        except Staff.DoesNotExist:
            return Response({"error": "Staff not found"},
                         status=status.HTTP_404_NOT_FOUND)
        
class DoctorCreationView(APIView):
    """Admin API for creating new doctors"""
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request):
        """Create new doctor (staff + doctor details)"""
        # First create the staff member
        staff_view = StaffManagementView()
        staff_response = staff_view.post(request)
        
        # If staff creation failed, return the error
        if staff_response.status_code != status.HTTP_201_CREATED:
            return staff_response
        
        staff_id = staff_response.data['staff_id']
        staff = Staff.objects.get(staff_id=staff_id)
        
        # Check required doctor fields
        required_fields = ['doctor_specialization', 'doctor_license', 
                         'doctor_experience_years', 'doctor_qualification', 'doctor_type_id']
        for field in required_fields:
            if field not in request.data:
                # Delete the staff we just created to avoid orphaned records
                staff.delete()
                return Response({"error": f"Missing required doctor field: {field}"}, 
                              status=status.HTTP_400_BAD_REQUEST)
        
        # Validate doctor type exists
        try:
            doctor_type = DoctorType.objects.get(doctor_type_id=request.data['doctor_type_id'])
        except DoctorType.DoesNotExist:
            staff.delete()
            return Response({"error": "Doctor type does not exist"}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Create doctor details
        doctor_data = {
            'staff': staff,
            'doctor_specialization': request.data['doctor_specialization'],
            'doctor_license': request.data['doctor_license'],
            'doctor_experience_years': request.data['doctor_experience_years'],
            'doctor_qualification': request.data['doctor_qualification'],
            'doctor_type': doctor_type
        }
        
        doctor = DoctorDetails.objects.create(**doctor_data)
        
        # Handle doctor profile photo
        if 'doctor_profile_photo' in request.FILES:
            doctor.profile_photo = request.FILES['doctor_profile_photo']
            doctor.save()
        
        return Response({
            "message": "Doctor created successfully",
            "staff_id": staff.staff_id
        }, status=status.HTTP_201_CREATED)

class LabTechnicianCreationView(APIView):
    """Admin API for creating new lab technicians"""
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAdminStaff]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request):
        """Create new lab technician (staff + lab tech details)"""
        # First create the staff member
        staff_view = StaffManagementView()
        staff_response = staff_view.post(request)
        
        # If staff creation failed, return the error
        if staff_response.status_code != status.HTTP_201_CREATED:
            return staff_response
        
        staff_id = staff_response.data['staff_id']
        staff = Staff.objects.get(staff_id=staff_id)
        
        # Check required lab technician fields
        required_fields = ['certification', 'lab_experience_years', 'assigned_lab']
        for field in required_fields:
            if field not in request.data:
                # Delete the staff we just created to avoid orphaned records
                staff.delete()
                return Response({"error": f"Missing required lab technician field: {field}"}, 
                              status=status.HTTP_400_BAD_REQUEST)
        
        # Create lab technician details
        lab_tech_data = {
            'staff': staff,
            'certification': request.data['certification'],
            'lab_experience_years': request.data['lab_experience_years'],
            'assigned_lab': request.data['assigned_lab']
        }
        
        lab_tech = LabTechnicianDetails.objects.create(**lab_tech_data)
        
        # Handle lab tech profile photo
        if 'tech_profile_photo' in request.FILES:
            lab_tech.profile_photo = request.FILES['tech_profile_photo']
            lab_tech.save()
        
        return Response({
            "message": "Lab technician created successfully",
            "staff_id": staff.staff_id
        }, status=status.HTTP_201_CREATED)