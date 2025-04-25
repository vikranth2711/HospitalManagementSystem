from django.db import models

class Role(models.Model):
    role_id = models.AutoField(primary_key=True)
    role_name = models.CharField(max_length=100)
    role_permissions = models.JSONField()

    def __str__(self):
        return self.role_name

class Patient(models.Model):
    patient_id = models.AutoField(primary_key=True)
    patient_name = models.CharField(max_length=255)
    patient_email = models.EmailField()
    patient_mobile = models.CharField(max_length=20)
    is_authenticated = models.BooleanField(default=True)
    patient_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.patient_name
    
class PatientDetails(models.Model):
    patient = models.OneToOneField(Patient, on_delete=models.CASCADE, related_name='details')
    patient_dob = models.DateField()
    patient_gender = models.BooleanField()
    patient_blood_group = models.CharField(max_length=5)
    patient_address = models.TextField()
    profile_photo = models.ImageField(upload_to='patient_photos/', null=True, blank=True)
    
    def __str__(self):
        return f"Details for {self.patient.patient_name}"

class Staff(models.Model):
    staff_id = models.CharField(primary_key=True, max_length=50)
    staff_name = models.CharField(max_length=255)
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='staff')
    created_at = models.DateField()
    staff_email = models.EmailField()
    staff_mobile = models.CharField(max_length=20)
    on_leave = models.BooleanField(default=False)
    is_authenticated = models.BooleanField(default=True)
    
    def __str__(self):
        return self.staff_name

class StaffDetails(models.Model):
    staff = models.OneToOneField(Staff, on_delete=models.CASCADE, related_name='staff_details')
    staff_dob = models.DateField()
    staff_address = models.TextField()
    staff_qualification = models.CharField(max_length=255)
    profile_photo = models.ImageField(upload_to='staff_photos/', null=True, blank=True)

    def __str__(self):
        return f"Details for {self.staff.staff_name}"

class DoctorType(models.Model):
    doctor_type_id = models.AutoField(primary_key=True)
    doctor_type = models.CharField(max_length=100)
    doctor_type_remark = models.TextField(blank=True, null=True)
    def __str__(self):
        return self.doctor_type

class DoctorDetails(models.Model):
    staff = models.OneToOneField(Staff, on_delete=models.CASCADE, primary_key=True, related_name='doctor_details')
    doctor_specialization = models.CharField(max_length=255)
    doctor_license = models.CharField(max_length=255)
    doctor_experience_years = models.IntegerField()
    doctor_type = models.ForeignKey(DoctorType, on_delete=models.CASCADE, related_name='doctor_details')

    def __str__(self):
        return f"Doctor: {self.staff.staff_name}"

class LabTechnicianDetails(models.Model):
    staff = models.OneToOneField(Staff, on_delete=models.CASCADE, primary_key=True, related_name='lab_tech_details')
    certification = models.CharField(max_length=255)
    lab_experience_years = models.IntegerField()
    assigned_lab = models.CharField(max_length=255)

    def __str__(self):
        return f"Lab Technician: {self.staff.staff_name}"
                
class Appointment(models.Model):
    appointment_id = models.AutoField(primary_key=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='appointments')
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointments')

class PatientVitals(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='vitals')
    appointment_id = models.ForeignKey(Appointment, on_delete=models.CASCADE, related_name='vitals')
    patient_height = models.FloatField()
    patient_weight = models.FloatField()
    patient_heartrate = models.IntegerField()
    patient_spo2 = models.FloatField()
    patient_temperature = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Vitals for {self.patient.patient_name} at {self.created_at}"
    
