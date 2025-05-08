import decimal
from django.core.management.base import BaseCommand
from django.utils import timezone
from hospital.models import LabTestType, LabTestCharge, Unit


class Command(BaseCommand):
    help = 'Populate lab test charges for predefined LabTestType entries'

    def handle(self, *args, **kwargs):
        # Ensure INR unit exists
        inr_unit, created = Unit.objects.get_or_create(
            unit_name='INR',
            defaults={'unit_symbol': '₹', 'unit_remark': 'Indian Rupee'}
        )
        if created:
            self.stdout.write(self.style.SUCCESS('Created INR unit'))

        # Define charges data
        charges_data = [
            (1, decimal.Decimal('500.00'), 'Complete Blood Count charge'),
            (2, decimal.Decimal('300.00'), 'Blood Sugar charge'),
            (3, decimal.Decimal('200.00'), 'ESR charge'),
            (4, decimal.Decimal('250.00'), 'Urinalysis charge'),
            (5, decimal.Decimal('150.00'), 'Stool Examination charge'),
            (6, decimal.Decimal('100.00'), 'Blood Grouping charge'),
            (7, decimal.Decimal('700.00'), 'Liver Function Test charge'),
            (8, decimal.Decimal('650.00'), 'Kidney Function Test charge'),
            (9, decimal.Decimal('800.00'), 'Lipid Profile charge'),
            (10, decimal.Decimal('300.00'), 'Blood Glucose charge'),
            (11, decimal.Decimal('400.00'), 'Culture & Sensitivity (Urine) charge'),
            (12, decimal.Decimal('450.00'), 'Culture & Sensitivity (Sputum) charge'),
            (13, decimal.Decimal('1000.00'), 'Biopsy Analysis charge'),
            (14, decimal.Decimal('900.00'), 'FNAC charge'),
            (15, decimal.Decimal('1200.00'), 'X-Ray charge'),
            (16, decimal.Decimal('1100.00'), 'Ultrasound charge'),
            (17, decimal.Decimal('2500.00'), 'CT Scan charge'),
            (18, decimal.Decimal('3000.00'), 'MRI charge'),
            (19, decimal.Decimal('1800.00'), 'Mammography charge'),
        ]

        # Apply charges
        for test_type_id, amount, remark in charges_data:
            try:
                test_type = LabTestType.objects.get(test_type_id=test_type_id)
                
                # Deactivate old active charges
                LabTestCharge.objects.filter(test=test_type, is_active=True).update(is_active=False)

                # Create new active charge
                LabTestCharge.objects.create(
                    test=test_type,
                    charge_amount=amount,
                    charge_unit=inr_unit,
                    charge_remark=remark,
                    is_active=True
                )

                self.stdout.write(self.style.SUCCESS(f'Charge set for: {test_type.test_name}'))

            except LabTestType.DoesNotExist:
                self.stdout.write(self.style.WARNING(f'LabTestType with id {test_type_id} does not exist'))

        self.stdout.write(self.style.SUCCESS('Charges population completed.'))
