# Hospital Management System API Reference

This document provides a comprehensive reference for all APIs in the Hospital Management System, organized by functional areas.

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
- **Authentication**: Required
- **Description**: Updates the patient's profile information
- **Request Body**:
  ```json
  {
    "patient_name": "John Smith",
    "patient_mobile": "9876543211",
    "address": "456 New St, City"
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Profile updated successfully"
  }
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
- **Description**: Books an appointment with payment
- **Request Body**:
  ```json
  {
    "date": "2023-05-15",
    "staff_id": "DOC456",
    "slot_id": 1,
    "reason": "Regular checkup",
    "payment_method_id": 2
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Appointment booked and payment processed",
    "appointment_id": 124,
    "transaction_id": 456
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
    "diagnosis_data": {
      "symptoms": ["fever", "cough"],
      "findings": "Mild respiratory infection",
      "notes": "Rest advised"
    },
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

- **URL**: `/api/hospital/general/lab-tests//pay/`
- **Method**: POST
- **Authentication**: Required (Patient)
- **Description**: Processes payment for a lab test
- **Request Body**:
  ```json
  {
    "payment_method_id": 2
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Payment for lab test processed successfully",
    "transaction_id": 457,
    "amount": "500.00 $"
  }
  ```

### Add Lab Test Results

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