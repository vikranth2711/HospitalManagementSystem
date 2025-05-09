# Hospital Management System API Reference

## Authentication and User Management

### Request OTP

- **URL**: `/api/accounts/request-otp/`
- **Method**: POST
- **Description**: Requests an OTP for authentication
- **Request Body**:
  ```json
  {
    "email": "patient@example.com"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "OTP sent successfully"
  }
  ```

### Verify OTP

- **URL**: `/api/accounts/verify-otp/`
- **Method**: POST
- **Description**: Verifies the OTP sent to the user
- **Request Body**:
  ```json
  {
    "email": "patient@example.com",
    "otp": "123456"
  }
  ```
- **Response**: 
  ```json
  {
    "token": "jwt_token_here",
    "user_type": "patient"
  }
  ```

### Patient Signup

- **URL**: `/api/accounts/patient-signup/`
- **Method**: POST
- **Description**: Registers a new patient
- **Request Body**:
  ```json
  {
    "patient_name": "John Doe",
    "patient_email": "john@example.com",
    "patient_mobile": "9876543210",
    "password": "securepassword"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Patient registered successfully",
    "patient_id": 123
  }
  ```

### Create Admin Staff

- **URL**: `/api/accounts/create-admin-staff/`
- **Method**: POST
- **Description**: Creates an admin staff member
- **Request Body**:
  ```json
  {
    "staff_name": "Admin User",
    "staff_email": "admin@hospital.com",
    "staff_mobile": "9876543210",
    "password": "securepassword"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Admin staff created successfully",
    "staff_id": "ADMIN123"
  }
  ```

### Change Password

- **URL**: `/api/accounts/change-password/`
- **Method**: POST
- **Authentication**: Required
- **Description**: Changes the user's password
- **Request Body**:
  ```json
  {
    "current_password": "oldpassword",
    "new_password": "newpassword"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Password changed successfully"
  }
  ```

### Initiate Email Verification

- **URL**: `/api/accounts/initiate-email-verification/`
- **Method**: POST
- **Description**: Initiates the email verification process for registration
- **Request Body**:
  ```json
  {
    "email": "newuser@example.com"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Verification email sent"
  }
  ```

### Verify Email and Create Patient

- **URL**: `/api/accounts/verify-email-create-patient/`
- **Method**: POST
- **Description**: Verifies email and creates a patient account
- **Request Body**:
  ```json
  {
    "email": "newuser@example.com",
    "verification_code": "123456",
    "name": "New User",
    "mobile": "9876543210",
    "password": "securepassword"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Patient account created",
    "patient_id": 124
  }
  ```

### Complete Patient Profile

- **URL**: `/api/accounts/complete-patient-profile/`
- **Method**: POST
- **Authentication**: Required
- **Description**: Completes the patient profile with additional details
- **Request Body**:
  ```json
  {
    "dob": "1990-01-01",
    "gender": true,
    "blood_group": "O+",
    "address": "123 Main St, City"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Profile completed successfully"
  }
  ```

### User Login

- **URL**: `/api/accounts/login/`
- **Method**: POST
- **Description**: Authenticates a user and initiates 2FA
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "OTP sent for verification",
    "email": "user@example.com"
  }
  ```

### Verify Login OTP

- **URL**: `/api/accounts/verify-login-otp/`
- **Method**: POST
- **Description**: Verifies the OTP for login
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "otp": "123456"
  }
  ```
- **Response**: 
  ```json
  {
    "token": "jwt_token_here",
    "user_type": "patient"
  }
  ```

### Patient Profile

- **URL**: `/api/accounts/patient/profile/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets the patient's profile information
- **Response**: 
  ```json
  {
    "patient_id": 123,
    "patient_name": "John Doe",
    "patient_email": "john@example.com",
    "patient_mobile": "9876543210",
    "dob": "1990-01-01",
    "gender": true,
    "blood_group": "O+",
    "address": "123 Main St, City",
    "profile_photo": "http://example.com/media/patient_photos/john.jpg"
  }
  ```


### Update Patient Profile

- **URL**: `/api/accounts/patient/update-profile/`
- **Method**: PUT
- **Authentication**: Required (Patient only)
- **Description**: Updates a patient's profile information including name, mobile number, date of birth, gender, blood group, and address

#### Request

##### Headers
- `Authorization`: JWT token for authentication
- `Content-Type`: `multipart/form-data`

##### Body Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `patient_name` | String | No | Patient's full name |
| `patient_mobile` | String | No | Patient's mobile number |
| `patient_dob` | String | No | Patient's date of birth in format YYYY-MM-DD |
| `patient_gender` | String/Boolean | No | Patient's gender (true/1/male for male, false/0/female for female) |
| `patient_blood_group` | String | No | Patient's blood group (e.g., A+, B-, O+) |
| `patient_address` | String | No | Patient's residential address |

#### Response

##### Success Response (200 OK)
```json
{
  "message": "Profile updated successfully",
  "created": false,
  "success": true
}
```

The `created` field indicates whether a new PatientDetails record was created (true) or an existing one was updated (false).

##### Error Responses

###### 400 Bad Request
```json
{"error": "Missing required fields"}
```

```json
{"error": "Invalid date format. Use YYYY-MM-DD"}
```

```json
{"error": "Mobile number already in use"}
```

###### 403 Forbidden
```json
{"error": "Not a patient account"}
```

### Update Patient Photo

- **URL**: `/api/accounts/patient/update-photo/`
- **Method**: POST
- **Authentication**: Required
- **Description**: Updates the patient's profile photo
- **Request Body**: Form data with 'profile_photo' file
- **Response**: 
  ```json
  {
    "message": "Photo updated successfully",
    "photo_url": "http://example.com/media/patient_photos/john_new.jpg"
  }
  ```

## Staff Management

### Staff Profile

- **URL**: `/api/hospital/staff/profile/`
- **Method**: GET
- **Authentication**: Required (Staff)
- **Description**: Gets the staff member's profile
- **Response**: 
  ```json
  {
    "staff_id": "DOC123",
    "staff_name": "Dr. Smith",
    "staff_email": "smith@hospital.com",
    "staff_mobile": "9876543210",
    "role": {
      "role_id": 2,
      "role_name": "Doctor"
    },
    "created_at": "2023-01-01",
    "on_leave": false,
    "staff_dob": "1980-05-15",
    "staff_address": "789 Hospital St, City",
    "staff_qualification": "MD",
    "profile_photo": "http://example.com/media/staff_photos/smith.jpg",
    "doctor_specialization": "Cardiology",
    "doctor_license": "MED12345",
    "doctor_experience_years": 10,
    "doctor_type": {
      "doctor_type_id": 1,
      "doctor_type": "Specialist"
    }
  }
  ```

### Admin Profile

- **URL**: `/api/hospital/admin/profile/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Gets the admin's profile
- **Response**: 
  ```json
  {
    "staff_id": "ADMIN123",
    "staff_name": "Admin User",
    "staff_email": "admin@hospital.com",
    "staff_mobile": "9876543210",
    "role": {
      "role_id": 1,
      "role_name": "Admin",
      "permissions": {
        "is_admin": true,
        "can_manage_staff": true,
        "can_manage_patients": true
      }
    },
    "created_at": "2023-01-01",
    "staff_dob": "1985-10-20",
    "staff_address": "456 Admin St, City",
    "staff_qualification": "MBA",
    "profile_photo": "http://example.com/media/staff_photos/admin.jpg"
  }
  ```

## Lab Technician Management

### Create Lab Technician

