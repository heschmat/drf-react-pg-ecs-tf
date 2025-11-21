
import time

from psycopg import OperationalError as PsycopgOperationalError
from django.db.utils import OperationalError

from django.core.management.base import BaseCommand


class Command(BaseCommand):
    """Django command to pause execution until database is available"""

    def handle(self, *args, **options):
        self.stdout.write("⌛ Waiting for database...")
        db_up = False
        while not db_up:
            try:
                # Attempt to check database connection
                self.check(databases=["default"])
                db_up = True
            except (PsycopgOperationalError, OperationalError):
                self.stdout.write("🕒 Database unavailable, waiting 1 second...")
                time.sleep(1)

        self.stdout.write(self.style.SUCCESS("Database available!"))
