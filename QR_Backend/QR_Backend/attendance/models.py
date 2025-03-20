from django.db import models
import uuid
from django.contrib.auth.models import User
from django.conf import settings


class UserProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    student_id = models.CharField(max_length=20, unique=True)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, default="8968976")
    first_name = models.CharField(max_length=30, default="Bidav")
    last_name = models.CharField(max_length=30, default="Birenzi")
    is_scholar = models.BooleanField(default=False)
    qr_code_id = models.UUIDField(default=uuid.uuid4, editable=False)
    # image = models.ImageField(upload_to="profile_images/", blank=True, null=True)
    paid = models.BooleanField(default=False)
    blocked = models.BooleanField(default=False)
    profile_picture = models.ImageField(upload_to='profile_pictures/', null=True, blank=True)

    def __str__(self):
        return f"{self.first_name} {self.last_name}"

    @classmethod
    def get_user_by_student_id(cls, student_id):
        """Retrieve a UserProfile instance based on student_id and return the associated User."""
        try:
            user_profile = cls.objects.get(student_id=student_id)
            return user_profile.user
        except cls.DoesNotExist:
            return None

def get_default_user_profile():
    """Return the first UserProfile instance or raise an exception if none exists."""
    user_profile = UserProfile.objects.first()
    if user_profile:
        return user_profile
    raise ValueError("No UserProfile exists to be set as a default.")

class Attendance(models.Model):
    user_profile = models.ForeignKey(UserProfile, on_delete=models.CASCADE, default=get_default_user_profile)
    date = models.DateField(auto_now_add=True)
    time = models.TimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user_profile.user.username} - {self.date}"
    


class Issue(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    priority = models.CharField(max_length=10, choices=[('Low', 'Low'), ('Medium', 'Medium'), ('High', 'High')])
    reported_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title