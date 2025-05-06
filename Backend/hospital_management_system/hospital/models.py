from django.db import models
from transactions.models import Transaction, Unit
from django.contrib.auth.hashers import make_password, check_password

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
    password = models.CharField(max_length=128, null=True)  # New field for password

    def __str__(self):
        return self.patient_name
    
    def set_password(self, raw_password):
        self.password = make_password(raw_password)
        
    def check_password(self, raw_password):
        return check_password(raw_password, self.password)
        
    def save(self, *args, **kwargs):
        if self.password and not self.password.startswith('pbkdf2_sha256'):
            self.password = make_password(self.password)
        super().save(*args, **kwargs)

    
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
    password = models.CharField(max_length=128, null=True)  # New field for password
    
    def __str__(self):
        return self.staff_name
        
    def set_password(self, raw_password):
        self.password = make_password(raw_password)
        
    def check_password(self, raw_password):
        return check_password(raw_password, self.password)
        
    def save(self, *args, **kwargs):
        if self.password and not self.password.startswith('pbkdf2_sha256'):
            self.password = make_password(self.password)
        super().save(*args, **kwargs)


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

class Shift(models.Model):
    shift_id = models.AutoField(primary_key=True)
    shift_name = models.CharField(max_length=100)
    start_time = models.TimeField()
    end_time = models.TimeField()

    def __str__(self):
        return f"{self.shift_name} ({self.start_time} - {self.end_time})"

class Slot(models.Model):
    slot_id = models.AutoField(primary_key=True)
    slot_start_time = models.TimeField()
    slot_duration = models.IntegerField(help_text="Duration in minutes")
    shift = models.ForeignKey(Shift, on_delete=models.CASCADE, related_name='slots')
    slot_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Slot {self.slot_id} ({self.slot_start_time}, {self.slot_duration} min)"
                    
# class Appointment(models.Model):
#     appointment_id = models.AutoField(primary_key=True)
#     patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='appointments')
#     staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointments')
#     slot = models.ForeignKey(Slot, on_delete=models.CASCADE, null=False, blank=True, related_name='appointments')
#     tran = models.ForeignKey(Transaction, on_delete=models.SET_NULL, null=True, blank=True, related_name='appointments')
#     created_at = models.DateTimeField(auto_now_add=True)
#     status = models.CharField(max_length=100)
#     def __str__(self):
#         return f"Appointment for {self.patient.patient_name} with {self.staff.staff_name} at {self.created_at}"

class AppointmentCharge(models.Model):
    appointment_charge_id = models.AutoField(primary_key=True)
    doctor = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointment_charges')
    charge_amount = models.DecimalField(max_digits=10, decimal_places=2)
    charge_unit = models.ForeignKey(Unit, on_delete=models.PROTECT, related_name='appointment_charges')
    charge_remark = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Charge for Dr. {self.doctor.staff_name}: {self.charge_amount} {self.charge_unit.unit_symbol}"

class Appointment(models.Model):
    STATUS_CHOICES = (
        ('upcoming', 'Upcoming'),
        ('completed', 'Completed'),
        ('missed', 'Missed'),
    )
    
    appointment_id = models.AutoField(primary_key=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='appointments')
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointments')
    slot = models.ForeignKey(Slot, on_delete=models.CASCADE, null=False, blank=True, related_name='appointments')
    tran = models.ForeignKey(Transaction, on_delete=models.SET_NULL, null=True, blank=True, related_name='appointments')
    created_at = models.DateTimeField(auto_now_add=True)
    charge = models.ForeignKey(AppointmentCharge, on_delete=models.SET_NULL, null=True, blank=True, related_name='appointments')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='upcoming')
    reason = models.TextField(blank=True, null=True)  # Added to store appointment reason
    appointment_date = models.DateField(null=True)

    def __str__(self):
        return f"Appointment for {self.patient.patient_name} with {self.staff.staff_name} at {self.created_at}"
    
    def save(self, *args, **kwargs):
        # Auto-update status based on time if not explicitly set
        if not self.pk and not self.status:
            self.status = 'upcoming'
        super().save(*args, **kwargs)
        
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
    
########################New Models#########################

class LabType(models.Model):
    lab_type_id = models.AutoField(primary_key=True)
    lab_type_name = models.CharField(max_length=100)
    supported_tests = models.JSONField()  # List of enums or test type names

    def __str__(self):
        return self.lab_type_name

class Lab(models.Model):
    lab_id = models.AutoField(primary_key=True)
    lab_name = models.CharField(max_length=255)
    lab_type = models.ForeignKey(LabType, on_delete=models.CASCADE, related_name='labs')
    functional = models.BooleanField(default=True)

    def __str__(self):
        return self.lab_name

class LabTestCategory(models.Model):
    test_category_id = models.AutoField(primary_key=True)
    test_category_name = models.CharField(max_length=100)
    test_category_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.test_category_name

class TargetOrgan(models.Model):
    target_organ_id = models.AutoField(primary_key=True)
    target_organ_name = models.CharField(max_length=100)
    target_organ_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.target_organ_name

class LabTestType(models.Model):
    test_type_id = models.AutoField(primary_key=True)
    test_name = models.CharField(max_length=100)
    test_schema = models.JSONField(blank=True, null=True)  # JSON schema for test result structure
    test_category = models.ForeignKey(LabTestCategory, on_delete=models.CASCADE, related_name='test_types')
    test_target_organ = models.ForeignKey(TargetOrgan, on_delete=models.CASCADE, related_name='test_types')
    image_required = models.BooleanField(default=False)  # Whether image is required for this test
    test_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.test_name

