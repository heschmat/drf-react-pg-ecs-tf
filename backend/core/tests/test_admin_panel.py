
from django.test import TestCase
from django.contrib.auth import get_user_model  # to get the custom user model
from django.test import Client
from django.urls import reverse

from rest_framework import status

class AdminPanelTests(TestCase):
    """Tests for the Django admin panel integration with custom user model"""

    # setUp() is a special method that runs before each test method.
    # It's part of the unittest framework that Django's TestCase builds upon.
    def setUp(self):
        """Set up a test client and create a superuser for admin access"""
        self.client = Client()
        self.admin_user = get_user_model().objects.create_superuser(
            email="admin@example.com", password="Whatever!23"
        )

        # Log in the admin user using the test client
        self.client.force_login(self.admin_user)

        # Create a regular user to test listing and detail views
        self.user = get_user_model().objects.create_user(
            email="user1@example.com", password="Whatever!23"
        )

    def test_users_listed(self):
        """Test that users are listed on the user list page in admin"""
        # Get the URL for the user list page in the admin panel
        # The URL pattern for the user list page follows the format:
        # {{ app_label }}_{{ model_name }}_changelist
        # https://docs.djangoproject.com/en/5.2/ref/contrib/admin/#admin-reverse-urls
        url = reverse("admin:core_user_changelist")
        # Make a GET request to the user list page
        res = self.client.get(url)

        # Check that the response contains the user's email
        self.assertContains(res, self.user.email)

    def test_user_change_page(self):
        """Test that the user edit page works in admin"""
        # Get the URL for the user change (edit) page in the admin panel
        # The URL pattern for the user change page follows the format:
        # {{ app_label }}_{{ model_name }}_change
        url = reverse("admin:core_user_change", args=[self.user.id])  # /admin/core/user/1/change/
        # Make a GET request to the user change page
        res = self.client.get(url)

        # Check that the response status code is 200 (OK)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_user_create_page(self):
        """Test that the user create page works in admin"""
        url = reverse('admin:core_user_add')  # /admin/core/user/add/
        res = self.client.get(url)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
