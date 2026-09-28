from django.contrib import messages
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import AuthenticationForm
from django.db.models import Count
from django.shortcuts import redirect, render
from django.utils import timezone

from .models import ActivityLog, Attendance, School, SchoolMembership, Section, Student, Teacher


def _current_school_for_user(request):
    memberships = (
        SchoolMembership.objects.filter(user=request.user, is_active=True, school__is_active=True)
        .select_related("school")
        .order_by("school__name")
    )

    requested_school = request.GET.get("school")
    if requested_school:
        membership = memberships.filter(school_id=requested_school).first()
        if membership:
            request.session["school_id"] = membership.school_id
            return membership.school

    session_school = request.session.get("school_id")
    if session_school:
        membership = memberships.filter(school_id=session_school).first()
        if membership:
            return membership.school

    membership = memberships.first()
    if membership:
        request.session["school_id"] = membership.school_id
        return membership.school

    if request.user.is_superuser:
        school = School.objects.filter(is_active=True).order_by("name").first()
        if school:
            request.session["school_id"] = school.id
            return school

    return None


def login_view(request):
    if request.user.is_authenticated:
        return redirect("dashboard")

    form = AuthenticationForm(request=request, data=request.POST or None)
    if request.method == "POST" and form.is_valid():
        login(request, form.get_user())
        messages.success(request, "Welcome back.")
        return redirect(request.GET.get("next") or "dashboard")

    return render(request, "backend/login.html", {"form": form})


@login_required
def logout_view(request):
    if request.method == "POST":
        logout(request)
        return redirect("login")
    return redirect("dashboard")


@login_required
def dashboard(request):
    school = _current_school_for_user(request)
    memberships = (
        SchoolMembership.objects.filter(user=request.user, is_active=True, school__is_active=True)
        .select_related("school")
        .order_by("school__name")
    )

    if school is None:
        return render(request, "backend/no_school.html", {"memberships": memberships}, status=403)

    today = timezone.localdate()
    attendance = Attendance.objects.filter(enrollment__section__school=school, date=today)
    attendance_total = attendance.count()
    attendance_present = attendance.filter(
        status__in=[Attendance.Status.PRESENT, Attendance.Status.LATE]
    ).count()
    attendance_rate = round((attendance_present / attendance_total) * 100) if attendance_total else 0

    context = {
        "school": school,
        "memberships": memberships,
        "student_count": Student.objects.filter(school=school, status=Student.Status.ACTIVE).count(),
        "teacher_count": Teacher.objects.filter(school=school, status=Teacher.Status.ACTIVE).count(),
        "section_count": Section.objects.filter(school=school, is_active=True).count(),
        "attendance_rate": attendance_rate,
        "attendance_total": attendance_total,
        "recent_attendance": attendance.select_related(
            "enrollment__student", "enrollment__section__grade_level"
        ).order_by("-created_at")[:8],
        "recent_activity": ActivityLog.objects.filter(school=school).select_related("user")[:6],
        "notification_count": request.user.notification_recipients.filter(is_read=False).count(),
        "section_summary": (
            Section.objects.filter(school=school, is_active=True)
            .values("grade_level__name")
            .annotate(total=Count("id"))
            .order_by("grade_level__order")[:8]
        ),
    }
    return render(request, "backend/dashboard.html", context)