class Diagnosis(models.Model):
    diagnosis_id = models.AutoField(primary_key=True)
    diagnosis_data = models.JSONField()
    appointment = models.ForeignKey('Appointment', on_delete=models.CASCADE, related_name='diagnoses')
    lab_test_required = models.BooleanField(default=False)
    follow_up_required = models.BooleanField(default=False)

    def __str__(self):
        return f"Diagnosis for Appointment {self.appointment_id}"

# class LabTest(models.Model):
#     lab_test_id = models.AutoField(primary_key=True)
#     lab = models.ForeignKey(Lab, on_delete=models.CASCADE, related_name='lab_tests')
#     test_datetime = models.DateTimeField()
#     test_result = models.JSONField()
#     test_type = models.ForeignKey(LabTestType, on_delete=models.CASCADE, related_name='lab_tests')
#     charge = models.ForeignKey(LabTestCharge, on_delete=models.SET_NULL, null=True, blank=True, related_name='lab_tests')
#     appointment = models.ForeignKey(Appointment, on_delete=models.CASCADE, related_name='lab_tests')
#     tran = models.ForeignKey(Transaction, on_delete=models.SET_NULL, null=True, blank=True, related_name='lab_tests')

#     def __str__(self):
#         return f"Lab Test {self.lab_test_id} ({self.test_type.test_name})"

class LabTest(models.Model):
    class Priority(models.TextChoices):
        HIGH = 'high', 'High'
        MEDIUM = 'medium', 'Medium'
        LOW = 'low', 'Low'

    lab_test_id = models.AutoField(primary_key=True)
    lab = models.ForeignKey('Lab', on_delete=models.CASCADE, related_name='lab_tests')
    test_datetime = models.DateTimeField()
    test_result = models.JSONField(blank=True, null=True)
    test_type = models.ForeignKey('LabTestType', on_delete=models.CASCADE, related_name='lab_tests')
    appointment = models.ForeignKey('Appointment', on_delete=models.CASCADE, related_name='lab_tests')
    tran = models.ForeignKey(Transaction, on_delete=models.SET_NULL, null=True, blank=True, related_name='lab_tests') #####Changed
    test_image = models.ImageField(upload_to='lab_test_images/', null=True, blank=True)  # Optional image
    priority = models.CharField(
        max_length=10,
        choices=Priority.choices,
        default=Priority.MEDIUM
    )

    def __str__(self):
        return f"Lab Test {self.lab_test_id} ({self.test_type.test_name})"


class FollowUp(models.Model):
    follow_up_id = models.AutoField(primary_key=True)
    appointment = models.ForeignKey(Appointment, on_delete=models.CASCADE, related_name='follow_ups')
    follow_up_date = models.DateField()
    follow_up_remarks = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Follow Up for Appointment {self.appointment_id} on {self.follow_up_date}"

class Leave(models.Model):
    leave_id = models.AutoField(primary_key=True)
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='leaves')
    leave_reason = models.CharField(max_length=255)
    leave_start = models.DateField()
    leave_end = models.DateField()
    leave_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Leave for {self.staff.staff_name} from {self.leave_start} to {self.leave_end}"



class Schedule(models.Model):
    schedule_id = models.AutoField(primary_key=True)
    schedule_date = models.DateField()
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='schedules')
    shift = models.ForeignKey(Shift, on_delete=models.CASCADE, related_name='schedules')

    def __str__(self):
        return f"{self.staff.staff_name} - {self.shift.shift_name} on {self.schedule_date}"

class Medicine(models.Model):
    medicine_id = models.AutoField(primary_key=True)
    medicine_name = models.CharField(max_length=255)
    medicine_remark = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.medicine_name

class Prescription(models.Model):
    prescription_id = models.AutoField(primary_key=True)
    appointment = models.ForeignKey(Appointment, on_delete=models.CASCADE, related_name='prescriptions')
    prescription_remarks = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Prescription {self.prescription_id} for Appointment {self.appointment_id}"

class PrescribedMedicine(models.Model):
    prescribed_medicine_id = models.AutoField(primary_key=True)
    prescription = models.ForeignKey(Prescription, on_delete=models.CASCADE, related_name='prescribed_medicines')
    medicine = models.ForeignKey(Medicine, on_delete=models.CASCADE, related_name='prescribed_medicines')
    medicine_dosage = models.JSONField(help_text='e.g. {"morning": 1, "evening": 2}')
    fasting_required = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.medicine.medicine_name} for Prescription {self.prescription_id}"


class LabTestCharge(models.Model):
    test_charge_id = models.AutoField(primary_key=True)
    test = models.ForeignKey('LabTestType', on_delete=models.CASCADE, related_name='charges')
    charge_amount = models.DecimalField(max_digits=10, decimal_places=2)
    charge_unit = models.ForeignKey(Unit, on_delete=models.PROTECT, related_name='lab_test_charges')
    charge_remark = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Charge for {self.test.test_name}: {self.charge_amount} {self.charge_unit.unit_symbol}"

class AppointmentRating(models.Model):
    rating_id = models.AutoField(primary_key=True)
    appointment = models.ForeignKey(Appointment, on_delete=models.CASCADE, related_name='ratings')
    rating = models.IntegerField()
    rating_comment = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Rating for Appointment {self.appointment_id}: {self.rating}"