from django import forms
from django.contrib.auth.models import User
from .models import UserProfile
import random
import string
import uuid
from django.utils.text import slugify
from django.contrib.auth.forms import AuthenticationForm
from .models import Issue

class CustomLoginForm(AuthenticationForm):
    """Custom login form for both Admin and Student"""
    pass

class SignupForm(forms.ModelForm):
    # Fields for UserProfile model
    student_id = forms.CharField(max_length=20, required=True)
    email = forms.EmailField(required=True)
    phone = forms.CharField(max_length=15, required=True)
    first_name = forms.CharField(max_length=30, required=True)
    last_name = forms.CharField(max_length=30, required=True)
    is_scholar = forms.BooleanField(required=False)

    class Meta:
        model = UserProfile
        fields = ['email', 'phone', 'first_name', 'last_name', 'is_scholar']

    def generate_random_password(self, length=12):
        """Generate a random secure password."""
        characters = string.ascii_letters + string.digits + string.punctuation
        return ''.join(random.choice(characters) for _ in range(length))

    def save(self, commit=True):
        # Generate username from email
        email = self.cleaned_data['email']
        base_username = slugify(email.split('@')[0])  # Slugify the email to make it URL-safe
        if not base_username:  # Fallback if email is empty
            base_username = "user"

        username = base_username
        max_retries = 5
        for _ in range(max_retries):
            if not User.objects.filter(username=username).exists():
                break
            unique_suffix = uuid.uuid4().hex[:6]  # Generate a random 6-character suffix
            username = f"{base_username}_{unique_suffix}"
        else:
            raise forms.ValidationError("Failed to generate a unique username. Please try again.")

        # Generate a random password
        password = self.generate_random_password()

        # Create User instance
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=self.cleaned_data['first_name'],
            last_name=self.cleaned_data['last_name']
        )

        # Create UserProfile instance linked to the User
        user_profile = super().save(commit=False)
        user_profile.user = user

        if commit:
            user_profile.save()

        # Optionally, return the generated password to send it to the user via email
        return user_profile, password


class UpdateProfileForm(forms.ModelForm):
    # Fields for UserProfile model
    student_id = forms.CharField(max_length=20, required=True, disabled=True)  # Student ID remains unchanged
    email = forms.EmailField(required=True)
    phone = forms.CharField(max_length=15, required=True)
    first_name = forms.CharField(max_length=30, required=True)
    last_name = forms.CharField(max_length=30, required=True)
    is_scholar = forms.BooleanField(required=False)

    class Meta:
        model = UserProfile
        fields = ['student_id', 'email', 'phone', 'first_name', 'last_name', 'is_scholar']

    def save(self, commit=True):
        # Get the current logged-in user (assuming it's passed to the form)
        user_profile = super().save(commit=False)

        if commit:
            user_profile.save()
            # Update the linked User model
            user = user_profile.user
            user.email = self.cleaned_data['email']
            user.first_name = self.cleaned_data['first_name']
            user.last_name = self.cleaned_data['last_name']
            user.save()

        return user_profile
    

# Form for User Login (only email)
class LoginForm(forms.Form):
    email = forms.EmailField()

class ProfileImageForm(forms.ModelForm):
    class Meta:
        model = UserProfile
        fields = ['profile_picture']





class IssueForm(forms.ModelForm):
    class Meta:
        model = Issue
        fields = ['title', 'description', 'priority']
        widgets = {
            'title': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Enter issue title',
            }),
            'description': forms.Textarea(attrs={
                'class': 'form-control',
                'placeholder': 'Describe the issue in detail',
                'rows': 5,
            }),
            'priority': forms.Select(attrs={
                'class': 'form-control',
            }),
        }