- **URL**: `/api/hospital/admin/lab-technicians/create/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Creates a new lab technician
- **Request Body**:
  ```json
  {
    "staff_name": "Tech User",
    "staff_email": "tech@hospital.com",
    "staff_mobile": "9876543210",
    "certification": "Medical Lab Technician",
    "lab_experience_years": 5,
    "assigned_lab": "Pathology",
    "staff_joining_date": "2023-01-15"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Lab technician created successfully",
    "staff_id": "LABTECH123"
  }
  ```

### Lab Technician List

- **URL**: `/api/hospital/admin/lab-technicians/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Lists all lab technicians
- **Response**: 
  ```json
  [
    {
      "staff_id": "LABTECH123",
      "staff_name": "Tech User",
      "staff_email": "tech@hospital.com",
      "staff_mobile": "9876543210",
      "certification": "Medical Lab Technician",
      "lab_experience_years": 5,
      "assigned_lab": "Pathology",
      "on_leave": false
    }
  ]
  ```

### Lab Technician Detail

- **URL**: `/api/hospital/admin/lab-technicians//`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Gets details of a specific lab technician
- **Response**: 
  ```json
  {
    "staff_id": "LABTECH123",
    "staff_name": "Tech User",
    "staff_email": "tech@hospital.com",
    "staff_mobile": "9876543210",
    "created_at": "2023-01-15",
    "certification": "Medical Lab Technician",
    "lab_experience_years": 5,
    "assigned_lab": "Pathology",
    "on_leave": false,
    "staff_dob": "1988-03-25",
    "staff_address": "123 Tech St, City",
    "staff_qualification": "BSc Medical Technology",
    "profile_photo": "http://example.com/media/staff_photos/tech.jpg"
  }
  ```

### Update Lab Technician

- **URL**: `/api/hospital/admin/lab-technicians//`
- **Method**: PUT
- **Authentication**: Required (Admin)
- **Description**: Updates a lab technician's details
- **Request Body**:
  ```json
  {
    "staff_name": "Tech User Updated",
    "staff_email": "tech_new@hospital.com",
    "staff_mobile": "9876543211",
    "certification": "Senior Medical Lab Technician",
    "lab_experience_years": 6,
    "assigned_lab": "Biochemistry",
    "on_leave": true,
    "staff_dob": "1988-03-25",
    "staff_address": "456 Tech St, City",
    "staff_qualification": "MSc Medical Technology",
    "profile_photo": "file_upload"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Lab technician updated successfully"
  }
  ```

### Delete Lab Technician

- **URL**: `/api/hospital/admin/lab-technicians//`
- **Method**: DELETE
- **Authentication**: Required (Admin)
- **Description**: Deletes a lab technician
- **Response**: 
  ```json
  {
    "message": "Lab technician deleted successfully"
  }
  ```

## Doctor Management

### Create Doctor

- **URL**: `/api/hospital/admin/doctors/create/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Creates a new doctor
- **Request Body**:
  ```json
  {
    "staff_name": "Dr. Johnson",
    "staff_email": "johnson@hospital.com",
    "staff_mobile": "9876543210",
    "specialization": "Neurology",
    "license": "MED67890",
    "experience_years": 8,
    "doctor_type_id": 1,
    "staff_joining_date": "2023-02-01",
    "staff_qualification": "MD, PhD",
    "staff_dob": "1982-07-10",
    "staff_address": "789 Doctor St, City"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Doctor created successfully",
    "staff_id": "DOC456"
  }
  ```

### Doctor List (Admin)

- **URL**: `/api/hospital/admin/doctors/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Lists all doctors (admin view)
- **Response**: 
  ```json
  [
    {
      "staff_id": "DOC456",
      "staff_name": "Dr. Johnson",
      "staff_email": "johnson@hospital.com",
      "staff_mobile": "9876543210",
      "specialization": "Neurology",
      "license": "MED67890",
      "experience_years": 8,
      "doctor_type": "Specialist",
      "on_leave": false
    }
  ]
  ```

### Doctor Detail (Admin)

- **URL**: `/api/hospital/admin/doctors//`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Gets details of a specific doctor (admin view)
- **Response**: 
  ```json
  {
    "staff_id": "DOC456",
    "staff_name": "Dr. Johnson",
    "staff_email": "johnson@hospital.com",
    "staff_mobile": "9876543210",
    "created_at": "2023-02-01",
    "specialization": "Neurology",
    "license": "MED67890",
    "experience_years": 8,
    "doctor_type": {
      "id": 1,
      "name": "Specialist"
    },
    "on_leave": false,
    "staff_dob": "1982-07-10",
    "staff_address": "789 Doctor St, City",
    "staff_qualification": "MD, PhD",
    "profile_photo": "http://example.com/media/staff_photos/johnson.jpg"
  }
  ```

### Update Doctor

- **URL**: `/api/hospital/admin/doctors//`
- **Method**: PUT
- **Authentication**: Required (Admin)
- **Description**: Updates a doctor's details
- **Request Body**:
  ```json
  {
    "staff_name": "Dr. Johnson Updated",
    "staff_email": "johnson_new@hospital.com",
    "staff_mobile": "9876543211",
    "specialization": "Neurosurgery",
    "license": "MED67891",
    "experience_years": 9,
    "doctor_type_id": 2,
    "on_leave": true,
    "staff_dob": "1982-07-10",
    "staff_address": "123 New St, City",
    "staff_qualification": "MD, PhD, FRCS",
    "profile_photo": "file_upload"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Doctor updated successfully"
  }
  ```

### Delete Doctor

- **URL**: `/api/hospital/admin/doctors//`
- **Method**: DELETE
- **Authentication**: Required (Admin)
- **Description**: Deletes a doctor
- **Response**: 
  ```json
  {
    "message": "Doctor deleted successfully"
  }
  ```

## Doctor Information (Patient View)

### Doctor List (General)

- **URL**: `/api/hospital/general/doctors/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Lists all doctors (patient view)
- **Response**: 
  ```json
  [
    {
      "staff_id": "DOC456",
      "staff_name": "Dr. Johnson",
      "specialization": "Neurology",
      "doctor_type": "Specialist",
      "on_leave": false
    }
  ]
  ```

### Doctor Detail (General)

- **URL**: `/api/hospital/general/doctors//`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets details of a specific doctor (patient view)
- **Response**: 
  ```json
  {
    "staff_id": "DOC456",
    "staff_name": "Dr. Johnson",
    "specialization": "Neurology",
    "doctor_type": "Specialist",
    "on_leave": false
  }
  ```

## Appointment Management

### Doctor Slots

- **URL**: `/api/hospital/general/doctors//slots/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets available slots for a doctor on a specific date
- **Query Parameters**: `date=YYYY-MM-DD`
- **Response**: 
  ```json
  [
    {
      "slot_id": 1,
      "slot_start_time": "09:00:00",
      "slot_duration": 30,
      "is_booked": false
    },
    {
      "slot_id": 2,
      "slot_start_time": "09:30:00",
      "slot_duration": 30,
      "is_booked": true
    }
  ]
  ```

### Book Appointment

- **URL**: `/api/hospital/general/appointments/`
- **Method**: POST
- **Authentication**: Required
- **Description**: Books an appointment with a doctor
- **Request Body**:
  ```json
  {
    "date": "2023-05-15",
    "staff_id": "DOC456",
    "slot_id": 1,
    "reason": "Regular checkup"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Appointment booked",
    "appointment_id": 123
  }
  ```

### Book Appointment with Payment

- **URL**: `/api/hospital/general/appointments/book-with-payment/`
- **Method**: POST
- **Authentication**: Required
- **Description**: Books an appointment and processes payment in one step
- **Request Body**:
  ```json
  {
    "date": "2025-05-15",
    "staff_id": "DOC456",
    "slot_id": 1,
    "reason": "Regular checkup",
    "payment_method_id": 2,
    "transaction_reference": "PAY_12345678",
    "payment_gateway_response": {
      "gateway_id": "razorpay_12345",
      "status": "success",
      "payment_id": "pay_abc123def456"
    }
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Appointment booked and payment processed",
    "appointment_id": 124,
    "transaction_id": 456,
    "invoice_id": 78,
    "invoice_number": "INV-20250515-0001"
  }
  ```

### Reschedule Appointment

- **URL**: `/api/hospital/general/appointments//reschedule/`
- **Method**: PUT
- **Authentication**: Required
- **Description**: Reschedules an existing appointment
- **Request Body**:
  ```json
  {
    "date": "2023-05-20",
    "slot_id": 3
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Appointment rescheduled successfully",
    "appointment_id": 124,
    "new_date": "2023-05-20",
    "new_slot_id": 3
  }
  ```

