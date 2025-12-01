
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
urls = {
    'create_user': reverse('user:create-user'),  # the reverse mapping comes from above file
    'token': reverse('user:create-token'),
    'profile': reverse('user:profile'),
}


# def create_user(**params):
#     return get_user_model().objects.create_user(**params)


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

        res = self.client.post(urls['create_user'], self.payload)
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
        res = self.client.post(urls['create_user'], self.payload)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_password_too_short(self):
        """Make sure password cannot be less than 8 chars long."""
        payload = {'email': 'user1@example.com', 'password': 'Pass123'}  # len(pass) < 8
        res = self.client.post(urls['create_user'], payload)

        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

        # Make sure the user has not been created:
        # N.B. .get() is not suited for our purpose (HINT: raise self.model.DoesNotExist)
        user = get_user_model().objects.filter(email=payload['email'])
        self.assertFalse(user.exists())

    def test_create_token_for_user_ok(self):
        """Test token gets crated when valid credentials are passed."""
        _ = get_user_model().objects.create_user(**self.payload)
        res = self.client.post(urls['token'], self.payload)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('token', res.data)

    def test_create_token_for_invalid_credentials_fail(self):
        """Test token wont get created with invalid credentials."""
        _ = get_user_model().objects.create_user(**self.payload)

        invalid_payload = {'email': self.payload['email'], 'password': 'InvalidPass!'}
        res = self.client.post(urls['token'], invalid_payload)

        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertNotIn('token', res.data)

    def test_unauthenticated_user_cannot_view_profile(self):
        res = self.client.get(urls['profile'])
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        # self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)


class AuthenticatedUserAPITests(TestCase):

    def setUp(self):
        self.user = get_user_model().objects.create_user(
            email='user1@example.com',
            password='Whatever!23',
        )

        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_authenticated_user_checks_profile_ok(self):
        res = self.client.get(urls['profile'])

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data, {'email': self.user.email})

    def test_post_method_not_allowed_on_profile(self):
        res = self.client.post(urls['profile'], data={})

        self.assertEqual(res.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

    def test_authenticated_user_updates_profile_ok(self):
        payload = {'password': 'ThisPasswordIsNew!'}
        res = self.client.patch(urls['profile'], payload)
        self.user.refresh_from_db()

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(self.user.email, self.user.email)
        self.assertTrue(self.user.check_password(payload['password']))
