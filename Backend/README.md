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

# Unrestricted APIs

## 📘 API Documentation: Hospital Management System

**Base URL:** `/api/hospital/unrestricted/`

---

### 1. 🩺 Get All Doctors

**Endpoint:** `/api/hospital/unrestricted/api/doctors/`  
**Method:** `GET`  
**Auth:** JWT Token (Authenticated)

**Response:**
```json
[
  {
    "staff_id": "DOC123",
    "staff_name": "Dr. Jane Doe",
    "specialization": "Cardiology",
    "doctor_type": "Consultant",
    "on_leave": false
  }
]
```

---

### 2. 🧑‍⚕️ Doctor Detail

**Endpoint:** `/api/hospital/unrestricted/api/doctors/<staff_id>/`  
**Method:** `GET`  
**Auth:** JWT Token (Authenticated)

**Response:**
```json
{
  "staff_id": "DOC123",
  "staff_name": "Dr. Jane Doe",
  "specialization": "Cardiology",
  "doctor_type": "Consultant",
  "on_leave": false
}
```

---

### 3. 📅 Available Slots for a Doctor on a Date

**Endpoint:** `/api/hospital/unrestricted/api/doctors/<staff_id>/slots/?date=YYYY-MM-DD`  
**Method:** `GET`  
**Auth:** JWT Token (Authenticated)

**Query Param:** `date` (required, format `YYYY-MM-DD`)

**Response:**
```json
[
  {
    "slot_id": 1,
    "slot_start_time": "10:00:00",
    "slot_duration": "00:30:00",
    "is_booked": false
  }
]
```

---

### 4. 🗓️ Book Appointment

**Endpoint:** `/api/hospital/unrestricted/api/appointments/`  
**Method:** `POST`  
**Auth:** JWT Token (Authenticated)

**Request Body:**
```json
{
  "date": "2025-05-01",
  "staff_id": "DOC123",
  "slot_id": 1,
  "reason": "Routine Checkup"
}
```

**Response:**
```json
{
  "message": "Appointment booked",
  "appointment_id": 101
}
```

---

### 5. 📜 Appointment History (Patient/Doctor)

**Endpoint:** `/api/hospital/unrestricted/api/appointments/history/`  
**Method:** `GET`  
**Auth:** JWT Token (Authenticated)

**Response:**
```json
[
  {
    "appointment_id": 101,
    "date": "2025-05-01",
    "slot_id": 1,
    "staff_id": "DOC123",
    "patient_id": "PAT456",
    "status": "upcoming"
  }
]
```

---

### 6. 📋 Appointment Detail

**Endpoint:** `/api/hospital/unrestricted/api/appointments/<appointment_id>/`  
**Method:** `GET`  
**Auth:** JWT Token (Authenticated)

**Response:**
```json
{
  "appointment_id": 101,
  "date": "2025-05-01",
  "slot_id": 1,
  "staff_id": "DOC123",
  "patient_id": "PAT456",
  "prescription": {
    "prescription_id": 10,
    "remarks": "Take rest",
    "medicines": [
      {
        "medicine_name": "Paracetamol",
        "dosage": "500mg",
        "fasting_required": false
      }
    ]
  }
}
```

---

### 7. 🩺 Admin View - All Appointments

**Endpoint:** `/api/hospital/unrestricted/api/appointments/admin/`  
**Method:** `GET`  
**Auth:** JWT Token (Admin)

**Response:**
```json
[
  {
    "appointment_id": 101,
    "date": "2025-05-01",
    "slot_id": 1,
    "staff_id": "DOC123",
    "patient_id": "PAT456"
  }
]
```

---

### 8. 🧑 Patient Detail

**Endpoint:** `/api/hospital/unrestricted/api/patients/<patient_id>/`  
**Method:** `GET`  
**Auth:** JWT Token (Authenticated)

**Response:**
```json
{
  "patient_id": "PAT456",
  "patient_name": "John Smith",
  "patient_email": "john@example.com",
  "patient_mobile": "1234567890",
  "dob": "1990-01-01",
  "gender": "Male",
  "blood_group": "O+",
  "address": "123 Main St",
  "profile_photo": "http://localhost:8000/media/profile_photos/john.jpg"
}
```

---

### 9. 💓 Enter Patient Vitals

