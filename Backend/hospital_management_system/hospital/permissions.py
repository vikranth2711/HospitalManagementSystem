from rest_framework import permissions
from .models import Staff, Role

class IsAdminStaff(permissions.BasePermission):
    """
    Permission to only allow users with admin role permissions or admin user type
    """
    message = "Admin staff privileges required."

    def has_permission(self, request, view):
        # Check if user is authenticated and is a staff member
        if not request.user or not hasattr(request.user, 'staff_id'):
            return False
        
        # Check if user has admin user_type
        is_admin_user_type = getattr(request.user, 'user_type', '') == 'admin'
        
        # Check if user has admin role permissions
        try:
            has_admin_permissions = request.user.role.role_permissions.get('is_admin', False)
        except AttributeError:
            has_admin_permissions = False
            
        return is_admin_user_type or has_admin_permissions

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