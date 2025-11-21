
from unittest.mock import patch

from psycopg import OperationalError as PsycopgOperationalError
from django.db.utils import OperationalError
from django.test import SimpleTestCase

from django.core.management import call_command


@patch("core.management.commands.wait_for_db.Command.check")
class CommandTests(SimpleTestCase):
    """Tests for 'wait_for_db' command"""

    # @patch decorator is used to mock the database check method
    # check is a method of BaseCommand that checks database connectivity
    def test_wait_for_db_ready(self, patched_check):
        """Test waiting for database if database is ready"""
        # Set the return value of the mocked check method to True
        patched_check.return_value = True

        # Call the custom management command 'wait_for_db'
        call_command("wait_for_db")

        # Assert that the check method was called exactly once with the default database
        # default database refers to the database defined in settings.py
        patched_check.assert_called_once_with(databases=["default"])

    @patch("time.sleep")  # Mock time.sleep to avoid actual delay during tests
    def test_wait_for_db_delay(self, patched_sleep, patched_check):
        """Test waiting for database when getting OperationalError"""
        # Simulate OperationalError for the first five calls, then return True
        # The side_effect list simulates the sequence of return values/exceptions
        # PsycopgOperationalError: Simulates the database being down
        # OperationalError: Simulates a generic operational error, e.g., connection issues
        # Finally, returns True indicating the database is up
        patched_check.side_effect = [PsycopgOperationalError] * 2 + [OperationalError] * 3 + [True]

        # Call the custom management command 'wait_for_db'
        call_command("wait_for_db")

        # Assert that the check method was called six times in total
        self.assertEqual(patched_check.call_count, 6)

        # Finally, assert that the last call was with the default database
        patched_check.assert_called_with(databases=["default"])
