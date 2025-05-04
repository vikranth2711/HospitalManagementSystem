# your_app/management/commands/populate_lab_tests.py

from django.core.management.base import BaseCommand
from django.db import transaction
import json
from hospital.models import LabTestType, TargetOrgan, LabTestCategory


class Command(BaseCommand):
    help = 'Populates the database with lab test types and their associated target organs'

    def add_arguments(self, parser):
        parser.add_argument(
            '--category',
            type=str,
            default='General',
            help='The category name to use for the lab tests'
        )

    def handle(self, *args, **options):
        # Parse test types data
        test_types_data = [
            {
                "test_name": "Complete Blood Count (CBC)",
                "target_organ_id": 32,
                "target_organ": "Blood Vessel",
                "organ_description": "This is the blood vessel."
            },
            {
                "test_name": "Blood Sugar (Fasting/PP)",
                "target_organ_id": 7,
                "target_organ": "Pancreas",
                "organ_description": "This is the pancreas."
            },
            {
                "test_name": "ESR",
                "target_organ_id": 32,
                "target_organ": "Blood Vessel",
                "organ_description": "This is the blood vessel."
            },
            {
                "test_name": "Urinalysis",
                "target_organ_id": 11,
                "target_organ": "Bladder",
                "organ_description": "This is the bladder."
            },
            {
                "test_name": "Stool Examination",
                "target_organ_id": 9,
                "target_organ": "Large Intestine",
                "organ_description": "This is the large intestine."
            },
            {
                "test_name": "Blood Grouping & Rh Typing",
                "target_organ_id": 32,
                "target_organ": "Blood Vessel",
                "organ_description": "This is the blood vessel."
            },
            {
                "test_name": "Liver Function Test (LFT)",
                "target_organ_id": 3,
                "target_organ": "Liver",
                "organ_description": "This is the liver."
            },
            {
                "test_name": "Kidney Function Test (KFT)",
                "target_organ_id": 4,
                "target_organ": "Kidney",
                "organ_description": "This is the kidney."
            },
            {
                "test_name": "Lipid Profile",
                "target_organ_id": 32,
                "target_organ": "Blood Vessel",
                "organ_description": "This is the blood vessel."
            },
            {
                "test_name": "Blood Glucose (Fasting, PP)",
                "target_organ_id": 7,
                "target_organ": "Pancreas",
                "organ_description": "This is the pancreas."
            },
            {
                "test_name": "Culture & Sensitivity (Urine)",
                "target_organ_id": 11,
                "target_organ": "Bladder",
                "organ_description": "This is the bladder."
            },
            {
                "test_name": "Culture & Sensitivity (Sputum)",
                "target_organ_id": 2,
                "target_organ": "Lung",
                "organ_description": "This is the lung."
            },
            {
                "test_name": "Biopsy Analysis",
                "target_organ_id": 19,
                "target_organ": "Skin",
                "organ_description": "This is the skin."
            },
            {
                "test_name": "FNAC",
                "target_organ_id": 33,
                "target_organ": "Lymph Node",
                "organ_description": "This is the lymph node."
            },
            {
                "test_name": "X-Ray",
                "target_organ_id": 31,
                "target_organ": "Bone Marrow",
                "organ_description": "This is the bone marrow."
            },
            {
                "test_name": "Ultrasound (USG)",
                "target_organ_id": 3,
                "target_organ": "Liver",
                "organ_description": "This is the liver."
            },
            {
                "test_name": "CT Scan",
                "target_organ_id": 5,
                "target_organ": "Brain",
                "organ_description": "This is the brain."
            },
            {
                "test_name": "MRI",
                "target_organ_id": 5,
                "target_organ": "Brain",
                "organ_description": "This is the brain."
            },
            {
                "test_name": "Mammography",
                "target_organ_id": 19,
                "target_organ": "Skin",
                "organ_description": "This is the skin."
            }
        ]

        # Parse test schemas data
        test_schemas = {
            "Complete Blood Count (CBC)": {
                "sample_collected": "blood",
                "parameters": {
                    "Hemoglobin": { "type": "number", "unit": "g/dL", "range": "13-17" },
                    "WBC": { "type": "number", "unit": "cells/mcL", "range": "4000-11000" },
                    "Platelets": { "type": "number", "unit": "/mcL", "range": "150000-450000" },
                    "RBC": { "type": "number", "unit": "million/mcL", "range": "4.5-6.0" }
                }
            },
            "Blood Sugar (Fasting/PP)": {
                "sample_collected": "blood",
                "parameters": {
                    "Fasting": { "type": "number", "unit": "mg/dL", "range": "70-99" },
                    "Postprandial": { "type": "number", "unit": "mg/dL", "range": "<140" }
                }
            },
            "ESR": {
                "sample_collected": "blood",
                "parameters": {
                    "ESR (Male)": { "type": "number", "unit": "mm/hr", "range": "0-22" },
                    "ESR (Female)": { "type": "number", "unit": "mm/hr", "range": "0-29" }
                }
            },
            "Urinalysis": {
                "sample_collected": "urine",
                "parameters": {
                    "Color": { "type": "text", "options": ["Yellow", "Pale", "Dark"] },
                    "pH": { "type": "number", "range": "4.6-8.0" },
                    "Protein": { "type": "text", "options": ["Negative", "Trace", "Positive"] },
                    "Glucose": { "type": "text", "options": ["Negative", "Positive"] }
                }
            },
            "Stool Examination": {
                "sample_collected": "stool",
                "parameters": {
                    "Consistency": { "type": "text", "options": ["Formed", "Loose", "Watery"] },
                    "Occult Blood": { "type": "text", "options": ["Positive", "Negative"] },
                    "Parasites": { "type": "text", "options": ["Absent", "Present"] }
                }
            },
            "Blood Grouping & Rh Typing": {
                "sample_collected": "blood",
                "parameters": {
                    "Blood Group": { "type": "text", "options": ["A", "B", "AB", "O"] },
                    "Rh Factor": { "type": "text", "options": ["Positive", "Negative"] }
                }
            },
            "Liver Function Test (LFT)": {
                "sample_collected": "blood",
                "parameters": {
                    "ALT": { "type": "number", "unit": "U/L", "range": "7-56" },
                    "AST": { "type": "number", "unit": "U/L", "range": "10-40" },
                    "Bilirubin Total": { "type": "number", "unit": "mg/dL", "range": "0.1-1.2" }
                }
            },
            "Kidney Function Test (KFT)": {
                "sample_collected": "blood",
                "parameters": {
                    "Creatinine": { "type": "number", "unit": "mg/dL", "range": "0.7-1.3" },
                    "Urea": { "type": "number", "unit": "mg/dL", "range": "7-20" }
                }
            },
            "Lipid Profile": {
                "sample_collected": "blood",
                "parameters": {
                    "Total Cholesterol": { "type": "number", "unit": "mg/dL", "range": "<200" },
                    "HDL": { "type": "number", "unit": "mg/dL", "range": ">40" },
                    "LDL": { "type": "number", "unit": "mg/dL", "range": "<100" },
                    "Triglycerides": { "type": "number", "unit": "mg/dL", "range": "<150" }
                }
            },
            "Blood Glucose (Fasting, PP)": {
                "sample_collected": "blood",
                "parameters": {
                    "Fasting": { "type": "number", "unit": "mg/dL", "range": "70-99" },
                    "Postprandial": { "type": "number", "unit": "mg/dL", "range": "<140" }
                }
            },
            "Culture & Sensitivity (Urine)": {
                "sample_collected": "urine",
                "parameters": {
                    "Organism": { "type": "text", "options": ["E. coli", "Klebsiella", "Pseudomonas"] },
                    "Sensitivity": { "type": "table", "format": "Antibiotic: Sensitive/Resistant" }
                }
            },
            "Culture & Sensitivity (Sputum)": {
                "sample_collected": "sputum",
                "parameters": {
                    "Organism": { "type": "text", "options": ["Mycobacterium tuberculosis", "Streptococcus", "Klebsiella"] },
                    "Sensitivity": { "type": "table", "format": "Antibiotic: Sensitive/Resistant" }
                }
            },
            "Biopsy Analysis": {
                "sample_collected": "tissue",
                "parameters": {
                    "Histopathology": { "type": "text", "options": ["Benign", "Malignant", "Suspicious"] },
                    "Tissue Type": { "type": "text", "options": ["Epithelial", "Connective", "Muscle", "Nerve"] }
                }
            },
            "FNAC": {
                "sample_collected": "tissue",
                "parameters": {
                    "Cytology": { "type": "text", "options": ["Benign", "Malignant", "Suspicious"] },
                    "Cell Type": { "type": "text", "options": ["Lymphocytes", "Epithelial", "Macrophages", "Neutrophils"] }
                }
            },
            "X-Ray": {
                "sample_collected": "imaging",
                "parameters": {
                    "Findings": { "type": "text", "format": "Free text" }
                }
            },
            "Ultrasound (USG)": {
                "sample_collected": "imaging",
                "parameters": {
                    "Findings": { "type": "text", "format": "Free text" }
                }
            },
            "CT Scan": {
                "sample_collected": "imaging",
                "parameters": {
                    "Findings": { "type": "text", "format": "Free text" }
                }
            },
            "MRI": {
                "sample_collected": "imaging",
                "parameters": {
                    "Findings": { "type": "text", "format": "Free text" }
                }
            },
            "Mammography": {
                "sample_collected": "imaging",
                "parameters": {
                    "Findings": { "type": "text", "format": "Free text" }
                }
            }
        }

        # Define which test types require images
        imaging_tests = [
            "X-Ray", "Ultrasound (USG)", "CT Scan", "MRI", "Mammography", 
            "Biopsy Analysis", "FNAC"
        ]

        # Get or create a default test category
        category_name = options['category']
        default_category, _ = LabTestCategory.objects.get_or_create(
            test_category_name=category_name, 
            defaults={'test_category_remark': f'{category_name} laboratory tests'}
        )
        
        self.stdout.write(self.style.SUCCESS(f'Using category: {category_name}'))

        # Create or update lab test types
        with transaction.atomic():
            self.stdout.write(self.style.NOTICE('Starting to create lab test types...'))
            
            created_count = 0
            updated_count = 0
            
            # First, gather all organ IDs we need to fetch
            organ_ids = set(test_data["target_organ_id"] for test_data in test_types_data)
            
            # Fetch all target organs in a single query
            # This avoids attempting to create new organs with existing IDs
            target_organs = {
                organ.id: organ for organ in TargetOrgan.objects.filter(id__in=organ_ids)
            }
            
            self.stdout.write(f'Found {len(target_organs)} existing target organs')
            
            # Check for any missing organs that might need attention
            missing_organs = organ_ids - set(target_organs.keys())
            if missing_organs:
                self.stdout.write(self.style.WARNING(
                    f'Warning: These target organ IDs were not found in the database: {missing_organs}'
                ))
            
            # Create tests
            for test_data in test_types_data:
                test_name = test_data["test_name"]
                target_organ_id = test_data["target_organ_id"]
                
                # Get target organ from our preloaded dict
                target_organ_obj = target_organs.get(target_organ_id)
                
                if not target_organ_obj:
                    self.stdout.write(self.style.ERROR(
                        f'Error: Target organ with ID {target_organ_id} not found. Skipping test: {test_name}'
                    ))
                    continue
                
                # Get test schema
                test_schema = test_schemas.get(test_name, {})
                
                # Check if this is an imaging test
                image_required = test_name in imaging_tests
                
                # Create or update the lab test type
                test_type, created = LabTestType.objects.update_or_create(
                    test_name=test_name,
                    defaults={
                        'test_schema': test_schema,
                        'test_category': default_category,
                        'test_target_organ': target_organ_obj,
                        'image_required': image_required,
                        'test_remark': f"Standard {test_name} test targeting {test_data['target_organ']}"
                    }
                )
                
                if created:
                    created_count += 1
                    self.stdout.write(f'Created test type: {test_name}')
                else:
                    updated_count += 1
                    self.stdout.write(f'Updated test type: {test_name}')
            
            self.stdout.write(self.style.SUCCESS(
                f'Finished processing lab test types. Created: {created_count}, Updated: {updated_count}'
            ))