**Endpoint:** `/api/hospital/unrestricted/api/appointments/<appointment_id>/vitals/`  
**Method:** `POST`  
**Auth:** JWT Token (Authenticated)

**Request Body:**
```json
{
  "height": 170,
  "weight": 70,
  "heartrate": 80,
  "spo2": 98,
  "temperature": 98.6
}
```

**Response:**
```json
{
  "message": "Vitals saved"
}
```

---

### 10. 💊 Submit Prescription

**Endpoint:** `/api/hospital/unrestricted/api/appointments/<appointment_id>/prescription/`  
**Method:** `POST`  
**Auth:** JWT Token (Authenticated)

**Request Body:**
```json
{
  "remarks": "Take after meals",
  "medicines": [
    {
      "medicine_id": 1,
      "dosage": "1 tablet",
      "fasting_required": false
    }
  ]
}
```

**Response:**
```json
{
  "message": "Prescription submitted"
}
```

---

### 11. 🕘 Assign Doctor Shift

**Endpoint:** `/api/hospital/unrestricted/api/doctors/<staff_id>/shifts/`  
**Method:** `POST`  
**Auth:** JWT Token (Admin)

**Request Body:**
```json
{
  "shift_id": 3,
  "date": "2025-05-01"
}
```

**Response:**
```json
{
  "message": "Shift assigned"
}
```

---

### 12. ⏱️ All Slots Assigned to a Doctor

**Endpoint:** `/api/hospital/unrestricted/api/doctors/<staff_id>/all-slots/`  
**Method:** `GET`  
**Auth:** JWT Token (Authenticated)

**Response:**
```json
[
  {
    "slot_id": 1,
    "slot_start_time": "10:00:00",
    "slot_duration": "00:30:00",
    "shift": "Morning Shift",
    "date": "2025-05-01"
  }
]
```

# New APIs

# API Documentation for Hospital Management System

Below is a comprehensive guide to the new APIs for appointments, vitals, and diagnosis in your hospital management system.

## Appointment APIs

### 1. Book Appointment

**Request:**
- **Method:** POST
- **Endpoint:** `/api/appointments/`
- **Authentication:** JWT Bearer Token
- **Content-Type:** application/json

**Request Body:**
```json
{
  "date": "2025-05-15",
  "staff_id": "DOC12345AB",
  "slot_id": 3,
  "reason": "Recurring headache and fever"
}
```

**Response (201 Created):**
```json
{
  "message": "Appointment booked",
  "appointment_id": 42
}
```

**Error Response (409 Conflict):**
```json
{
  "error": "Slot already booked"
}
```

### 2. Get Appointment History

**Request:**
- **Method:** GET
- **Endpoint:** `/api/appointments/history/`
- **Authentication:** JWT Bearer Token

**Response (200 OK):**
```json
[
  {
    "appointment_id": 42,
    "date": "2025-05-15",
    "slot_id": 3,
    "staff_id": "DOC12345AB",
    "patient_id": 101,
    "status": "upcoming",
    "reason": "Recurring headache and fever"
  },
  {
    "appointment_id": 38,
    "date": "2025-04-20",
    "slot_id": 5,
    "staff_id": "DOC98765CD",
    "patient_id": 101,
    "status": "completed",
    "reason": "Annual checkup"
  }
]
```

### 3. Get Appointment Details

**Request:**
- **Method:** GET
- **Endpoint:** `/api/appointments/{appointment_id}/`
- **Authentication:** JWT Bearer Token

**Response (200 OK):**
```json
{
  "appointment_id": 42,
  "date": "2025-05-15",
  "slot_id": 3,
  "staff_id": "DOC12345AB",
  "patient_id": 101,
  "status": "upcoming",
  "reason": "Recurring headache and fever",
  "prescription": null,
  "diagnosis": null
}
```

**Response with Prescription and Diagnosis (200 OK):**
```json
{
  "appointment_id": 38,
  "date": "2025-04-20",
  "slot_id": 5,
  "staff_id": "DOC98765CD",
  "patient_id": 101,
  "status": "completed",
  "reason": "Annual checkup",
  "prescription": {
    "prescription_id": 24,
    "remarks": "Take with food",
    "medicines": [
      {
        "medicine_name": "Paracetamol",
        "dosage": {"morning": 1, "afternoon": 0, "evening": 1},
        "fasting_required": false
      }
    ]
  },
  "diagnosis": {
    "diagnosis_id": 15,
    "diagnosis_data": {
      "condition": "Seasonal flu",
      "notes": "Patient showing typical symptoms"
    },
    "lab_test_required": false,
    "follow_up_required": true
  }
}
```

