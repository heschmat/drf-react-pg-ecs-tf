from django.contrib.auth import get_user_model, authenticate
from django.utils.translation import gettext as _

from rest_framework import serializers


class UserSerializer(serializers.ModelSerializer):

    class Meta:
        model = get_user_model()
        fields = ['email', 'password']  # required fields when creating the user
        extra_kwargs = {
            'password': {'write_only': True, 'min_length': 8}
        }

    # only if the input data is valid, the `create()` method gets called:
    # for example, if `password` is short (less than 8), validation fails.
    # NOTE: UserSerializer.create() calls UserManager.create_user(); define in ./core/models.py
    def create(self, validated_data):
        return get_user_model().objects.create_user(**validated_data)

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        user = super().update(instance, validated_data)

        if password:
            user.set_password(password)
            user.save()
        return user


class AuthTokenSerializer(serializers.Serializer):
    """serializer for the user auth token"""
    email = serializers.EmailField()
    password = serializers.CharField(
        style={'input_type', 'password'},  # shows *** instead of actuall password
        trim_whitespace=False
    )

    def validate(self, attr):
        user = authenticate(
            request=self.context.get('request'),
            username=attr.get('email'),
            password=attr.get('password')
        )

        if not user:
            msg = _('email and password do not match')
            raise serializers.ValidationError(msg, code='authorization')

        attr['user'] = user
        return attr
