
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile,Attendance

class SignupSerializer(serializers.ModelSerializer):
    student_id = serializers.CharField()
    phone = serializers.CharField()
    is_scholar = serializers.BooleanField()

    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'student_id', 'phone', 'is_scholar']

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()

class OTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(max_length=6)

class AttendanceSerializer(serializers.ModelSerializer):
    qr_code_id = serializers.UUIDField()

    class Meta:
        model = Attendance
        fields = ['qr_code_id']