from django.contrib import admin
from .models import UserProfile, Attendance, Issue
# Register your models here.


class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('email', 'qr_code_id')
    search_fields = ('user__username', 'user__email')

admin.site.register(UserProfile, UserProfileAdmin)

class IssueAdmin(admin.ModelAdmin):
    list_display = ('title', 'priority', 'reported_by', 'created_at')
    list_filter = ('priority', 'reported_by')
    search_fields = ('title', 'description')

admin.site.register(Issue, IssueAdmin)

class AttendanceAdmin(admin.ModelAdmin):
    list_display = ('user_profile', 'date', 'time')
    list_filter = ('date',)
    search_fields = ('user__username',)

admin.site.register(Attendance, AttendanceAdmin)
