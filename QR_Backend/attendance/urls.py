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
    path('admin_dashboard/', views.admin_dashboard, name='admin_dashboard'),
    path('send-otp/', views.send_otp, name='send_otp'),
    path('verify-otp/', views.verify_otp, name='verify_otp'),
    path('admin_landing/', views.admin_landing, name='admin_landing'),
    path('admin_dashboard/api/toggle-payment-status/', views.toggle_payment_status, name='toggle_payment_status'),
    path('admin_dashboard/api/get-attendance-data/', views.get_attendance_data, name='get_attendance_data'),
    path('admin_dashboard/api/get-attendance-summary/', views.attendance_summary, name='get_attendance_summary'),
    path('admin_dashboard/search-students/', views.search_students, name='search_students'),
    # path('scan_page/', views.scan_page, name='scan_page'),
]

# API Endpoints
# api_patterns = [
#     path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

# ]

urlpatterns = web_patterns + api_patterns
