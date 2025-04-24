# Hospital Management System API Documentation

This document outlines all available API endpoints, their request types, required parameters, sample requests, and expected responses.

## Table of Contents
- [Authentication](#authentication)
- [Patient APIs](#patient-apis)
- [Staff APIs](#staff-apis)
- [Admin APIs](#admin-apis)
  - [Lab Technician Management](#lab-technician-management)
  - [Doctor Management](#doctor-management)

## Authentication

All protected routes require a JWT token in the Authorization header:
```
Authorization: Bearer {your_access_token}
```

### Request OTP
Used for both login and signup workflows to initiate authentication.

**Endpoint:** `POST /api/request-otp/`

**Request Body:**
```json
{
  "email": "patient@example.com",
  "user_type": "patient" // Options: "patient" or "staff"
}
```

**Sample Response:**
```json
{
  "message": "OTP sent successfully."
}
```

### Verify OTP
Used to verify an OTP without completing login/signup.

**Endpoint:** `POST /api/verify-otp/`

**Request Body:**
```json
{
  "email": "patient@example.com",
  "otp": "123456"
}
```

**Sample Response:**
```json
{
  "message": "OTP verified successfully."
}
```

### Patient Signup
Register a new patient using OTP verification.

**Endpoint:** `POST /api/patient-signup/`

**Request Body:**
```json
{
  "email": "newpatient@example.com",
  "otp": "123456",
  "patient_name": "John Doe",
  "patient_mobile": "1234567890"
}
```

**Sample Response:**
```json
{
  "message": "Patient registered successfully.",
  "patient_id": 123,
  "access_token": "eyJhbGciOiJ...",
  "refresh_token": "eyJhbGciOiJ..."
}
```

### User Login
Used for both patient and staff login.

**Endpoint:** `POST /api/login/`

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456",
  "user_type": "patient" // Options: "patient" or "staff"
}
```

**Sample Response:**
```json
{
  "message": "Login successful.",
  "user_id": "PATIENT123" or "STAFF123",
  "user_type": "patient" or "staff",
  "access_token": "eyJhbGciOiJ...",
  "refresh_token": "eyJhbGciOiJ..."
}
```

## Patient APIs

### Get Patient Profile
Retrieves authenticated patient's details.

**Endpoint:** `GET /api/patient/profile/`

**Authentication:** Required

**Sample Response:**
```json
{
  "patient_id": 123,
  "patient_name": "John Doe",
  "patient_email": "john@example.com",
  "patient_mobile": "1234567890",
  "patient_remark": null,
  "patient_dob": "1990-01-01",
  "patient_gender": true,
  "patient_blood_group": "A+",
  "patient_address": "123 Main St, City",
  "profile_photo": "https://example.com/media/patient_photos/john.jpg"
}
```

### Update Patient Profile
Updates patient's basic profile information.

**Endpoint:** `PUT /api/patient/update-profile/`

**Authentication:** Required

**Request Body:**
```json
{
  "patient_dob": "1990-01-01",
  "patient_blood_group": "A+",
  "patient_gender": true,
  "patient_address": "123 Main St, City"
}
```

**Sample Response:**
```json
{
  "message": "Profile updated successfully",
  "created": false
}
```

### Update Patient Photo
Updates patient's profile photo.

**Endpoint:** `PUT /api/patient/update-photo/`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Form Data:**
- `profile_photo`: [File Upload]

**Sample Response:**
```json
{
  "message": "Profile photo updated successfully",
  "photo_url": "https://example.com/media/patient_photos/john.jpg"
}
```

## Staff APIs

### Get Staff Profile
Retrieves authenticated staff's details.

**Endpoint:** `GET /api/staff/profile/`

**Authentication:** Required

**Sample Response:**
```json
{
  "staff_id": "STAFF123",
  "staff_name": "Jane Smith",
  "staff_email": "jane@hospital.com",
  "staff_mobile": "9876543210",
  "role": {
    "role_id": 2,
    "role_name": "Doctor"
  },
  "created_at": "2023-01-15",
  "on_leave": false,
  "staff_dob": "1985-05-10",
  "staff_address": "456 Hospital St, City",
  "staff_qualification": "MBBS, MD",
  "profile_photo": "https://example.com/media/staff_photos/jane.jpg",
  "doctor_specialization": "Cardiologist",
  "doctor_license": "MED12345",
  "doctor_experience_years": 8,
  "doctor_type": {
    "doctor_type_id": 3,
    "doctor_type": "Specialist"
  }
}
```

## Admin APIs

### Get Admin Profile
Retrieves authenticated admin's details.

**Endpoint:** `GET /api/admin/profile/`

**Authentication:** Required (with admin role)

**Sample Response:**
```json
{
  "staff_id": "STAFF001",
  "staff_name": "Admin User",
  "staff_email": "admin@hospital.com",
  "staff_mobile": "7777777777",
  "role": {
    "role_id": 1,
    "role_name": "Administrator",
    "permissions": {
      "is_admin": true,
      "manage_staff": true,
      "manage_patients": true
    }
  },
  "created_at": "2022-12-01",
  "staff_dob": "1980-03-15",
  "staff_address": "789 Admin St, City",
  "staff_qualification": "MSc Health Administration",
  "profile_photo": "https://example.com/media/staff_photos/admin.jpg"
}
```

### Create Admin Staff

**Endpoint:** `POST /api/create-admin-staff/`

**Authentication:** Required (with admin role)

**Request Body:**
```json
{
  "staff_name": "New Admin",
  "staff_email": "newadmin@hospital.com",
  "staff_mobile": "5555555555",
  "role_id": 1,
  "staff_joining_date": "2023-04-01"
}
```

**Sample Response:**
```json
{
  "message": "Admin staff created successfully",
  "staff_id": "STAFF789",
  "access_token": "eyJhbGciOiJ...",
  "refresh_token": "eyJhbGciOiJ..."
}
```

### Lab Technician Management

#### Get All Lab Technicians

**Endpoint:** `GET /api/admin/lab-technicians/`

**Authentication:** Required (with admin role)

**Sample Response:**
```json
[
  {
    "staff_id": "LABTECH123",
    "staff_name": "Lab Tech 1",
    "staff_email": "labtech1@hospital.com",
    "staff_mobile": "1122334455",
    "certification": "MLT Certificate",
    "lab_experience_years": 5,
    "assigned_lab": "Pathology Lab",
    "on_leave": false
  },
  {
    "staff_id": "LABTECH456",
    "staff_name": "Lab Tech 2",
    "staff_email": "labtech2@hospital.com",
    "staff_mobile": "5566778899",
    "certification": "Clinical Lab Technician",
    "lab_experience_years": 3,
    "assigned_lab": "Biochemistry Lab",
    "on_leave": true
  }
]
```

#### Get Specific Lab Technician

**Endpoint:** `GET /api/admin/lab-technicians/{staff_id}/`

**Authentication:** Required (with admin role)

**Sample Response:**
```json
{
  "staff_id": "LABTECH123",
  "staff_name": "Lab Tech 1",
  "staff_email": "labtech1@hospital.com",
  "staff_mobile": "1122334455",
  "created_at": "2022-06-15",
  "certification": "MLT Certificate",
  "lab_experience_years": 5,
  "assigned_lab": "Pathology Lab",
  "on_leave": false,
  "staff_dob": "1992-08-20",
  "staff_address": "234 Lab St, City",
  "staff_qualification": "BSc Medical Laboratory Technology",
  "profile_photo": "https://example.com/media/staff_photos/labtech1.jpg"
}
```

#### Update Lab Technician

**Endpoint:** `PUT /api/admin/lab-technicians/{staff_id}/`

**Authentication:** Required (with admin role)

**Request Body:**
```json
{
  "staff_name": "Updated Lab Tech Name",
  "staff_email": "updated@hospital.com",
  "staff_mobile": "9988776655",
  "on_leave": true,
  "certification": "Updated Certification",
  "lab_experience_years": 6,
  "assigned_lab": "Hematology Lab"
}
```

**Sample Response:**
```json
{
  "message": "Lab technician updated successfully"
}
```

#### Delete Lab Technician

**Endpoint:** `DELETE /api/admin/lab-technicians/{staff_id}/`

**Authentication:** Required (with admin role)

**Sample Response:**
```json
{
  "message": "Lab technician deleted successfully"
}
```

#### Create Lab Technician

**Endpoint:** `POST /api/admin/lab-technicians/create/`

**Authentication:** Required (with admin role)

**Request Body:**
```json
{
  "staff_name": "New Lab Tech",
  "staff_email": "newlabtech@hospital.com",
  "staff_mobile": "1231231234",
  "certification": "Medical Laboratory Science",
  "lab_experience_years": 2,
  "assigned_lab": "Microbiology Lab",
  "staff_joining_date": "2023-03-15"
}
```

**Sample Response:**
```json
{
  "message": "Lab technician created successfully",
  "staff_id": "LABTECH789"
}
```

### Doctor Management

#### Get All Doctors

**Endpoint:** `GET /api/admin/doctors/`

**Authentication:** Required (with admin role)

**Sample Response:**
```json
[
  {
    "staff_id": "DOC123",
    "staff_name": "Dr. Smith",
    "staff_email": "drsmith@hospital.com",
    "staff_mobile": "9876543210",
    "specialization": "Cardiology",
    "license": "MED98765",
    "experience_years": 10,
    "doctor_type": "Specialist",
    "on_leave": false
  },
  {
    "staff_id": "DOC456",
    "staff_name": "Dr. Johnson",
    "staff_email": "drjohnson@hospital.com",
    "staff_mobile": "8765432109",
    "specialization": "Pediatrics",
    "license": "MED45678",
    "experience_years": 7,
    "doctor_type": "General",
    "on_leave": true
  }
]
```

#### Get Specific Doctor

**Endpoint:** `GET /api/admin/doctors/{staff_id}/`

**Authentication:** Required (with admin role)

**Sample Response:**
```json
{
  "staff_id": "DOC123",
  "staff_name": "Dr. Smith",
  "staff_email": "drsmith@hospital.com",
  "staff_mobile": "9876543210",
  "created_at": "2020-03-15",
  "specialization": "Cardiology",
  "license": "MED98765",
  "experience_years": 10,
  "doctor_type": {
    "id": 3,
    "name": "Specialist"
  },
  "on_leave": false,
  "staff_dob": "1975-11-20",
  "staff_address": "789 Doctor St, City",
  "staff_qualification": "MBBS, MD, DM Cardiology",
  "profile_photo": "https://example.com/media/staff_photos/drsmith.jpg"
}
```

#### Update Doctor

**Endpoint:** `PUT /api/admin/doctors/{staff_id}/`

**Authentication:** Required (with admin role)

**Request Body:**
```json
{
  "staff_name": "Dr. Smith Updated",
  "staff_email": "drsmithupdated@hospital.com",
  "staff_mobile": "9876543210",
  "on_leave": true,
  "specialization": "Interventional Cardiology",
  "license": "MED98765",
  "experience_years": 11,
  "doctor_type_id": 4
}
```

**Sample Response:**
```json
{
  "message": "Doctor updated successfully"
}
```

#### Delete Doctor

**Endpoint:** `DELETE /api/admin/doctors/{staff_id}/`

**Authentication:** Required (with admin role)

**Sample Response:**
```json
{
  "message": "Doctor deleted successfully"
}
```

#### Create Doctor

**Endpoint:** `POST /api/admin/doctors/create/`

**Authentication:** Required (with admin role)

**Request Body:**
```json
{
  "staff_name": "Dr. New Doctor",
  "staff_email": "newdoctor@hospital.com",
  "staff_mobile": "1212121212",
  "specialization": "Neurology",
  "license": "MED54321",
  "experience_years": 5,
  "doctor_type_id": 3,
  "staff_joining_date": "2023-02-01"
}
```

**Sample Response:**
```json
{
  "message": "Doctor created successfully",
  "staff_id": "DOC789"
}
```

## Error Responses

All API endpoints will return appropriate error responses with HTTP status codes:

### Bad Request (400)
```json
{
  "error": "Missing required fields"
}
```

### Unauthorized (401)
```json
{
  "detail": "Authentication credentials were not provided."
}
```

### Forbidden (403)
```json
{
  "error": "Not authorized as admin"
}
```

### Not Found (404)
```json
{
  "error": "Doctor not found"
}
```

### Internal Server Error (500)
```json
{
  "error": "An unexpected error occurred",
  "details": "Error details here"
}
```