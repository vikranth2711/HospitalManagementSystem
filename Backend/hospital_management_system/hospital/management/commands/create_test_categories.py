# your_app/management/commands/create_lab_test_categories.py

from django.core.management.base import BaseCommand
from hospital.models import LabTestCategory

class Command(BaseCommand):
    help = 'Create default lab test categories'

    def handle(self, *args, **options):
        categories = ['blood', 'urine', 'stool', 'sputum', 'tissue', 'imaging']
        created = 0

        for name in categories:
            obj, was_created = LabTestCategory.objects.get_or_create(
                test_category_name=name,
                defaults={'test_category_remark': f'Default remark for {name}'}
            )
            if was_created:
                created += 1
                self.stdout.write(self.style.SUCCESS(f'Created category: {name}'))
            else:
                self.stdout.write(self.style.WARNING(f'Category already exists: {name}'))

        self.stdout.write(self.style.SUCCESS(f'Total new categories created: {created}'))
