from django.contrib import admin

from . import models

MODELS = [
    models.School,
    models.Branch,
    models.AcademicYear,
    models.Term,
    models.GradeLevel,
    models.Shift,
    models.Room,
    models.SchoolMembership,
    models.MembershipRole,
    models.Student,
    models.Guardian,
    models.StudentGuardian,
    models.Teacher,
    models.Staff,
    models.Section,
    models.Enrollment,
    models.Subject,
    models.TeachingAssignment,
    models.Schedule,
    models.Attendance,
    models.Assessment,
    models.AssessmentResult,
    models.FeeCharge,
    models.Payment,
    models.Expense,
    models.PayrollEntry,
    models.Asset,
    models.Announcement,
    models.Notification,
    models.NotificationRecipient,
    models.ActivityLog,
]

for model in MODELS:
    admin.site.register(model)

admin.site.site_header = "EduTrack Administration"
admin.site.site_title = "EduTrack Admin"
admin.site.index_title = "School Management"
