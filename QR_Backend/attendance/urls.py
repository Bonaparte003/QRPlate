from django.urls import path
from . import views
from rest_framework_simplejwt.views import TokenRefreshView  #  TokenRefreshView
from django.contrib.auth.views import LogoutView

# Web Views
web_patterns = [
    #  path('logout/', LogoutView.as_view(next_page='/'), name='logout'),
    path('signup/', views.signup, name='signup'),
    path('', views.login_view, name='login'),
    path('home/', views.web_home, name='web_home'),
    path('logout/', views.logout_view, name='logout'),
    path('scan/<uuid:qr_code_id>/', views.scan_qr_code, name='scan_qr_code'),
    path('admin_dashboard/', views.admin_dashboard, name='admin_dashboard'),
    path('send-otp/', views.send_otp, name='send_otp'),
    path('verify-otp/', views.verify_otp, name='verify_otp'),
    path('admin_dashboard/api/toggle-payment-status/', views.toggle_payment_status, name='toggle_payment_status'),
    path('admin_dashboard/api/get-attendance-data/', views.get_attendance_data, name='get_attendance_data'),
    path('admin_dashboard/api/get-attendance-summary/', views.attendance_summary, name='get_attendance_summary'),
    path('admin_dashboard/search-students/', views.search_students, name='search_students'),
    path('scan_page/', views.scan_page, name='scan_page'),
    path('report_issue/', views.report_issue, name='report_issue'),
    path('download-apps/', views.download_app, name='download_apps'),
]

# API Endpoints
api_patterns = [
    path('api/signup/', views.signup_api, name='signup_api'),
    path('api/login/', views.login_api, name='login_api'),
    path('api/send-otp/', views.send_otp_api, name='send_otp_api'),
    path('api/verify-otp/', views.verify_otp_api, name='verify_otp_api'),
    path('api/logout/', views.logout_api, name='logout_api'),
    path('api/mark-attendance/', views.mark_attendance_api, name='mark_attendance_api'),
    path('api/home/', views.home_api, name='home_api'),
    path('api/scan/<uuid:qr_code_id>/', views.scan_qr_code_api, name='scan_qr_code_api'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/admin-dashboard/', views.admin_dashboard_api, name='admin_dashboard_api'),
    path('api/student-dashboard/', views.student_dashboard_api, name='student_dashboard_api'),
    path('api/home-api/', views.home, name='home'),
    path('api/admin-login/', views.admin_login, name='admin_login'),
    path('api/update-profile-picture/', views.update_profile_picture, name='update_profile_picture'),

]

urlpatterns = web_patterns + api_patterns