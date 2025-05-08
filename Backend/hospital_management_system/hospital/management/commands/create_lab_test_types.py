import csv
import json
from django.core.management.base import BaseCommand
from hospital.models import LabTestType, LabTestCategory, TargetOrgan  # replace 'your_app'

class Command(BaseCommand):
    help = 'Import LabTestType data from CSV'

    def add_arguments(self, parser):
        parser.add_argument('csv_file', type=str, help='Path to the CSV file')

    def handle(self, *args, **options):
        csv_path = options['csv_file']
        with open(csv_path, newline='', encoding='utf-8-sig') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                try:
                    category = LabTestCategory.objects.get(test_category_id=int(row['test_category_id']))
                    organ = TargetOrgan.objects.get(target_organ_id=int(row['test_target_organ_id']))
                    
                    test_type, created = LabTestType.objects.update_or_create(
                        test_type_id=int(row['test_type_id']),
                        defaults={
                            'test_name': row['test_name'],
                            'test_remark': row['test_remark'] if row['test_remark'] != 'NULL' else None,
                            'test_category': category,
                            'test_target_organ': organ,
                            'image_required': row['image_required'].strip().upper() == 'TRUE',
                            'test_schema': json.loads(row['test_schema']),
                        }
                    )
                    self.stdout.write(self.style.SUCCESS(
                        f"{'Created' if created else 'Updated'}: {test_type.test_name}"
                    ))
                except LabTestCategory.DoesNotExist:
                    self.stderr.write(f"Category ID {row['test_category_id']} not found.")
                except TargetOrgan.DoesNotExist:
                    self.stderr.write(f"Target Organ ID {row['test_target_organ_id']} not found.")
                except Exception as e:
                    self.stderr.write(f"Error processing row {row}: {e}")
