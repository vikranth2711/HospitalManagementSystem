from rest_framework import permissions
from .models import Staff, Role

class IsAdminStaff(permissions.BasePermission):
    """
    Permission to only allow admin staff to access the view.
    """
    def has_permission(self, request, view):
        if not hasattr(request, 'user') or not isinstance(request.user, Staff):
            return False
        
        # Check if staff has admin permissions
        try:
            role_permissions = request.user.role.role_permissions
            if isinstance(role_permissions, str):
                import json
                role_permissions = json.loads(role_permissions)
            
            return role_permissions.get('is_admin', False)
        except:
            return False

class IsDoctorAdmin(permissions.BasePermission):
    """
    Permission to only allow staff with doctor admin permissions.
    """
    def has_permission(self, request, view):
        if not hasattr(request, 'user') or not isinstance(request.user, Staff):
            return False
        
        try:
            role_permissions = request.user.role.role_permissions
            if isinstance(role_permissions, str):
                import json
                role_permissions = json.loads(role_permissions)
            
            return role_permissions.get('can_manage_doctors', False)
        except:
            return False

class IsLabTechAdmin(permissions.BasePermission):
    """
    Permission to only allow staff with lab tech admin permissions.
    """
    def has_permission(self, request, view):
        if not hasattr(request, 'user') or not isinstance(request.user, Staff):
            return False
        
        try:
            role_permissions = request.user.role.role_permissions
            if isinstance(role_permissions, str):
                import json
                role_permissions = json.loads(role_permissions)
            
            return role_permissions.get('can_manage_lab_techs', False)
        except:
            return False