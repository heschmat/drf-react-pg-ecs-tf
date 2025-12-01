
from rest_framework import generics, authentication, permissions
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.settings import api_settings

from user.serializers import (
    UserSerializer,
    AuthTokenSerializer,
)


class CreateUserView(generics.CreateAPIView):
    serializer_class = UserSerializer


class ManageUserView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    authentication_class = [authentication.TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    # when making an HTTP GET request to this endpoint, this method gets called
    # this will fetch the authenticated user and passes it over to the serializer
    # before returning the result to the API
    def get_object(self):
        return self.request.user


class CreateTokenView(ObtainAuthToken):
    serializer_class = AuthTokenSerializer
    renderer_classes = api_settings.DEFAULT_RENDERER_CLASSES