### Appointment History

- **URL**: `/api/hospital/general/appointments/history/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets appointment history for the authenticated user
- **Response**: 
  ```json
  [
    {
      "appointment_id": 123,
      "date": "2023-05-15",
      "slot_id": 1,
      "staff_id": "DOC456",
      "patient_id": 101,
      "status": "upcoming",
      "reason": "Regular checkup"
    },
    {
      "appointment_id": 122,
      "date": "2023-05-01",
      "slot_id": 2,
      "staff_id": "DOC123",
      "patient_id": 101,
      "status": "completed",
      "reason": "Fever"
    }
  ]
  ```

### Appointment Detail

- **URL**: `/api/hospital/general/appointments//`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets details of a specific appointment
- **Response**: 
  ```json
  {
    "appointment_id": 123,
    "date": "2023-05-15",
    "slot_id": 1,
    "staff_id": "DOC456",
    "patient_id": 101,
    "status": "upcoming",
    "reason": "Regular checkup",
    "prescription": null,
    "diagnosis": null
  }
  ```

### All Appointments (Admin)

- **URL**: `/api/hospital/general/appointments/admin/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Lists all appointments (admin view)
- **Response**: 
  ```json
  [
    {
      "appointment_id": 123,
      "date": "2023-05-15",
      "slot_id": 1,
      "staff_id": "DOC456",
      "patient_id": 101,
      "status": "upcoming",
      "reason": "Regular checkup"
    },
    {
      "appointment_id": 122,
      "date": "2023-05-01",
      "slot_id": 2,
      "staff_id": "DOC123",
      "patient_id": 102,
      "status": "completed",
      "reason": "Fever"
    }
  ]
  ```

## Patient Management

### Patient Detail

- **URL**: `/api/hospital/general/patients//`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets details of a specific patient
- **Response**: 
  ```json
  {
    "patient_id": 101,
    "patient_name": "John Doe",
    "patient_email": "john@example.com",
    "patient_mobile": "9876543210",
    "dob": "1990-01-01",
    "gender": true,
    "blood_group": "O+",
    "address": "123 Main St, City",
    "profile_photo": "http://example.com/media/patient_photos/john.jpg"
  }
  ```

### Latest Patient Vitals

- **URL**: `/api/hospital/general/patients//latest-vitals/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets the latest vitals for a patient
- **Response**: 
  ```json
  {
    "patient_height": 175.5,
    "patient_weight": 70.2,
    "patient_heartrate": 72,
    "patient_spo2": 98.5,
    "patient_temperature": 36.8,
    "created_at": "2023-05-01T10:30:00Z",
    "appointment_id": 122
  }
  ```

### Enter Patient Vitals

- **URL**: `/api/hospital/general/appointments//vitals/`
- **Method**: POST
- **Authentication**: Required (Staff)
- **Description**: Records vitals for a patient during an appointment
- **Request Body**:
  ```json
  {
    "height": 175.5,
    "weight": 70.2,
    "heartrate": 72,
    "spo2": 98.5,
    "temperature": 36.8
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Vitals saved"
  }
  ```

## Medical Records

### Create Diagnosis

- **URL**: `/api/hospital/general/appointments//diagnosis/`
- **Method**: POST
- **Authentication**: Required (Doctor)
- **Description**: Creates a diagnosis for an appointment
- **Request Body**:
  ```json
  {
    "diagnosis_data": [
      {
      "organ" : "Head",
      "notes": "Patient reports recurring episodes",
      "symptoms": ["Headache", "Light sensitivity", "Nausea"]
      },
      {
      "organ" : "Tail",
      "notes": "Patient reports recurring episodes",
      "symptoms": ["Headache", "Light sensitivity", "Nausea"]
      }
    ],
    "lab_test_required": true,
    "follow_up_required": false
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Diagnosis created and appointment marked as completed",
    "diagnosis_id": 45
  }
  ```

### Diagnosis Detail

- **URL**: `/api/hospital/general/diagnosis//`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets details of a specific diagnosis
- **Response**: 
  ```json
  {
    "diagnosis_id": 45,
    "diagnosis_data": {
      "symptoms": ["fever", "cough"],
      "findings": "Mild respiratory infection",
      "notes": "Rest advised"
    },
    "lab_test_required": true,
    "follow_up_required": false,
    "appointment": {
      "appointment_id": 122,
      "date": "2023-05-01",
      "patient_id": 101,
      "patient_name": "John Doe",
      "staff_id": "DOC123",
      "staff_name": "Dr. Smith"
    }
  }
  ```

### Submit Prescription

- **URL**: `/api/hospital/general/appointments//prescription/`
- **Method**: POST
- **Authentication**: Required (Doctor)
- **Description**: Submits a prescription for an appointment
- **Request Body**:
  ```json
  {
    "remarks": "Take with food",
    "medicines": [
      {
        "medicine_id": 1,
        "dosage": {"morning": 1, "afternoon": 0, "evening": 1},
        "fasting_required": false
      },
      {
        "medicine_id": 2,
        "dosage": {"morning": 1, "afternoon": 1, "evening": 1},
        "fasting_required": true
      }
    ]
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Prescription submitted"
  }
  ```

### Recommend Lab Tests
> ⚠️ **Deprecated**: This API is no longer recommended. Please use `/new-api-endpoint` instead.

- **URL**: `/api/hospital/general/appointments//recommend-lab-tests/`
- **Method**: POST
- **Authentication**: Required (Doctor)
- **Description**: Recommends lab tests for a patient
- **Request Body**:
  ```json
  {
    "lab_id": 1,
    "test_type_ids": [2, 3],
    "priority": "high",
    "test_datetime": "2023-05-10 10:00:00"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Recommended 2 lab tests",
    "lab_tests": [
      {
        "lab_test_id": 56,
        "test_type": "Blood Test"
      },
      {
        "lab_test_id": 57,
        "test_type": "Urine Analysis"
      }
    ]
  }
  ```

### Pay for Lab Test
> ⚠️ **Deprecated**: This API is no longer recommended. Please use `/new-api-endpoint` instead.

- **URL**: `/api/hospital/general/lab-tests//pay/`
- **Method**: POST
- **Authentication**: Required (Patient)
- **Description**: Processes payment for a lab test
- **Request Body**:
  ```json
  {
    "payment_method_id": 2,
    "transaction_reference": "PAY_87654321",
    "payment_gateway_response": {
      "gateway_id": "razorpay_67890",
      "status": "success",
      "payment_id": "pay_xyz789uvw456"
    }
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Payment for lab test processed successfully",
    "transaction_id": 457,
    "amount": "500.00 ₹",
    "invoice_id": 79,
    "invoice_number": "INV-20250515-0002"
  }
  ```

### Add Lab Test Results
> ⚠️ **Deprecated**: This API is no longer recommended. Please use `/new-api-endpoint` instead.

- **URL**: `/api/hospital/general/lab-tests//results/`
- **Method**: PUT
- **Authentication**: Required (Lab Technician)
- **Description**: Adds results for a lab test
- **Request Body**:
  ```json
  {
    "test_result": {
      "hemoglobin": 14.5,
      "wbc_count": 7500,
      "rbc_count": 5.2,
      "platelets": 250000,
      "notes": "All values within normal range"
    },
    "test_image": "file_upload"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Lab test results added successfully",
    "lab_test_id": 56
  }
  ```

