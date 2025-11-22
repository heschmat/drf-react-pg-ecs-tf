from django.contrib.auth import get_user_model

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
