from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext as _

from core import models


class UserAdmin(BaseUserAdmin):
    """Define the admin pages for users"""

    ordering = ["id"]
    list_display = ["email"]

    # `fieldsets` define the layout of the user detail page in the admin panel
    # the fields need to match those defined in the custom user model (./core/models.py)
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        # (_("Personal Info"), {"fields": ("name",)}),
        (
            _("Permissions"),
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                )
            },
        ),
        (_("Important dates"), {"fields": ("last_login",)}),
    )
    readonly_fields = ["last_login"]  # cannot edit last_login manually

    # `add_fieldsets` define the layout of the user creation page in the admin panel
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "password1", "password2", "is_staff", "is_superuser"),
            },
        ),
    )


admin.site.register(models.User, UserAdmin)

# movies ========================================================== #
@admin.register(models.Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ("name", "slug")
    search_fields = ("name",)


@admin.register(models.Movie)
class MovieAdmin(admin.ModelAdmin):
    list_display = ("title", "release_year", "created_by", "created_at")
    list_filter = ("release_year", "genres")
    search_fields = ("title",)
    ordering = ("-release_year",)

    filter_horizontal = ("genres",)
