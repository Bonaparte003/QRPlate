from django.shortcuts import render, redirect,get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from .forms import  SignupForm, LoginForm, ProfileImageForm,UpdateProfileForm,IssueForm
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
import qrcode
from io import BytesIO
from django.core.files.storage import FileSystemStorage
from django.http import HttpResponse, JsonResponse

from .models import UserProfile, Attendance

from django.conf import settings
import base64
from django.views.decorators.csrf import csrf_exempt  # For bypassing CSRF protection for QR scanners
from django.contrib.admin.views.decorators import staff_member_required 
from uuid import UUID
import uuid
import random
from django.core.mail import send_mail
from datetime import timedelta
from django.utils.crypto import get_random_string


from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated,IsAdminUser

from rest_framework_simplejwt.tokens import RefreshToken, AccessToken
from rest_framework_simplejwt.authentication import JWTAuthentication
from .serializers import SignupSerializer, LoginSerializer, OTPSerializer, AttendanceSerializer
from rest_framework.views import APIView
import datetime
from django.contrib.sessions.models import Session
from datetime import date
import json
from django.utils import timezone
from django.utils.text import slugify
import uuid
import logging
from django.contrib.auth.hashers import check_password
from rest_framework import status

from django.template.loader import get_template
from xhtml2pdf import pisa

from django.core.mail import EmailMessage
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.contrib.staticfiles.storage import staticfiles_storage
import os
from django.db.models import Q

from django.shortcuts import get_list_or_404

logger = logging.getLogger(__name__)





def handler404(request, exception):
    return render(request, '404.html', status=404)

def handler403(request, exception):
    return render(request, '403.html', status=403)

def handler500(request):
    return render(request, '500.html', status=500)

def handler400(request, exception):
    return render(request, '400.html', status=400)

# Set OTP expiration time (e.g., 5 minutes)
OTP_EXPIRATION_TIME = datetime.timedelta(minutes=5)



@login_required
@staff_member_required
def admin_landing(request):
    return render(request, "attendance/home_admin.html")


@login_required
@staff_member_required
def scan_page(request):
    return render(request, "attendance/scan_page.html")



@login_required
@staff_member_required
def admin_dashboard(request):
    students_data = []
    students = UserProfile.objects.all()
    
    # Collecting student data for attendance & payment status
    for student in students:
        today = datetime.date.today()
        attendance_today = Attendance.objects.filter(user_profile=student, date=today).exists()
        present_status = "Present" if attendance_today else "Absent"
        
        students_data.append({
            "id": student.id,
            "name": f"{student.first_name} {student.last_name}",
            "email": student.email,
            "phone": student.phone,
            "scholar": "Yes" if student.is_scholar else "No",
            "paid": "Yes" if student.paid else "No",
            "present": present_status,
        })
    
    # Pass student data to the template
    context = {
        "students_json": json.dumps(students_data),
    }

    # If the request is POST (profile update form submission)
    if request.method == 'POST':
        form = UpdateProfileForm(request.POST, instance=request.user.userprofile)
        if form.is_valid():
            form.save()
            messages.success(request, "Your profile has been updated successfully.")
            return redirect('admin_dashboard')  # Redirect to the dashboard or wherever you need
        else:
            messages.error(request, "There was an error updating your profile. Please try again.")

    # Fetch current user profile to populate the form for editing
    form = UpdateProfileForm(instance=request.user.userprofile)
    issue_form = IssueForm()
    context.update({
        "form": form,
        "issue_form": issue_form,
    })

    return render(request, "attendance/index_admin.html", context)



def search_students(request):
    query = request.GET.get("query", "")
    if query:
        students = UserProfile.objects.filter(
            Q(first_name__icontains=query) | 
            Q(last_name__icontains=query) | 
            Q(phone__icontains=query)
        )
        results = [{"name": f"{student.first_name} {student.last_name}", "phone": student.phone} for student in students]
        return JsonResponse({"results": results})
    return JsonResponse({"results": []})


