from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.tokens import AccessToken
from django.conf import settings
import jwt
from hospital.models import Patient, Staff

class JWTAuthentication(BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return None
        
        token = auth_header.split(' ')[1]
        
        try:
            # Decode the token
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
            user_id = payload.get('user_id')
            user_type = payload.get('user_type')
            
            if not user_id or not user_type:
                raise AuthenticationFailed('Invalid token payload')
            
            # Get the user based on user_type
            if user_type == 'patient':
                try:
                    user = Patient.objects.get(patient_id=user_id)
                except Patient.DoesNotExist:
                    raise AuthenticationFailed('Patient not found')
            elif user_type == 'staff':
                try:
                    user = Staff.objects.get(staff_id=user_id)
                except Staff.DoesNotExist:
                    raise AuthenticationFailed('Staff not found')
            else:
                raise AuthenticationFailed('Invalid user type')
            
            return (user, token)
        
        except jwt.ExpiredSignatureError:
            raise AuthenticationFailed('Token expired')
        except jwt.InvalidTokenError:
            raise AuthenticationFailed('Invalid token')