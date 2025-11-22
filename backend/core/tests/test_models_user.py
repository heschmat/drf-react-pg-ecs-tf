""" Tests for user model """

from django.test import TestCase
from django.contrib.auth import get_user_model


class ModelTests(TestCase):
    """Tests for user model"""

    def test_create_user_with_email_successful(self):
        """Test creating a user with an email is successful"""
        email = "user1@example.com"
        password = "Testpass123"
        user = get_user_model().objects.create_user(
            # N.B. get_user_model() gets the user model defined in settings.AUTH_USER_MODEL
            # which is 'core.User' in this project
            # by default it would be 'auth.User'
            # by default, create_user() uses username, but our custom user model uses email.
            email=email,
            password=password,
        )

        self.assertEqual(user.email, email)
        # Check that the password is correctly set; uses Django's built-in method
        # to verify hashed password
        self.assertTrue(user.check_password(password))

    def test_new_user_email_normalized(self):
        """Test the email for a new user is normalized"""
        sample_emails = [
            ("USER@EXAMPLE.COM", "USER@example.com"),
            ("  John.Doe@GMAIL.COM  ", "John.Doe@gmail.com"),
            ("mixed.CASE@Outlook.Co.UK", "mixed.CASE@outlook.co.uk"),
            ("nochange@domain.com", "nochange@domain.com"),
            ("UPPERlower@Sub.Domain.COM", "UPPERlower@sub.domain.com"),
        ]

        for email, expected in sample_emails:
            user = get_user_model().objects.create_user(email, "Whatever!23")
            self.assertEqual(user.email, expected)

    def test_create_user_without_email_raises_error(self):
        """Test creating a user without an email raises a ValueError"""
        with self.assertRaises(ValueError):
            get_user_model().objects.create_user("", "Whatever!23")

    def test_create_superuser(self):
        """Test creating a superuser"""
        admin_user = get_user_model().objects.create_superuser(
            email="admin@example.com", password="Whatever!23"
        )

        self.assertTrue(admin_user.is_superuser)
        self.assertTrue(admin_user.is_staff)
