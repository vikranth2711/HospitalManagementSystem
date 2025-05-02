from django.core.management.base import BaseCommand
from hospital.models import Shift, Slot  # replace 'yourapp' with your app name
from datetime import datetime, timedelta

class Command(BaseCommand):
    help = 'Create 20-minute slots for each shift'

    def handle(self, *args, **options):
        shifts = Shift.objects.all()
        slot_duration_minutes = 20
        total_slots_created = 0

        for shift in shifts:
            shift_start = datetime.combine(datetime.today(), shift.start_time)
            shift_end = datetime.combine(datetime.today(), shift.end_time)
            
            # Handle shifts that cross midnight
            if shift_end <= shift_start:
                shift_end += timedelta(days=1)

            current_start = shift_start

            while current_start + timedelta(minutes=slot_duration_minutes) <= shift_end:
                Slot.objects.create(
                    slot_start_time=current_start.time(),
                    slot_duration=slot_duration_minutes,
                    shift=shift,
                    slot_remark=f"{shift.shift_name} Slot starting at {current_start.time()}"
                )
                current_start += timedelta(minutes=slot_duration_minutes)
                total_slots_created += 1

        self.stdout.write(self.style.SUCCESS(f"Successfully created {total_slots_created} slots!"))