## Schedule Management

### Doctor Schedule

- **URL**: `/api/hospital/general/doctors//schedule/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets the schedule for a doctor
- **Query Parameters**: `start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`
- **Response**: 
  ```json
  [
    {
      "date": "2023-05-15",
      "shift": {
        "shift_id": 1,
        "shift_name": "Morning",
        "start_time": "09:00:00",
        "end_time": "13:00:00"
      },
      "slots": [
        {
          "slot_id": 1,
          "start_time": "09:00:00",
          "duration": 30,
          "is_booked": false
        },
        {
          "slot_id": 2,
          "start_time": "09:30:00",
          "duration": 30,
          "is_booked": true,
          "appointment": {
            "appointment_id": 123,
            "patient_id": 101,
            "patient_name": "John Doe",
            "status": "upcoming"
          }
        }
      ]
    }
  ]
  ```

### All Doctor Schedules

- **URL**: `/api/hospital/general/doctors/schedules/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Gets schedules for all doctors on a specific date
- **Query Parameters**: `date=YYYY-MM-DD`
- **Response**: 
  ```json
  [
    {
      "doctor": {
        "staff_id": "DOC123",
        "staff_name": "Dr. Smith"
      },
      "shift": {
        "shift_id": 1,
        "shift_name": "Morning",
        "start_time": "09:00:00",
        "end_time": "13:00:00"
      },
      "slots": [
        {
          "slot_id": 1,
          "start_time": "09:00:00",
          "duration": 30,
          "is_booked": false
        },
        {
          "slot_id": 2,
          "start_time": "09:30:00",
          "duration": 30,
          "is_booked": true,
          "appointment": {
            "appointment_id": 122,
            "patient_id": 101,
            "patient_name": "John Doe",
            "status": "upcoming"
          }
        }
      ]
    }
  ]
  ```

### Set Staff Schedule

- **URL**: `/api/hospital/general/staff/set-schedule/`
- **Method**: POST
- **Authentication**: Required (Staff)
- **Description**: Sets a schedule for the authenticated staff member
- **Request Body**:
  ```json
  {
    "shift_id": 1,
    "date": "2023-05-20"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Schedule set successfully",
    "schedule_id": 78,
    "date": "2023-05-20",
    "shift": {
      "shift_id": 1,
      "shift_name": "Morning"
    }
  }
  ```

### Set Staff Slots

- **URL**: `/api/hospital/general/admin/set-slots/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Sets slots for a shift
- **Request Body**:
  ```json
  {
    "shift_id": 1,
    "slots": [
      {
        "start_time": "09:00:00",
        "duration": 30,
        "remark": "Regular slot"
      },
      {
        "start_time": "09:30:00",
        "duration": 30,
        "remark": "Regular slot"
      }
    ]
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Created 2 slots for shift Morning",
    "shift_id": 1,
    "slots": [
      {
        "slot_id": 1,
        "start_time": "09:00:00",
        "duration": 30
      },
      {
        "slot_id": 2,
        "start_time": "09:30:00",
        "duration": 30
      }
    ]
  }
  ```

### Assign Doctor Shift

- **URL**: `/api/hospital/general/doctors//shifts/`
- **Method**: POST
- **Authentication**: Required
- **Description**: Assigns a shift to a doctor
- **Request Body**:
  ```json
  {
    "shift_id": 1,
    "date": "2023-05-20"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Shift assigned"
  }
  ```

### Doctor All Slots

- **URL**: `/api/hospital/general/doctors//all-slots/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets all slots for a doctor across all schedules
- **Response**: 
  ```json
  [
    {
      "slot_id": 1,
      "slot_start_time": "09:00:00",
      "slot_duration": 30,
      "shift": "Morning",
      "date": "2023-05-15"
    },
    {
      "slot_id": 5,
      "slot_start_time": "09:00:00",
      "slot_duration": 30,
      "shift": "Morning",
      "date": "2023-05-16"
    }
  ]
  ```

## Reference Data

### Shift List

- **URL**: `/api/hospital/general/shifts/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Lists all shifts
- **Response**: 
  ```json
  [
    {
      "shift_id": 1,
      "shift_name": "Morning",
      "start_time": "09:00:00",
      "end_time": "13:00:00"
    },
    {
      "shift_id": 2,
      "shift_name": "Afternoon",
      "start_time": "14:00:00",
      "end_time": "18:00:00"
    }
  ]
  ```

### Medicine List

- **URL**: `/api/hospital/general/medicines/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Lists all medicines
- **Response**: 
  ```json
  [
    {
      "medicine_id": 1,
      "medicine_name": "Paracetamol",
      "medicine_remark": "For fever and pain"
    },
    {
      "medicine_id": 2,
      "medicine_name": "Amoxicillin",
      "medicine_remark": "Antibiotic"
    }
  ]
  ```

### Target Organ List

- **URL**: `/api/hospital/general/target-organs/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Lists all target organs
- **Response**: 
  ```json
  [
    {
      "target_organ_id": 1,
      "target_organ_name": "Heart",
      "target_organ_remark": "Cardiovascular system"
    },
    {
      "target_organ_id": 2,
      "target_organ_name": "Lungs",
      "target_organ_remark": "Respiratory system"
    }
  ]

# Transaction and Invoice API Reference

## Invoice Management

### List Invoices

- **URL**: `/api/transactions/invoices/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Lists invoices based on user type (patients see only their own, admins see all)
- **Response**: 
  ```json
  [
    {
      "invoice_id": 1,
      "invoice_number": "INV-20250504-0001",
      "invoice_datetime": "2025-05-04T10:30:00Z",
      "tran": 456,
      "invoice_type": 1,
      "invoice_type_name": "appointment",
      "patient": 101,
      "patient_name": "John Doe",
      "invoice_items": [123],
      "invoice_subtotal": 2000.00,
      "invoice_tax": 100.00,
      "invoice_total": 2100.00,
      "invoice_unit": 1,
      "unit_symbol": "$",
      "invoice_status": "paid",
      "invoice_remark": "Invoice for appointment on 2025-05-04"
    }
  ]
  ```

### Invoice Detail

- **URL**: `/api/transactions/invoices//`
- **Method**: GET
- **Authentication**: Required
- **Description**: Gets detailed information about a specific invoice
- **Response**: 
  ```json
  {
    "invoice_id": 1,
    "invoice_number": "INV-20250504-0001",
    "invoice_datetime": "2025-05-04T10:30:00Z",
    "tran": 456,
    "invoice_type": 1,
    "invoice_type_name": "appointment",
    "patient": 101,
    "patient_name": "John Doe",
    "invoice_items": [123],
    "invoice_subtotal": 2000.00,
    "invoice_tax": 100.00,
    "invoice_total": 2100.00,
    "invoice_unit": 1,
    "unit_symbol": "$",
    "invoice_status": "paid",
    "invoice_remark": "Invoice for appointment on 2025-05-04",
    "detailed_items": [
      {
        "item_id": 123,
        "item_type": "appointment",
        "doctor_name": "Dr. Johnson",
        "appointment_date": "2025-05-04",
        "slot_time": "10:30"
      }
    ]
  }
  ```

### Update Invoice Status

- **URL**: `/api/transactions/invoices/status/`
- **Method**: PUT
- **Authentication**: Required (Admin)
- **Description**: Updates the status of an invoice
- **Request Body**:
  ```json
  {
    "status": "paid"
  }
  ```
- **Response**: 
  ```json
  {
    "invoice_id": 1,
    "invoice_number": "INV-20250504-0001",
    "invoice_datetime": "2025-05-04T10:30:00Z",
    "tran": 456,
    "invoice_type": 1,
    "invoice_type_name": "appointment",
    "patient": 101,
    "patient_name": "John Doe",
    "invoice_items": [123],
    "invoice_subtotal": 2000.00,
    "invoice_tax": 100.00,
    "invoice_total": 2100.00,
    "invoice_unit": 1,
    "unit_symbol": "$",
    "invoice_status": "paid",
    "invoice_remark": "Invoice for appointment on 2025-05-04"
  }
  ```

