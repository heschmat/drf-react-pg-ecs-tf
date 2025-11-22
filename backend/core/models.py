""" Database models for the project """

from django.db import models

from django.contrib.auth.models import (
    AbstractBaseUser,
    BaseUserManager,
    PermissionsMixin,
)


class UserManager(BaseUserManager):
    """Manager for custom user model"""

    def create_user(self, email, password=None, **extra_fields):
        """Create and return a user with an email and password"""
        if not email:
            raise ValueError("Users must have an email address")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)  # Hash the password; do not store it in plain text
        # self._db ensures compatibility with multiple databases; just in case. (future-proofing)
        user.save(using=self._db)

        return user

    def create_superuser(self, email, password):
        """Create and return a superuser with given email and password"""
        user = self.create_user(email, password)
        user.is_superuser = True
        user.is_staff = True
        user.save(using=self._db)

        return user


# Custom user model
# Don't forget to set AUTH_USER_MODEL = 'core.User' in settings.py
# otherwise, Django will use the default user model.
class User(AbstractBaseUser, PermissionsMixin):
    """Custom user model that supports using email instead of username"""

    email = models.EmailField(max_length=255, unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    # Use email as the unique identifier for authentication; no username field
    USERNAME_FIELD = "email"

    # Link the custom user manager to this model
    # This allows us to use User.objects.create_user() and create_superuser() as defined above.
    objects = UserManager()

    def __str__(self):
        return self.email
