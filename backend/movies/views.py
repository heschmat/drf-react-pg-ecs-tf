from rest_framework import viewsets
from rest_framework.permissions import AllowAny

from core.models import Movie, Genre
from .serializers import MovieSerializer, GenreSerializer


class GenreViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Genre.objects.all().order_by('name')
    serializer_class = GenreSerializer
    permission_classes = [AllowAny]


class MovieViewSet(viewsets.ModelViewSet):
    queryset = Movie.objects.all().prefetch_related('genres')
    serializer_class = MovieSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