@login_required
@csrf_exempt
def attendance_summary(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            print(data)
            date_str = data.get('content')
            print(f"Received date string: {date_str}")
            try:
                date = timezone.datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                logger.error("Invalid date format")
                return JsonResponse({'error': 'Invalid date format'}, status=400)
            
            attendance_records = Attendance.objects.filter(date=date)
            
            totalStudents = UserProfile.objects.count()
            totalAttended = attendance_records.count()
            PaidAttended = attendance_records.filter(user_profile__paid=True).count()
            PaidAbsent = totalStudents - PaidAttended
            UnpaidAttended = attendance_records.filter(user_profile__paid=False).count()
        
            summary = {
                'totalStudents': totalStudents,
                'totalAttended': totalAttended,
                'PaidAttended': PaidAttended,
                'PaidAbsent': PaidAbsent,
                'UnpaidAttended': UnpaidAttended,
            }
        
            return JsonResponse(summary)
        except json.JSONDecodeError:
            logger.error("JSON decode error")
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return JsonResponse({'error': 'An unexpected error occurred'}, status=500)
        


@login_required
def toggle_payment_status(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            student_id = data.get("id")
            new_status = data.get("paid") == "Yes"
            
            # Update the payment status in the database
            student = UserProfile.objects.get(id=student_id)
            student.paid = new_status
            student.save()
            
            return JsonResponse({"success": True, "message": "Payment status updated."})
        except UserProfile.DoesNotExist:
            return JsonResponse({"success": False, "message": "Student not found."})
        except Exception as e:
            return JsonResponse({"success": False, "message": str(e)})
    return JsonResponse({"success": False, "message": "Invalid request method."})

@login_required
def get_attendance_data(request):
    date = request.GET.get('date')
    if date:
        students = UserProfile.objects.all()
        attendance_records = Attendance.objects.filter(date=date)

        students_with_attendance = []
        for student in students:
            attendance = attendance_records.filter(user_profile=student).first()
            students_with_attendance.append({
                "id": student.id,
                "name": f"{student.first_name} {student.last_name}",
                "email": student.email,
                "phone": student.phone,
                "scholar": "Yes" if student.is_scholar else "No",
                "paid": "Yes" if student.paid else "No",
                "present": "Present" if attendance else "Absent",
            })

        return JsonResponse({'success': True, 'students': students_with_attendance})
    
    return JsonResponse({'success': False, 'message': 'Invalid date or no records found.'})


 
def signup(request):
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            user_profile, password = form.save()
            # Send email with the generated password
            send_mail(
                'Your Account Password',
                f'Your account has been created. Your password is: {password}',
                settings.EMAIL_HOST_USER,  # Replace with your sender email
                [user_profile.email],
                fail_silently=False,
            )
            messages.success(request, 'Signup successful! Please check your email for your password.')
            return redirect('login')
    else:
        form = SignupForm()

    return render(request, 'attendance/signup.html', {'form': form})


def generate_otp():
    return random.randint(100000, 999999)



def send_otp(email, otp):
    subject = 'Your OTP for Login - QR Plate'
    
    # Get base64 encoded logo
    logo_path = os.path.join(settings.STATIC_ROOT, 'assets/images/logo.jpg')
    try:
        with open(logo_path, 'rb') as img_file:
            logo_data = base64.b64encode(img_file.read()).decode()
            logo_url = f"data:image/jpeg;base64,{logo_data}"
    except Exception as e:
        print(f"Error reading logo: {e}")
        logo_url = ""  # Fallback if image can't be read
    
    html_content = render_to_string('emails/otp_email.html', {
        'otp': otp,
        'logo_url': logo_url
    })
    
    text_content = strip_tags(html_content)
    
    email_message = EmailMessage(
        subject,
        html_content,
        settings.EMAIL_HOST_USER,
        [email]
    )
    
    email_message.content_subtype = 'html'
    email_message.send()

# View for Login 

def login_with_otp(request):
    if request.method == 'POST':
        email = request.POST['email']
        otp = request.POST['otp']

        try:
            user_profile = UserProfile.objects.get(email=email)
            stored_otp = request.session.get('otp')
            otp_timestamp = request.session.get('otp_timestamp')
            
            # Check if OTP has expired
            if otp_timestamp:
                otp_time = timezone.datetime.strptime(otp_timestamp, "%Y-%m-%d %H:%M:%S")
                if timezone.now() - otp_time > OTP_EXPIRATION_TIME:
                    messages.error(request, 'OTP has expired.')
                    return redirect('login')

            if stored_otp == otp:
                login(request, user_profile.user)
                return redirect('web_home')
            else:
                messages.error(request, 'Invalid OTP')
        except UserProfile.DoesNotExist:
            messages.error(request, 'No user with this email')
    
    return render(request, 'attendance/login_with_otp.html')


@login_required
def web_home(request):
    if request.user.is_authenticated:
        try:
            user_profile = UserProfile.objects.get(user=request.user)

            # Handle image upload
            if request.method == 'POST':
                form = ProfileImageForm(request.POST, request.FILES, instance=user_profile)
                if form.is_valid():
                    form.save()
                    messages.success(request, "Profile image updated successfully!")
                    return redirect('web_home')  # Reload page to show the updated image
                else:
                    messages.error(request, "Failed to upload image. Please try again.")

            # Generate the QR code URL using settings.BASE_URL
            qr_code_url = f"{settings.BASE_URL}/scan/{user_profile.qr_code_id}"

            # Generate the QR code
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=8,
                border=4,
            )
            qr.add_data(qr_code_url)
            qr.make(fit=True)

            # Create an image from the QR code
            img = qr.make_image(fill_color='black', back_color='white')

            # Save the image to a BytesIO object
            img_io = BytesIO()
            img.save(img_io, format='PNG')
            img_io.seek(0)

            # Encode the QR code image to base64 to display in the template
            qr_code_base64 = base64.b64encode(img_io.getvalue()).decode('utf-8')

            form = ProfileImageForm(instance=user_profile)  # Pre-fill form with current data

            return render(request, 'attendance/home.html', {
                'qr_code': qr_code_base64,
                'user_profile': user_profile,
                'qr_code_url': qr_code_url,
                'form': form,
            })
        except UserProfile.DoesNotExist:
            messages.error(request, 'User profile not found.')
            return redirect('login')
    else:
        return redirect('login')


# View to handle email input and send OTP
@csrf_exempt
def login_view(request):
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']

            try:
                user_profile = UserProfile.objects.get(email=email)

                # Generate OTP
                otp = generate_otp()
                request.session['otp'] = str(otp)
                request.session['email'] = email
                request.session['otp_timestamp'] = timezone.now().strftime("%Y-%m-%d %H:%M:%S")

                # Send OTP to user's email
                send_otp(email, otp)
                messages.success(request, 'OTP sent to your email.')

                return redirect('verify_otp')  # Redirect to OTP verification page
            except UserProfile.DoesNotExist:
                messages.error(request, "No account found with that email.")
        else:
            messages.error(request, "Please enter a valid email address.")
    else:
        form = LoginForm()

    return render(request, 'attendance/login.html', {'form': form})

# Decorate with @login_required to ensure the user is authenticated
@csrf_exempt
def verify_otp(request):
    if request.method == 'POST':
        otp_input = request.POST.get('otp')
        stored_otp = request.session.get('otp')
        email = request.session.get('email')

        if otp_input == stored_otp:
            try:
                user_profile = UserProfile.objects.get(email=email)
                user = user_profile.user

                # Authenticate and log the user in
                login(request, user)

                # Redirect to the appropriate dashboard
                if user.is_staff:
                    return redirect('admin_dashboard')  # Admin dashboard
                else:
                    return redirect('web_home')  # Student dashboard

            except UserProfile.DoesNotExist:
                messages.error(request, "No account found with that email.")
                return redirect('login')  # Redirect back to login if user profile not found
        else:
            messages.error(request, "Invalid OTP. Please try again.")
    
    return render(request, 'attendance/verify_otp.html')



def logout_view(request):
    logout(request)  # Log out the user
    return redirect('login')  # Redirect to login page after logout

# Generate OTP
def generate_otp():
    return str(random.randint(100000, 999999))

    logout(request)
    return Response({'message': 'Logout successful.'}, status=status.HTTP_200_OK)

class LoginAPI(APIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            try:
                user_profile = UserProfile.objects.get(email=email)
                login(request, user_profile.user)
                return Response({'message': 'Login successful.'}, status=status.HTTP_200_OK)
            except UserProfile.DoesNotExist:
                return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


