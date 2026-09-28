from datetime import date, time
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.test import TestCase
from django.urls import reverse

from .models import (
    AcademicYear,
    Assessment,
    AssessmentResult,
    Attendance,
    Branch,
    Enrollment,
    FeeCharge,
    GradeLevel,
    Payment,
    Room,
    Schedule,
    School,
    SchoolMembership,
    Section,
    Shift,
    Student,
    Subject,
    Teacher,
    TeachingAssignment,
    Term,
)


class FoundationTestCase(TestCase):
    def setUp(self):
        self.school = School.objects.create(name="Ariana School", code="ARI")
        self.branch = Branch.objects.create(school=self.school, name="Main", code="MAIN")
        self.year = AcademicYear.objects.create(
            school=self.school, name="2026", start_date=date(2026, 3, 1), end_date=date(2026, 12, 20)
        )
        self.term = Term.objects.create(
            academic_year=self.year, name="Term 1", order=1,
            start_date=date(2026, 3, 1), end_date=date(2026, 7, 1)
        )
        self.grade = GradeLevel.objects.create(school=self.school, name="Grade 10", code="10", order=10)
        self.shift = Shift.objects.create(branch=self.branch, name="Morning", start_time=time(7), end_time=time(12))
        self.room = Room.objects.create(branch=self.branch, name="101", capacity=30)
        self.teacher = Teacher.objects.create(
            school=self.school, primary_branch=self.branch, employee_number="T-001",
            first_name="Ahmad", last_name="Rahimi"
        )
        self.section = Section.objects.create(
            school=self.school, branch=self.branch, academic_year=self.year,
            grade_level=self.grade, name="A", shift=self.shift, room=self.room
        )
        self.student = Student.objects.create(
            school=self.school, student_number="ST-001", first_name="Maryam",
            last_name="Noori", admission_date=date(2026, 3, 1)
        )
        self.enrollment = Enrollment.objects.create(
            student=self.student, section=self.section, start_date=date(2026, 3, 1)
        )
        self.subject = Subject.objects.create(school=self.school, code="MATH", name="Mathematics")
        self.assignment = TeachingAssignment.objects.create(
            section=self.section, subject=self.subject, teacher=self.teacher, term=self.term
        )

    def test_cross_school_section_is_rejected(self):
        other = School.objects.create(name="Other School", code="OTHER")
        other_grade = GradeLevel.objects.create(school=other, name="Grade 10", code="10", order=10)
        with self.assertRaises(ValidationError):
            Section(
                school=self.school, branch=self.branch, academic_year=self.year,
                grade_level=other_grade, name="B"
            ).full_clean()

    def test_teacher_schedule_overlap_is_rejected(self):
        Schedule.objects.create(
            assignment=self.assignment, room=self.room, day_of_week=Schedule.Day.SATURDAY,
            start_time=time(8), end_time=time(9)
        )
        other_subject = Subject.objects.create(school=self.school, code="SCI", name="Science")
        second = TeachingAssignment.objects.create(
            section=self.section, subject=other_subject, teacher=self.teacher, term=self.term
        )
        with self.assertRaises(ValidationError):
            Schedule(
                assignment=second, room=self.room, day_of_week=Schedule.Day.SATURDAY,
                start_time=time(8, 30), end_time=time(9, 30)
            ).full_clean()

    def test_attendance_must_fall_inside_enrollment(self):
        with self.assertRaises(ValidationError):
            Attendance(
                enrollment=self.enrollment, date=date(2026, 2, 28), status=Attendance.Status.PRESENT
            ).full_clean()

    def test_assessment_result_must_match_section(self):
        assessment = Assessment.objects.create(
            assignment=self.assignment, name="Quiz 1", assessment_type=Assessment.Type.QUIZ,
            date=date(2026, 4, 1), max_score=Decimal("20"), pass_score=Decimal("10")
        )
        other_grade = GradeLevel.objects.create(school=self.school, name="Grade 9", code="9", order=9)
        other_section = Section.objects.create(
            school=self.school, branch=self.branch, academic_year=self.year,
            grade_level=other_grade, name="A"
        )
        other_student = Student.objects.create(
            school=self.school, student_number="ST-002", first_name="Ali",
            last_name="Hosseini", admission_date=date(2026, 3, 1)
        )
        other_enrollment = Enrollment.objects.create(
            student=other_student, section=other_section, start_date=date(2026, 3, 1)
        )
        with self.assertRaises(ValidationError):
            AssessmentResult(
                assessment=assessment, enrollment=other_enrollment,
                score=Decimal("15"), status=AssessmentResult.Status.GRADED
            ).full_clean()

    def test_payment_cannot_overpay_charge(self):
        charge = FeeCharge.objects.create(
            enrollment=self.enrollment, category="Tuition",
            amount=Decimal("1000"), due_date=date(2026, 4, 1)
        )
        Payment.objects.create(
            fee_charge=charge, amount=Decimal("700"),
            payment_method=Payment.Method.CASH, receipt_number="R-1"
        )
        with self.assertRaises(ValidationError):
            Payment(
                fee_charge=charge, amount=Decimal("400"),
                payment_method=Payment.Method.CASH, receipt_number="R-2"
            ).full_clean()


class DashboardTestCase(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username="admin", password="strong-test-password")
        self.school = School.objects.create(name="Test School", code="TEST")
        SchoolMembership.objects.create(user=self.user, school=self.school)

    def test_dashboard_requires_authentication(self):
        response = self.client.get(reverse("dashboard"))
        self.assertEqual(response.status_code, 302)
        self.assertIn(reverse("login"), response.url)

    def test_dashboard_uses_membership_school(self):
        self.client.login(username="admin", password="strong-test-password")
        response = self.client.get(reverse("dashboard"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Test School")

    def test_login_form_does_not_expose_password(self):
        response = self.client.get(reverse("login"))
        self.assertContains(response, 'type="password"')
        self.assertContains(response, "csrfmiddlewaretoken")
