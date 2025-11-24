from rest_framework import serializers

from core.models import Genre, Movie


class GenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Genre
        fields = ['id', 'name', 'slug']


class MovieSerializer(serializers.ModelSerializer):
    genres = GenreSerializer(many=True, read_only=True)

    # Allow sending genre IDs when writing
    genres_ids = serializers.PrimaryKeyRelatedField(
        many=True,
        write_only=True,
        queryset=Genre.objects.all(),
        source='genres'
    )

    class Meta:
        model = Movie
        fields = [
            'id',
            'title',
            'description',
            'release_year',
            'poster',
            'genres',
            'genres_ids',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def validate_genres(self, genres):
        if not (1 <= len(genres) <= 4):
            raise serializers.ValidationError('Movies must have 1–4 genres.')
        return genres

    def create(self, validated_data):
        genres = validated_data.pop('genres', [])
        movie = Movie.objects.create(**validated_data)
        movie.genres.set(genres)
        return movie

    def update(self, instance, validated_data):
        genres = validated_data.pop('genres', None)
        movie = super().update(instance, validated_data)

        if genres is not None:
            movie.genres.set(genres)

        return movie