### 4. Get All Appointments (Admin/Doctor)

**Request:**
- **Method:** GET
- **Endpoint:** `/api/appointments/admin/`
- **Authentication:** JWT Bearer Token (Admin/Doctor only)

**Response (200 OK):**
```json
[
  {
    "appointment_id": 42,
    "date": "2025-05-15",
    "slot_id": 3,
    "staff_id": "DOC12345AB",
    "patient_id": 101,
    "status": "upcoming",
    "reason": "Recurring headache and fever"
  },
  {
    "appointment_id": 41,
    "date": "2025-05-14",
    "slot_id": 2,
    "staff_id": "DOC12345AB",
    "patient_id": 102,
    "status": "upcoming",
    "reason": "Skin rash"
  }
]
```

## Patient Vitals APIs

### 1. Enter Patient Vitals

**Request:**
- **Method:** POST
- **Endpoint:** `/api/appointments/{appointment_id}/vitals/`
- **Authentication:** JWT Bearer Token
- **Content-Type:** application/json

**Request Body:**
```json
{
  "height": 175.5,
  "weight": 70.2,
  "heartrate": 72,
  "spo2": 98.5,
  "temperature": 36.8
}
```

**Response (201 Created):**
```json
{
  "message": "Vitals saved"
}
```

### 2. Get Latest Patient Vitals

**Request:**
- **Method:** GET
- **Endpoint:** `/api/patients/{patient_id}/latest-vitals/`
- **Authentication:** JWT Bearer Token

**Response (200 OK):**
```json
{
  "patient_height": 175.5,
  "patient_weight": 70.2,
  "patient_heartrate": 72,
  "patient_spo2": 98.5,
  "patient_temperature": 36.8,
  "created_at": "2025-04-27T10:45:00Z",
  "appointment_id": 42
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "No vitals found for this patient."
}
```

## Diagnosis APIs

### 1. Create Diagnosis

**Request:**
- **Method:** POST
- **Endpoint:** `/api/appointments/{appointment_id}/diagnosis/`
- **Authentication:** JWT Bearer Token (Doctor only)
- **Content-Type:** application/json

**Request Body:**
```json
{
  "diagnosis_data": {
    "condition": "Migraine",
    "severity": "Moderate",
    "notes": "Patient reports recurring episodes",
    "symptoms": ["Headache", "Light sensitivity", "Nausea"]
  },
  "lab_test_required": true,
  "follow_up_required": true
}
```

**Response (201 Created):**
```json
{
  "message": "Diagnosis created and appointment marked as completed",
  "diagnosis_id": 16
}
```

### 2. Get Diagnosis Details

**Request:**
- **Method:** GET
- **Endpoint:** `/api/diagnosis/{diagnosis_id}/`
- **Authentication:** JWT Bearer Token

**Response (200 OK):**
```json
{
  "diagnosis_id": 16,
  "diagnosis_data": {
    "condition": "Migraine",
    "severity": "Moderate",
    "notes": "Patient reports recurring episodes",
    "symptoms": ["Headache", "Light sensitivity", "Nausea"]
  },
  "lab_test_required": true,
  "follow_up_required": true,
  "appointment": {
    "appointment_id": 42,
    "date": "2025-04-27",
    "patient_id": 101,
    "patient_name": "John Doe",
    "staff_id": "DOC12345AB",
    "staff_name": "Dr. Sarah Smith"
  }
}
```

## Status Field Implementation

The Appointment model now includes a status field with three possible values:
- **upcoming**: Default status for new appointments
- **completed**: Set when a doctor submits a diagnosis
- **missed**: Automatically set when an appointment date has passed without a diagnosis

The status is used in all appointment-related APIs to help filter and display appointments appropriately. When a doctor creates a diagnosis for an appointment, the status is automatically updated to "completed".

## Authentication and Permissions

All APIs require JWT authentication. The token should be included in the Authorization header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Certain APIs (like creating a diagnosis) have additional permission requirements to ensure only authorized personnel can perform those actions.