from django.core.management.base import BaseCommand
from core.models import Genre

GENRES = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Fantasy',
    'Historical',
    'Horror',
    'Musical',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Thriller',
    'War',
    'Western',
]


class Command(BaseCommand):
    help = "Seeds the database with predefined movie genres."

    def handle(self, *args, **options):
        created_count = 0

        for name in GENRES:
            genre, created = Genre.objects.get_or_create(name=name)
            if created:
                created_count += 1

        self.stdout.write(self.style.SUCCESS(
            f'Successfully seeded {created_count} new genres.'
        ))