### Generate Invoice PDF

- **URL**: `/api/transactions/invoices//pdf/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Generates a PDF version of the invoice
- **Response**: PDF file download

### Patient Invoices

- **URL**: `/api/transactions/patients//invoices/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Lists all invoices for a specific patient
- **Response**: 
  ```json
  [
    {
      "invoice_id": 1,
      "invoice_number": "INV-20250504-0001",
      "invoice_datetime": "2025-05-04T10:30:00Z",
      "tran": 456,
      "invoice_type": 1,
      "invoice_type_name": "appointment",
      "patient": 101,
      "patient_name": "John Doe",
      "invoice_items": [123],
      "invoice_subtotal": 2000.00,
      "invoice_tax": 100.00,
      "invoice_total": 2100.00,
      "invoice_unit": 1,
      "unit_symbol": "$",
      "invoice_status": "paid",
      "invoice_remark": "Invoice for appointment on 2025-05-04"
    }
  ]
  ```

## Invoice Generation

### Generate Appointment Invoice

- **URL**: `/api/transactions/appointments//generate-invoice/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Generates an invoice for an appointment
- **Response**: 
  ```json
  {
    "invoice_id": 1,
    "invoice_number": "INV-20250504-0001",
    "invoice_datetime": "2025-05-04T10:30:00Z",
    "tran": 456,
    "invoice_type": 1,
    "invoice_type_name": "appointment",
    "patient": 101,
    "patient_name": "John Doe",
    "invoice_items": [123],
    "invoice_subtotal": 2000.00,
    "invoice_tax": 100.00,
    "invoice_total": 2100.00,
    "invoice_unit": 1,
    "unit_symbol": "$",
    "invoice_status": "paid",
    "invoice_remark": "Invoice for appointment on 2025-05-04"
  }
  ```

### Generate Lab Test Invoice

- **URL**: `/api/transactions/lab-tests//generate-invoice/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Generates an invoice for a lab test
- **Response**: 
  ```json
  {
    "invoice_id": 2,
    "invoice_number": "INV-20250504-0002",
    "invoice_datetime": "2025-05-04T11:15:00Z",
    "tran": 457,
    "invoice_type": 2,
    "invoice_type_name": "lab_test",
    "patient": 101,
    "patient_name": "John Doe",
    "invoice_items": [56],
    "invoice_subtotal": 500.00,
    "invoice_tax": 25.00,
    "invoice_total": 525.00,
    "invoice_unit": 1,
    "unit_symbol": "$",
    "invoice_status": "paid",
    "invoice_remark": "Invoice for Blood Test on 2025-05-04"
  }
  ```

### Generate Multiple Lab Tests Invoice

- **URL**: `/api/transactions/lab-tests/generate-multiple-invoice/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Generates a single invoice for multiple lab tests
- **Request Body**:
  ```json
  {
    "lab_test_ids": [56, 57],
    "patient_id": 101
  }
  ```
- **Response**: 
  ```json
  {
    "invoice_id": 3,
    "invoice_number": "INV-20250504-0003",
    "invoice_datetime": "2025-05-04T11:30:00Z",
    "tran": 457,
    "invoice_type": 2,
    "invoice_type_name": "lab_test",
    "patient": 101,
    "patient_name": "John Doe",
    "invoice_items": [56, 57],
    "invoice_subtotal": 800.00,
    "invoice_tax": 40.00,
    "invoice_total": 840.00,
    "invoice_unit": 1,
    "unit_symbol": "$",
    "invoice_status": "paid",
    "invoice_remark": "Invoice for multiple lab tests on 2025-05-04"
  }
  ```

## URL Configuration

The transaction and invoice APIs are configured under the `/api/transactions/` path prefix. Here's the complete URL configuration:

```python
from django.urls import path
from . import views

urlpatterns = [
    # Invoice endpoints
    path('invoices/', views.InvoiceListView.as_view(), name='invoice-list'),
    path('invoices//', views.InvoiceDetailView.as_view(), name='invoice-detail'),
    path('invoices//status/', views.UpdateInvoiceStatusView.as_view(), name='update-invoice-status'),
    path('invoices//pdf/', views.GenerateInvoicePDFView.as_view(), name='generate-invoice-pdf'),
    path('patients//invoices/', views.PatientInvoicesView.as_view(), name='patient-invoices'),
    path('appointments//generate-invoice/', views.GenerateAppointmentInvoiceView.as_view(), name='generate-appointment-invoice'),
    path('lab-tests//generate-invoice/', views.GenerateLabTestInvoiceView.as_view(), name='generate-lab-test-invoice'),
    path('lab-tests/generate-multiple-invoice/', views.GenerateMultipleLabTestsInvoiceView.as_view(), name='generate-multiple-lab-tests-invoice'),
]
```

# Lab Management API Reference

## Lab CRUD Operations

### List All Labs

- **URL**: `/api/hospital/admin/labs/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves a list of all labs in the system
- **Response**: 
  ```json
  [
    {
      "lab_id": 1,
      "lab_name": "Pathology Lab",
      "lab_type": 1,
      "lab_type_name": "Pathology",
      "functional": true
    },
    {
      "lab_id": 2,
      "lab_name": "Radiology Lab",
      "lab_type": 2,
      "lab_type_name": "Radiology",
      "functional": true
    }
  ]
  ```

### Create Lab

- **URL**: `/api/hospital/admin/labs/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Creates a new lab
- **Request Body**:
  ```json
  {
    "lab_name": "Biochemistry Lab",
    "lab_type": 3,
    "functional": true
  }
  ```
- **Response**: 
  ```json
  {
    "lab_id": 3,
    "lab_name": "Biochemistry Lab",
    "lab_type": 3,
    "lab_type_name": "Biochemistry",
    "functional": true
  }
  ```

### Retrieve Lab

- **URL**: `/api/hospital/admin/labs//`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves details of a specific lab
- **Response**: 
  ```json
  {
    "lab_id": 1,
    "lab_name": "Pathology Lab",
    "lab_type": 1,
    "lab_type_name": "Pathology",
    "functional": true
  }
  ```

### Update Lab

- **URL**: `/api/hospital/admin/labs//`
- **Method**: PUT
- **Authentication**: Required (Admin)
- **Description**: Updates a lab's details
- **Request Body**:
  ```json
  {
    "lab_name": "Advanced Pathology Lab",
    "lab_type": 1,
    "functional": true
  }
  ```
- **Response**: 
  ```json
  {
    "lab_id": 1,
    "lab_name": "Advanced Pathology Lab",
    "lab_type": 1,
    "lab_type_name": "Pathology",
    "functional": true
  }
  ```

### Delete Lab

- **URL**: `/api/hospital/admin/labs//`
- **Method**: DELETE
- **Authentication**: Required (Admin)
- **Description**: Deletes a lab
- **Response**: 
  ```json
  {
    "message": "Lab deleted successfully"
  }
  ```

### List All Lab Test Types

