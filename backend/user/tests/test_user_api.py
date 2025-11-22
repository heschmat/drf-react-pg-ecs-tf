
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse

from rest_framework.test import APIClient
from rest_framework import status


""" urls.py
app_name = 'user'

urlpatterns = [
    path('create/', views.CreateUserView.as_view(), name='create'),
]
"""
URL_CREATE_USER = reverse('user:create')  # the reverse mapping comes from above file


def create_user(**params):
    return get_user_model().objects.create_user(**params)


class PublicUserAPITests(TestCase):
    """Test features of the **user** API that don't require authentication."""

    def setUp(self):
        self.client = APIClient()

        self.payload = {
            'email': 'user1@example.com',
            'password': 'Whatever!23'
        }

    def test_create_user_ok(self):
        """Test creating a new user is successful."""

        res = self.client.post(URL_CREATE_USER, self.payload)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertNotIn('password', res.data)

        # Make sure the password is set correctly for the created user.
        user = get_user_model().objects.get(email=self.payload['email'])        
        self.assertTrue(user.check_password(self.payload['password']))
        

    def test_existing_email_cannot_register(self):
        """Test if an already registered user fails registration."""
        _ = get_user_model().objects.create_user(**self.payload)
        
        # send a post request to register the user
        # but it's already been created in our db => is should fail (400 BAD REQUEST)
        res = self.client.post(URL_CREATE_USER, self.payload)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_password_too_short(self):
        """Make sure password cannot be less than 8 chars long."""
        payload = {'email': 'user1@example.com', 'password': 'Pass123'}  # len(pass) < 8
        res = self.client.post(URL_CREATE_USER, payload)

        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

        # Make sure the user has not been created:
        # N.B. .get() is not suited for our purpose (HINT: raise self.model.DoesNotExist)
        user = get_user_model().objects.filter(email=payload['email'])
        self.assertFalse(user.exists())