- **URL**: `/api/hospital/general/lab-test-types/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves a list of all available lab test types

- **Query Parameters**:

  - `category_id` (optional): Filter test types by category

  - `target_organ_id` (optional): Filter test types by target organ

- **Response**:
  ```json
  [
    {
      "test_type_id": 1,
      "test_name": "Complete Blood Count",
      "test_schema": {
        "hemoglobin": {"type": "number", "unit": "g/dL"},
        "wbc_count": {"type": "number", "unit": "cells/μL"},
        "rbc_count": {"type": "number", "unit": "cells/μL"},
        "platelets": {"type": "number", "unit": "cells/μL"}
      },
      "test_category": {
        "category_id": 1,
        "category_name": "Hematology"
      },
      "test_target_organ": {
        "target_organ_id": 3,
        "target_organ_name": "Blood"
      },
      "image_required": false,
      "test_remark": "Basic blood test to evaluate overall health"
    },
    {
      "test_type_id": 2,
      "test_name": "Liver Function Test",
      "test_schema": {
        "alt": {"type": "number", "unit": "U/L"},
        "ast": {"type": "number", "unit": "U/L"},
        "alp": {"type": "number", "unit": "U/L"},
        "bilirubin": {"type": "number", "unit": "mg/dL"}
      },
      "test_category": {
        "category_id": 2,
        "category_name": "Biochemistry"
      },
      "test_target_organ": {
        "target_organ_id": 1,
        "target_organ_name": "Liver"
      },
      "image_required": false,
      "test_remark": "Evaluates liver function and detects liver damage"
    }
  ]
  ```

# Appointment Rating API Reference

## Rating Operations

### Create Appointment Rating

- **URL**: `/api/hospital/general/appointments//rating/`
- **Method**: POST
- **Authentication**: Required (Patient only)
- **Description**: Creates a rating for a completed appointment
- **Request Body**:
  ```json
  {
    "rating": 5,
    "rating_comment": "Excellent service and care"
  }
  ```
- **Response**: 
  ```json
  {
    "rating_id": 1,
    "appointment": 123,
    "rating": 5,
    "rating_comment": "Excellent service and care",
    "patient_name": "John Doe",
    "doctor_name": "Dr. Smith",
    "appointment_date": "2025-05-01"
  }
  ```

### Get Appointment Rating

- **URL**: `/api/hospital/general/appointments//rating/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves the rating for a specific appointment
- **Response**: 
  ```json
  {
    "rating_id": 1,
    "appointment": 123,
    "rating": 5,
    "rating_comment": "Excellent service and care",
    "patient_name": "John Doe",
    "doctor_name": "Dr. Smith",
    "appointment_date": "2025-05-01"
  }
  ```

### Update Appointment Rating

- **URL**: `/api/hospital/general/appointments//rating/`
- **Method**: PUT
- **Authentication**: Required (Patient only)
- **Description**: Updates an existing rating
- **Request Body**:
  ```json
  {
    "rating": 4,
    "rating_comment": "Very good service with minor improvements needed"
  }
  ```
- **Response**: 
  ```json
  {
    "rating_id": 1,
    "appointment": 123,
    "rating": 4,
    "rating_comment": "Very good service with minor improvements needed",
    "patient_name": "John Doe",
    "doctor_name": "Dr. Smith",
    "appointment_date": "2025-05-01"
  }
  ```

### Delete Appointment Rating

- **URL**: `/api/hospital/general/appointments//rating/`
- **Method**: DELETE
- **Authentication**: Required (Patient only)
- **Description**: Deletes a rating
- **Response**: 
  ```json
  {
    "message": "Rating deleted successfully"
  }
  ```

### Get Doctor Ratings

- **URL**: `/api/hospital/general/doctors//ratings/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves all ratings for a specific doctor
- **Query Parameters**:
  - `page`: Page number (default: 1)
  - `page_size`: Number of results per page (default: 10)
- **Response**: 
  ```json
  {
    "average_rating": 4.5,
    "total_ratings": 25,
    "page": 1,
    "page_size": 10,
    "total_pages": 3,
    "ratings": [
      {
        "rating_id": 1,
        "appointment": 123,
        "rating": 5,
        "rating_comment": "Excellent service and care",
        "patient_name": "John Doe",
        "doctor_name": "Dr. Smith",
        "appointment_date": "2025-05-01"
      },
      {
        "rating_id": 2,
        "appointment": 124,
        "rating": 4,
        "rating_comment": "Very good experience",
        "patient_name": "Jane Smith",
        "doctor_name": "Dr. Smith",
        "appointment_date": "2025-04-28"
      }
    ]
  }
  ```

### Get Patient Ratings

- **URL**: `/api/hospital/general/patient/ratings/`
- **Method**: GET
- **Authentication**: Required (Patient only)
- **Description**: Retrieves all ratings submitted by the authenticated patient
- **Query Parameters**:
  - `page`: Page number (default: 1)
  - `page_size`: Number of results per page (default: 10)
- **Response**: 
  ```json
  {
    "total_ratings": 5,
    "page": 1,
    "page_size": 10,
    "total_pages": 1,
    "ratings": [
      {
        "rating_id": 1,
        "appointment": 123,
        "rating": 5,
        "rating_comment": "Excellent service and care",
        "patient_name": "John Doe",
        "doctor_name": "Dr. Smith",
        "appointment_date": "2025-05-01"
      },
      {
        "rating_id": 3,
        "appointment": 125,
        "rating": 3,
        "rating_comment": "Average experience",
        "patient_name": "John Doe",
        "doctor_name": "Dr. Johnson",
        "appointment_date": "2025-04-15"
      }
    ]
  }
  ```

# Charge Management API Reference

## Lab Test Charge Management

### List Lab Test Charges

- **URL**: `/api/hospital/admin/lab-test-charges/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves a list of all lab test charges
- **Response**: 
  ```json
  [
    {
      "test_charge_id": 1,
      "test": 1,
      "test_name": "Complete Blood Count",
      "charge_amount": 500.00,
      "charge_unit": 1,
      "charge_unit_symbol": "₹",
      "charge_remark": "Standard blood test",
      "is_active": true,
      "created_at": "2025-05-01T10:30:00Z",
      "updated_at": "2025-05-01T10:30:00Z"
    }
  ]
  ```

### Create Lab Test Charge

- **URL**: `/api/hospital/admin/lab-test-charges/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Creates a new lab test charge
- **Request Body**:
  ```json
  {
    "test": 1,
    "charge_amount": 500.00,
    "charge_unit": 1,
    "charge_remark": "Standard blood test",
    "is_active": true
  }
  ```
- **Response**: 
  ```json
  {
    "test_charge_id": 1,
    "test": 1,
    "test_name": "Complete Blood Count",
    "charge_amount": 500.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Standard blood test",
    "is_active": true,
    "created_at": "2025-05-06T15:38:00Z",
    "updated_at": "2025-05-06T15:38:00Z"
  }
  ```

### Retrieve Lab Test Charge

- **URL**: `/api/hospital/admin/lab-test-charges//`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves details of a specific lab test charge
- **Response**: 
  ```json
  {
    "test_charge_id": 1,
    "test": 1,
    "test_name": "Complete Blood Count",
    "charge_amount": 500.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Standard blood test",
    "is_active": true,
    "created_at": "2025-05-01T10:30:00Z",
    "updated_at": "2025-05-01T10:30:00Z"
  }
  ```

### Update Lab Test Charge

- **URL**: `/api/hospital/admin/lab-test-charges//`
- **Method**: PUT
- **Authentication**: Required (Admin)
- **Description**: Updates a lab test charge
- **Request Body**:
  ```json
  {
    "charge_amount": 550.00,
    "charge_remark": "Updated standard blood test",
    "is_active": true
  }
  ```
- **Response**: 
  ```json
  {
    "test_charge_id": 1,
    "test": 1,
    "test_name": "Complete Blood Count",
    "charge_amount": 550.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Updated standard blood test",
    "is_active": true,
    "created_at": "2025-05-01T10:30:00Z",
    "updated_at": "2025-05-06T15:38:00Z"
  }
  ```

### Delete Lab Test Charge

- **URL**: `/api/hospital/admin/lab-test-charges//`
- **Method**: DELETE
- **Authentication**: Required (Admin)
- **Description**: Deletes a lab test charge
- **Response**: 
  ```json
  {
    "message": "Lab test charge deleted successfully"
  }
  ```

## Appointment Charge Management

### List Appointment Charges

- **URL**: `/api/hospital/admin/appointment-charges/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves a list of all appointment charges
- **Response**: 
  ```json
  [
    {
      "appointment_charge_id": 1,
      "doctor": "DOC123",
      "doctor_name": "Dr. Smith",
      "charge_amount": 1000.00,
      "charge_unit": 1,
      "charge_unit_symbol": "₹",
      "charge_remark": "Standard consultation",
      "is_active": true,
      "created_at": "2025-05-01T10:30:00Z",
      "updated_at": "2025-05-01T10:30:00Z"
    }
  ]
  ```

### Create Appointment Charge

- **URL**: `/api/hospital/admin/appointment-charges/`
- **Method**: POST
- **Authentication**: Required (Admin)
- **Description**: Creates a new appointment charge
- **Request Body**:
  ```json
  {
    "doctor": "DOC123",
    "charge_amount": 1000.00,
    "charge_unit": 1,
    "charge_remark": "Standard consultation",
    "is_active": true
  }
  ```
- **Response**: 
  ```json
  {
    "appointment_charge_id": 1,
    "doctor": "DOC123",
    "doctor_name": "Dr. Smith",
    "charge_amount": 1000.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Standard consultation",
    "is_active": true,
    "created_at": "2025-05-06T15:38:00Z",
    "updated_at": "2025-05-06T15:38:00Z"
  }
  ```

### Retrieve Appointment Charge

- **URL**: `/api/hospital/admin/appointment-charges//`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves details of a specific appointment charge
- **Response**: 
  ```json
  {
    "appointment_charge_id": 1,
    "doctor": "DOC123",
    "doctor_name": "Dr. Smith",
    "charge_amount": 1000.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Standard consultation",
    "is_active": true,
    "created_at": "2025-05-01T10:30:00Z",
    "updated_at": "2025-05-01T10:30:00Z"
  }
  ```

### Update Appointment Charge

- **URL**: `/api/hospital/admin/appointment-charges//`
- **Method**: PUT
- **Authentication**: Required (Admin)
- **Description**: Updates an appointment charge
- **Request Body**:
  ```json
  {
    "charge_amount": 1200.00,
    "charge_remark": "Updated consultation fee",
    "is_active": true
  }
  ```
- **Response**: 
  ```json
  {
    "appointment_charge_id": 1,
    "doctor": "DOC123",
    "doctor_name": "Dr. Smith",
    "charge_amount": 1200.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Updated consultation fee",
    "is_active": true,
    "created_at": "2025-05-01T10:30:00Z",
    "updated_at": "2025-05-06T15:38:00Z"
  }
  ```

### Delete Appointment Charge

- **URL**: `/api/hospital/admin/appointment-charges//`
- **Method**: DELETE
- **Authentication**: Required (Admin)
- **Description**: Deletes an appointment charge
- **Response**: 
  ```json
  {
    "message": "Appointment charge deleted successfully"
  }
  ```

## Patient-Facing Charge APIs

### Get Doctor Charge

- **URL**: `/api/hospital/general/doctors//charge/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves the active charge for a specific doctor
- **Response**: 
  ```json
  {
    "appointment_charge_id": 1,
    "doctor": "DOC123",
    "doctor_name": "Dr. Smith",
    "charge_amount": 1000.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Standard consultation",
    "is_active": true,
    "created_at": "2025-05-01T10:30:00Z",
    "updated_at": "2025-05-01T10:30:00Z"
  }
  ```

### Get Lab Test Charge

- **URL**: `/api/hospital/general/lab-tests//charge/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves the active charge for a specific lab test
- **Response**: 
  ```json
  {
    "test_charge_id": 1,
    "test": 1,
    "test_name": "Complete Blood Count",
    "charge_amount": 500.00,
    "charge_unit": 1,
    "charge_unit_symbol": "₹",
    "charge_remark": "Standard blood test",
    "is_active": true,
    "created_at": "2025-05-01T10:30:00Z",
    "updated_at": "2025-05-01T10:30:00Z"
  }
  ```

### Get All Lab Test Charges

- **URL**: `/api/hospital/general/lab-tests/charges/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves all active lab test charges
- **Response**: 
  ```json
  [
    {
      "test_charge_id": 1,
      "test": 1,
      "test_name": "Complete Blood Count",
      "charge_amount": 500.00,
      "charge_unit": 1,
      "charge_unit_symbol": "₹",
      "charge_remark": "Standard blood test",
      "is_active": true,
      "created_at": "2025-05-01T10:30:00Z",
      "updated_at": "2025-05-01T10:30:00Z"
    },
    {
      "test_charge_id": 2,
      "test": 2,
      "test_name": "Liver Function Test",
      "charge_amount": 800.00,
      "charge_unit": 1,
      "charge_unit_symbol": "₹",
      "charge_remark": "Comprehensive liver panel",
      "is_active": true,
      "created_at": "2025-05-01T11:15:00Z",
      "updated_at": "2025-05-01T11:15:00Z"
    }
  ]
  ```

# Lab and Lab Test API Reference

## Doctor APIs

### List All Labs

- **URL**: `/api/hospital/general/labs/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves a list of all functional labs
- **Response**: 
  ```json
  [
    {
      "lab_id": 1,
      "lab_name": "Pathology Lab",
      "lab_type": 1,
      "lab_type_name": "Pathology",
      "functional": true
    },
    {
      "lab_id": 2,
      "lab_name": "Radiology Lab",
      "lab_type": 2,
      "lab_type_name": "Radiology",
      "functional": true
    }
  ]
  ```

### List Lab Tests

- **URL**: `/api/hospital/general/lab-tests/`
- **Method**: GET
- **Authentication**: Required
- **Description**: Retrieves a list of lab tests with optional filtering
- **Query Parameters**:
  - `lab_id`: Filter by lab
  - `test_type_id`: Filter by test type
- **Response**: 
  ```json
  [
    {
      "lab_test_id": 1,
      "lab": 1,
      "lab_name": "Pathology Lab",
      "test_datetime": "2025-05-10T10:00:00Z",
      "test_result": null,
      "test_type": 1,
      "test_type_name": "Complete Blood Count",
      "appointment": 123,
      "priority": "high"
    }
  ]
  ```

## Patient APIs

### Patient Recommended Lab Tests
> ⚠️ **Deprecated**: This API is no longer recommended. Please use `/new-api-endpoint` instead.
- **URL**: `/api/hospital/general/patient/recommended-lab-tests/`
- **Method**: GET
- **Authentication**: Required (Patient)
- **Description**: Retrieves all lab tests recommended for the authenticated patient
- **Response**: 
  ```json
  [
    {
      "lab_test_id": 1,
      "lab": 1,
      "lab_name": "Pathology Lab",
      "test_datetime": "2025-05-10T10:00:00Z",
      "test_result": null,
      "test_type": 1,
      "test_type_name": "Complete Blood Count",
      "priority": "high",
      "appointment": 123
    }
  ]
  ```

## Patient Recommended Lab Tests API Reference

### Get Patient Recommended Lab Tests

- **URL**: `/api/hospital/general/patient/recommended-lab-tests/`
- **Method**: GET
- **Authentication**: Required (Patient only)
- **Description**: Retrieves all lab tests recommended for the authenticated patient

#### Query Parameters
- `status` (optional): Filter lab tests by status (recommended, paid, completed, missed, failed)

#### Response
```json
{
  "status_summary": {
    "recommended": 3,
    "paid": 2,
    "completed": 1,
    "missed": 0,
    "failed": 0,
    "total": 6
  },
  "lab_tests": [
    {
      "lab_test_id": 56,
      "lab": 1,
      "lab_name": "Central Pathology Lab",
      "test_datetime": "2025-05-10T10:00:00Z",
      "test_result": null,
      "test_type": 1,
      "test_type_name": "Complete Blood Count",
      "priority": "high",
      "appointment": 123,
      "status": "recommended",
      "charge_amount": "500.00",
      "charge_unit_symbol": "₹"
    }
  ]
}
```

## Lab Technician APIs

### Lab Technician Assigned Patients
> ⚠️ **Deprecated**: This API is no longer recommended. Please use `/new-api-endpoint` instead.

- **URL**: `/api/hospital/general/lab-technician/assigned-patients/`
- **Method**: GET
- **Authentication**: Required (Lab Technician)
- **Description**: Retrieves patients assigned to the authenticated lab technician
- **Query Parameters**:
  - `start_datetime`: Filter by start datetime
  - `end_datetime`: Filter by end datetime
- **Response**: 
  ```json
  [
    {
      "appointment_id": 123,
      "patient": 101,
      "patient_name": "John Doe",
      "staff": "LABTECH123",
      "staff_name": "Tech User",
      "slot": 1,
      "slot_start_time": "09:00:00",
      "created_at": "2025-05-01T09:00:00Z",
      "status": "upcoming",
      "reason": "Blood test"
    }
  ]
  ```

# Lab Test Status Workflow API Reference

## LabTest Model (Updated)

**Status choices:**
- `recommended`
- `paid`
- `completed`
- `missed`
- `failed`

```python
status = models.CharField(
    max_length=15,
    choices=[
        ('recommended', 'Recommended'),
        ('paid', 'Paid'),
        ('completed', 'Completed'),
        ('missed', 'Missed'),
        ('failed', 'Failed')
    ],
    default='recommended'
)
```

### 1. Recommend Lab Tests

- **URL:** `/api/hospital/general/appointments//recommend-lab-tests/`
- **Method:** `POST`
- **Auth:** Doctor
- **Description:** Recommends lab tests for a patient. All new lab tests are created with status `recommended`.
- **Request Example:**
  ```json
  {
    "test_type_ids": [2, 3],
    "priority": "high",
    "test_datetime": "2025-05-10 10:00:00"
  }
  ```
- **Response Example:**
  ```json
  {
    "message": "Recommended 2 lab tests",
    "lab_tests": [
      {
        "lab_test_id": 56,
        "test_type": "Blood Test",
        "lab_name": "Central Pathology Lab",
        "lab_type": "Pathology",
        "status": "recommended"
      }
    ]
  }
  ```

---

### 2. Pay for Lab Test

- **URL:** `/api/hospital/general/lab-tests//pay/`
- **Method:** `POST`
- **Auth:** Patient
- **Description:** Pays for a lab test. On success, sets status to `paid`.
- **Request Example:**
  ```json
  {
    "payment_method_id": 2,
    "transaction_reference": "PAY_87654321",
    "payment_gateway_response": {...}
  }
  ```
- **Response Example:**
  ```json
  {
    "message": "Payment for lab test processed successfully",
    "transaction_id": 457,
    "amount": "500.00 ₹",
    "invoice_id": 79,
    "invoice_number": "INV-20250515-0002"
  }
  ```

---

### 3. Add Lab Test Results

- **URL:** `/api/hospital/general/lab-tests//results/`
- **Method:** `PUT`
- **Auth:** Lab Technician
- **Description:** Adds results for a paid lab test and sets status to `completed`.
- **Request Example:**
  ```json
  {
    "test_result": { ... },
    "test_image": ""
  }
  ```
- **Response Example:**
  ```json
  {
    "message": "Lab test results added successfully",
    "lab_test_id": 56
  }
  ```

---

### 4. Update Lab Test Status (Missed/Failed)

- **URL:** `/api/hospital/general/lab-tests//status/`
- **Method:** `PUT`
- **Auth:** Lab Technician
- **Description:** Updates the status of a lab test to `missed` or `failed` (with optional reason).
- **Request Example:**
  ```json
  {
    "status": "missed",
    "reason": "Patient did not show up"
  }
  ```
- **Response Example:**
  ```json
  {
    "message": "Lab test status updated to missed",
    "lab_test_id": 56
  }
  ```

---

### 5. Lab Technician Assigned Patients & Lab Tests

- **URL:** `/api/hospital/general/lab-technician/assigned-patients/`
- **Method:** `GET`
- **Auth:** Lab Technician
- **Query Parameters:**
  - `start_datetime` (optional)
  - `end_datetime` (optional)
- **Description:** Returns appointments and associated lab tests for the technician’s assigned lab, **only showing tests with status `paid` or `completed`**.
- **Response Example:**
  ```json
  [
    {
      "appointment_id": 123,
      "patient": 101,
      "patient_name": "John Doe",
      "status": "upcoming",
      "lab_tests": [
        {
          "lab_test_id": 56,
          "test_type": "Blood Test",
          "test_datetime": "2025-05-10T10:00:00Z",
          "priority": "high",
          "test_result": null,
          "status": "paid",
          "is_paid": true
        }
      ]
    }
  ]
  ```

---

## LabTest Status Workflow

- **Doctor recommends test:** `status = recommended`
- **Patient pays:** `status = paid`
- **Lab tech completes test:** `status = completed`
- **Lab tech marks as missed/failed:** `status = missed` or `failed`
- **Lab tech views:** Only `paid` or `completed` tests are visible

# Analytics API Reference

## Revenue Analytics

- **URL**: `/api/machine-learning/admin/analytics/revenue/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves revenue analytics data with historical trends
- **Query Parameters**:
  - `period`: Time period for analysis (week, month, year). Default: month
- **Response**: 
  ```json
  {
    "total_revenue": 25000.00,
    "period": "month",
    "historical_data": [
      {
        "period": "2025-04-10 to 2025-04-16",
        "revenue": 5000.00
      },
      {
        "period": "2025-04-17 to 2025-04-23",
        "revenue": 6500.00
      }
    ]
  }
  ```

## Rating Analytics

- **URL**: `/api/machine-learning/admin/analytics/ratings/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves patient rating analytics with distribution and top doctors
- **Query Parameters**:
  - `period`: Time period for analysis (week, month, year). Default: month
- **Response**: 
  ```json
  {
    "average_rating": 4.2,
    "total_ratings": 120,
    "rating_distribution": {
      "5": 50,
      "4": 40,
      "3": 20,
      "2": 7,
      "1": 3
    },
    "top_rated_doctors": [
      {
        "staff_id": "DOC123",
        "staff_name": "Dr. Smith",
        "avg_rating": 4.8,
        "rating_count": 25
      }
    ],
    "historical_data": [
      {
        "period": "2025-04-10 to 2025-04-16",
        "avg_rating": 4.3,
        "count": 30
      }
    ]
  }
  ```

## Appointment Analytics

- **URL**: `/api/machine-learning/admin/analytics/appointments/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves appointment statistics and trends
- **Query Parameters**:
  - `period`: Time period for analysis (week, month, year). Default: month
- **Response**: 
  ```json
  {
    "total_appointments": 150,
    "total_patients": 100,
    "status_distribution": {
      "upcoming": 50,
      "completed": 80,
      "missed": 20
    },
    "historical_data": [
      {
        "period": "2025-04-10 to 2025-04-16",
        "count": 35
      }
    ]
  }
  ```

## Doctor Specialization Analytics

- **URL**: `/api/machine-learning/admin/analytics/doctor-specializations/`
- **Method**: GET
- **Authentication**: Required (Admin)
- **Description**: Retrieves analytics on doctor specializations and appointment distribution
- **Response**: 
  ```json
  {
    "total_doctors": 25,
    "specialization_distribution": [
      {
        "specialization": "Cardiology",
        "count": 5
      },
      {
        "specialization": "Neurology",
        "count": 3
      }
    ],
    "appointment_distribution": [
      {
        "specialization": "Cardiology",
        "appointment_count": 120
      }
    ]
  }
  ```
