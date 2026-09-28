from decimal import Decimal

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone


class ValidatedModel(models.Model):
    """Run model validation for ordinary application writes."""

    class Meta:
        abstract = True

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class TimeStampedModel(ValidatedModel):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class School(TimeStampedModel):
    name = models.CharField(max_length=150)
    code = models.CharField(max_length=30, unique=True)
    phone = models.CharField(max_length=30, blank=True)
    email = models.EmailField(blank=True)
    address = models.CharField(max_length=300, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Branch(TimeStampedModel):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="branches")
    name = models.CharField(max_length=120)
    code = models.CharField(max_length=30)
    address = models.CharField(max_length=300, blank=True)
    phone = models.CharField(max_length=30, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["school", "name"]
        unique_together = (("school", "code"), ("school", "name"))

    def __str__(self):
        return f"{self.school} — {self.name}"


class AcademicYear(TimeStampedModel):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="academic_years")
    name = models.CharField(max_length=40)
    start_date = models.DateField()
    end_date = models.DateField()
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["-start_date"]
        unique_together = (("school", "name"),)

    def clean(self):
        if self.end_date <= self.start_date:
            raise ValidationError({"end_date": "End date must be after start date."})

    def __str__(self):
        return f"{self.school}: {self.name}"


class Term(TimeStampedModel):
    academic_year = models.ForeignKey(AcademicYear, on_delete=models.CASCADE, related_name="terms")
    name = models.CharField(max_length=50)
    order = models.PositiveSmallIntegerField(validators=[MinValueValidator(1)])
    start_date = models.DateField()
    end_date = models.DateField()
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["academic_year", "order"]
        unique_together = (("academic_year", "name"), ("academic_year", "order"))

    def clean(self):
        if self.end_date <= self.start_date:
            raise ValidationError({"end_date": "End date must be after start date."})
        if self.academic_year_id:
            year = self.academic_year
            if self.start_date < year.start_date or self.end_date > year.end_date:
                raise ValidationError("Term dates must fall inside the academic year.")

    def __str__(self):
        return f"{self.academic_year.name} — {self.name}"


class GradeLevel(TimeStampedModel):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="grade_levels")
    name = models.CharField(max_length=60)
    code = models.CharField(max_length=20)
    order = models.PositiveSmallIntegerField(validators=[MinValueValidator(1)])
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["school", "order"]
        unique_together = (("school", "code"), ("school", "order"))

    def __str__(self):
        return f"{self.school}: {self.name}"


class Shift(TimeStampedModel):
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name="shifts")
    name = models.CharField(max_length=50)
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["branch", "start_time"]
        unique_together = (("branch", "name"),)

    def clean(self):
        if self.end_time <= self.start_time:
            raise ValidationError({"end_time": "End time must be after start time."})

    def __str__(self):
        return f"{self.branch}: {self.name}"


class Room(TimeStampedModel):
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name="rooms")
    name = models.CharField(max_length=60)
    capacity = models.PositiveIntegerField(null=True, blank=True, validators=[MinValueValidator(1)])
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["branch", "name"]
        unique_together = (("branch", "name"),)

    def __str__(self):
        return f"{self.branch}: {self.name}"


class SchoolMembership(TimeStampedModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="school_memberships")
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="memberships")
    primary_branch = models.ForeignKey(
        Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name="primary_memberships"
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = (("user", "school"),)

    def clean(self):
        if self.primary_branch_id and self.primary_branch.school_id != self.school_id:
            raise ValidationError({"primary_branch": "Primary branch must belong to this school."})

    def __str__(self):
        return f"{self.user} @ {self.school}"


class MembershipRole(TimeStampedModel):
    class Role(models.TextChoices):
        OWNER = "owner", "Owner"
        ADMIN = "admin", "Administrator"
        MANAGER = "manager", "Manager"
        TEACHER = "teacher", "Teacher"
        STAFF = "staff", "Staff"
        GUARDIAN = "guardian", "Guardian"
        STUDENT = "student", "Student"

    membership = models.ForeignKey(SchoolMembership, on_delete=models.CASCADE, related_name="roles")
    role = models.CharField(max_length=20, choices=Role.choices)
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, null=True, blank=True, related_name="role_assignments")

    class Meta:
        unique_together = (("membership", "role", "branch"),)

    def clean(self):
        if self.branch_id and self.branch.school_id != self.membership.school_id:
            raise ValidationError({"branch": "Role branch must belong to the membership school."})

    def __str__(self):
        return f"{self.membership}: {self.get_role_display()}"


class Student(TimeStampedModel):
    class Gender(models.TextChoices):
        MALE = "male", "Male"
        FEMALE = "female", "Female"
        OTHER = "other", "Other"
        UNSPECIFIED = "unspecified", "Unspecified"

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        INACTIVE = "inactive", "Inactive"
        GRADUATED = "graduated", "Graduated"
        WITHDRAWN = "withdrawn", "Withdrawn"

    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="students")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="student_profiles"
    )
    student_number = models.CharField(max_length=50)
    first_name = models.CharField(max_length=60)
    last_name = models.CharField(max_length=60)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=20, choices=Gender.choices, default=Gender.UNSPECIFIED)
    admission_date = models.DateField()
    phone = models.CharField(max_length=30, blank=True)
    address = models.CharField(max_length=300, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)

    class Meta:
        ordering = ["school", "student_number"]
        unique_together = (("school", "student_number"),)

    def __str__(self):
        return f"{self.student_number} — {self.first_name} {self.last_name}"


class Guardian(TimeStampedModel):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="guardians")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="guardian_profiles"
    )
    first_name = models.CharField(max_length=60)
    last_name = models.CharField(max_length=60)
    phone = models.CharField(max_length=30)
    email = models.EmailField(blank=True)
    address = models.CharField(max_length=300, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["school", "last_name", "first_name"]

    def __str__(self):
        return f"{self.first_name} {self.last_name}"


class StudentGuardian(TimeStampedModel):
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="guardian_links")
    guardian = models.ForeignKey(Guardian, on_delete=models.CASCADE, related_name="student_links")
    relationship = models.CharField(max_length=40)
    is_primary = models.BooleanField(default=False)
    is_emergency_contact = models.BooleanField(default=False)

    class Meta:
        unique_together = (("student", "guardian"),)

    def clean(self):
        if self.student_id and self.guardian_id and self.student.school_id != self.guardian.school_id:
            raise ValidationError("Student and guardian must belong to the same school.")

    def __str__(self):
        return f"{self.guardian} → {self.student}"


class Teacher(TimeStampedModel):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        ON_LEAVE = "on_leave", "On leave"
        INACTIVE = "inactive", "Inactive"
        TERMINATED = "terminated", "Terminated"

    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="teachers")
    primary_branch = models.ForeignKey(
        Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name="teachers"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="teacher_profiles"
    )
    employee_number = models.CharField(max_length=50)
    first_name = models.CharField(max_length=60)
    last_name = models.CharField(max_length=60)
    phone = models.CharField(max_length=30, blank=True)
    email = models.EmailField(blank=True)
    hire_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)

    class Meta:
        ordering = ["school", "employee_number"]
        unique_together = (("school", "employee_number"),)

    def clean(self):
        if self.primary_branch_id and self.primary_branch.school_id != self.school_id:
            raise ValidationError({"primary_branch": "Branch must belong to this school."})

    def __str__(self):
        return f"{self.employee_number} — {self.first_name} {self.last_name}"


class Staff(TimeStampedModel):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        ON_LEAVE = "on_leave", "On leave"
        INACTIVE = "inactive", "Inactive"
        TERMINATED = "terminated", "Terminated"

    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="staff")
    primary_branch = models.ForeignKey(
        Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name="staff"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="staff_profiles"
    )
    employee_number = models.CharField(max_length=50)
    first_name = models.CharField(max_length=60)
    last_name = models.CharField(max_length=60)
    phone = models.CharField(max_length=30, blank=True)
    email = models.EmailField(blank=True)
    position = models.CharField(max_length=100)
    national_id = models.CharField(max_length=50, blank=True)
    hire_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)

    class Meta:
        ordering = ["school", "employee_number"]
        unique_together = (("school", "employee_number"), ("school", "national_id"))

    def clean(self):
        if self.primary_branch_id and self.primary_branch.school_id != self.school_id:
            raise ValidationError({"primary_branch": "Branch must belong to this school."})

    def __str__(self):
        return f"{self.employee_number} — {self.first_name} {self.last_name}"


class Section(TimeStampedModel):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="sections")
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name="sections")
    academic_year = models.ForeignKey(AcademicYear, on_delete=models.CASCADE, related_name="sections")
    grade_level = models.ForeignKey(GradeLevel, on_delete=models.PROTECT, related_name="sections")
    name = models.CharField(max_length=40)
    shift = models.ForeignKey(Shift, on_delete=models.SET_NULL, null=True, blank=True, related_name="sections")
    room = models.ForeignKey(Room, on_delete=models.SET_NULL, null=True, blank=True, related_name="sections")
    homeroom_teacher = models.ForeignKey(
        Teacher, on_delete=models.SET_NULL, null=True, blank=True, related_name="homeroom_sections"
    )
    max_capacity = models.PositiveIntegerField(null=True, blank=True, validators=[MinValueValidator(1)])
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["academic_year", "grade_level", "name"]
        unique_together = (("branch", "academic_year", "grade_level", "name"),)

    def clean(self):
        errors = {}
        if self.branch_id and self.branch.school_id != self.school_id:
            errors["branch"] = "Branch must belong to this school."
        if self.academic_year_id and self.academic_year.school_id != self.school_id:
            errors["academic_year"] = "Academic year must belong to this school."
        if self.grade_level_id and self.grade_level.school_id != self.school_id:
            errors["grade_level"] = "Grade level must belong to this school."
        if self.shift_id and self.shift.branch_id != self.branch_id:
            errors["shift"] = "Shift must belong to this branch."
        if self.room_id and self.room.branch_id != self.branch_id:
            errors["room"] = "Room must belong to this branch."
        if self.homeroom_teacher_id and self.homeroom_teacher.school_id != self.school_id:
            errors["homeroom_teacher"] = "Teacher must belong to this school."
        if errors:
            raise ValidationError(errors)

    def __str__(self):
        return f"{self.grade_level.name} {self.name} ({self.academic_year.name})"


class Enrollment(TimeStampedModel):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        TRANSFERRED = "transferred", "Transferred"
        WITHDRAWN = "withdrawn", "Withdrawn"
        COMPLETED = "completed", "Completed"

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="enrollments")
    section = models.ForeignKey(Section, on_delete=models.PROTECT, related_name="enrollments")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    roll_number = models.CharField(max_length=30, blank=True)

    class Meta:
        ordering = ["-section__academic_year__start_date", "student"]
        unique_together = (("student", "section", "start_date"),)

    def clean(self):
        if self.student_id and self.section_id and self.student.school_id != self.section.school_id:
            raise ValidationError("Student and section must belong to the same school.")
        if self.end_date and self.end_date < self.start_date:
            raise ValidationError({"end_date": "End date cannot be before start date."})
        if self.section_id:
            year = self.section.academic_year
            if self.start_date < year.start_date or self.start_date > year.end_date:
                raise ValidationError({"start_date": "Enrollment start must fall inside the academic year."})
            if self.end_date and self.end_date > year.end_date:
                raise ValidationError({"end_date": "Enrollment end must fall inside the academic year."})

    def __str__(self):
        return f"{self.student} → {self.section}"


class Subject(TimeStampedModel):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="subjects")
    code = models.CharField(max_length=30)
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["school", "name"]
        unique_together = (("school", "code"), ("school", "name"))

    def __str__(self):
        return self.name


class TeachingAssignment(TimeStampedModel):
    section = models.ForeignKey(Section, on_delete=models.CASCADE, related_name="teaching_assignments")
    subject = models.ForeignKey(Subject, on_delete=models.PROTECT, related_name="teaching_assignments")
    teacher = models.ForeignKey(Teacher, on_delete=models.PROTECT, related_name="teaching_assignments")
    term = models.ForeignKey(Term, on_delete=models.PROTECT, related_name="teaching_assignments")
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = (("section", "subject", "teacher", "term"),)

    def clean(self):
        school_id = self.section.school_id if self.section_id else None
        errors = {}
        if self.subject_id and self.subject.school_id != school_id:
            errors["subject"] = "Subject must belong to the section school."
        if self.teacher_id and self.teacher.school_id != school_id:
            errors["teacher"] = "Teacher must belong to the section school."
        if self.term_id and self.term.academic_year_id != self.section.academic_year_id:
            errors["term"] = "Term must belong to the section academic year."
        if errors:
            raise ValidationError(errors)

    def __str__(self):
        return f"{self.section} — {self.subject} — {self.teacher}"


class Schedule(TimeStampedModel):
    class Day(models.IntegerChoices):
        SATURDAY = 1, "Saturday"
        SUNDAY = 2, "Sunday"
        MONDAY = 3, "Monday"
        TUESDAY = 4, "Tuesday"
        WEDNESDAY = 5, "Wednesday"
        THURSDAY = 6, "Thursday"
        FRIDAY = 7, "Friday"

    assignment = models.ForeignKey(TeachingAssignment, on_delete=models.CASCADE, related_name="schedule_entries")
    room = models.ForeignKey(Room, on_delete=models.SET_NULL, null=True, blank=True, related_name="schedule_entries")
    day_of_week = models.PositiveSmallIntegerField(choices=Day.choices)
    start_time = models.TimeField()
    end_time = models.TimeField()

    class Meta:
        ordering = ["day_of_week", "start_time"]
        unique_together = (("assignment", "day_of_week", "start_time", "end_time"),)

    def clean(self):
        if self.end_time <= self.start_time:
            raise ValidationError({"end_time": "End time must be after start time."})
        if not self.assignment_id:
            return
        section = self.assignment.section
        if self.room_id and self.room.branch_id != section.branch_id:
            raise ValidationError({"room": "Room must belong to the section branch."})

        overlap = Schedule.objects.filter(
            day_of_week=self.day_of_week,
            start_time__lt=self.end_time,
            end_time__gt=self.start_time,
            assignment__term=self.assignment.term,
        ).exclude(pk=self.pk)

        if overlap.filter(assignment__teacher=self.assignment.teacher).exists():
            raise ValidationError("Teacher has an overlapping schedule.")
        if overlap.filter(assignment__section=section).exists():
            raise ValidationError("Section has an overlapping schedule.")
        if self.room_id and overlap.filter(room_id=self.room_id).exists():
            raise ValidationError("Room has an overlapping schedule.")

    def __str__(self):
        return f"{self.get_day_of_week_display()} {self.start_time}-{self.end_time}: {self.assignment}"


class Attendance(TimeStampedModel):
    class Status(models.TextChoices):
        PRESENT = "present", "Present"
        ABSENT = "absent", "Absent"
        LATE = "late", "Late"
        EXCUSED = "excused", "Excused"

    class Source(models.TextChoices):
        MANUAL = "manual", "Manual"
        FINGERPRINT = "fingerprint", "Fingerprint"
        DEVICE = "device", "Other device"
        IMPORT = "import", "Import"

    enrollment = models.ForeignKey(Enrollment, on_delete=models.CASCADE, related_name="attendance_records")
    date = models.DateField()
    status = models.CharField(max_length=20, choices=Status.choices)
    check_in_time = models.TimeField(null=True, blank=True)
    check_out_time = models.TimeField(null=True, blank=True)
    source = models.CharField(max_length=20, choices=Source.choices, default=Source.MANUAL)
    remarks = models.CharField(max_length=300, blank=True)
    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="attendance_recordings"
    )

    class Meta:
        ordering = ["-date", "enrollment"]
        unique_together = (("enrollment", "date"),)

    def clean(self):
        if self.check_in_time and self.check_out_time and self.check_out_time <= self.check_in_time:
            raise ValidationError({"check_out_time": "Check-out time must be after check-in time."})
        if self.enrollment_id:
            enrollment = self.enrollment
            if self.date < enrollment.start_date:
                raise ValidationError({"date": "Attendance cannot predate enrollment."})
            if enrollment.end_date and self.date > enrollment.end_date:
                raise ValidationError({"date": "Attendance cannot be after enrollment ended."})
            year = enrollment.section.academic_year
            if self.date < year.start_date or self.date > year.end_date:
                raise ValidationError({"date": "Attendance date must fall inside the academic year."})


class Assessment(TimeStampedModel):
    class Type(models.TextChoices):
        QUIZ = "quiz", "Quiz"
        ASSIGNMENT = "assignment", "Assignment"
        MIDTERM = "midterm", "Midterm"
        FINAL = "final", "Final"
        OTHER = "other", "Other"

    assignment = models.ForeignKey(TeachingAssignment, on_delete=models.CASCADE, related_name="assessments")
    name = models.CharField(max_length=120)
    assessment_type = models.CharField(max_length=20, choices=Type.choices)
    date = models.DateField()
    max_score = models.DecimalField(max_digits=7, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))])
    pass_score = models.DecimalField(max_digits=7, decimal_places=2, validators=[MinValueValidator(Decimal("0.00"))])
    weight_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal("0.00"),
        validators=[MinValueValidator(Decimal("0.00")), MaxValueValidator(Decimal("100.00"))],
    )
    is_published = models.BooleanField(default=False)
    is_locked = models.BooleanField(default=False)

    class Meta:
        ordering = ["-date", "name"]
        unique_together = (("assignment", "name", "date"),)

    def clean(self):
        if self.pass_score > self.max_score:
            raise ValidationError({"pass_score": "Pass score cannot exceed maximum score."})
        if self.assignment_id:
            term = self.assignment.term
            if self.date < term.start_date or self.date > term.end_date:
                raise ValidationError({"date": "Assessment date must fall inside the term."})


class AssessmentResult(TimeStampedModel):
    class Status(models.TextChoices):
        GRADED = "graded", "Graded"
        ABSENT = "absent", "Absent"
        EXCUSED = "excused", "Excused"
        NOT_GRADED = "not_graded", "Not graded"

    assessment = models.ForeignKey(Assessment, on_delete=models.CASCADE, related_name="results")
    enrollment = models.ForeignKey(Enrollment, on_delete=models.CASCADE, related_name="assessment_results")
    score = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.NOT_GRADED)
    remarks = models.CharField(max_length=300, blank=True)
    graded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="graded_results"
    )

    class Meta:
        unique_together = (("assessment", "enrollment"),)

    def clean(self):
        if self.assessment_id and self.enrollment_id:
            if self.enrollment.section_id != self.assessment.assignment.section_id:
                raise ValidationError("Enrollment must belong to the assessed section.")
            if self.score is not None:
                if self.score < 0 or self.score > self.assessment.max_score:
                    raise ValidationError({"score": "Score must be between 0 and the assessment maximum."})
                if self.status != self.Status.GRADED:
                    raise ValidationError({"status": "A numeric score requires graded status."})
            elif self.status == self.Status.GRADED:
                raise ValidationError({"score": "Graded results require a score."})


class FeeCharge(TimeStampedModel):
    class Status(models.TextChoices):
        UNPAID = "unpaid", "Unpaid"
        PARTIAL = "partial", "Partially paid"
        PAID = "paid", "Paid"
        OVERDUE = "overdue", "Overdue"
        WAIVED = "waived", "Waived"

    enrollment = models.ForeignKey(Enrollment, on_delete=models.PROTECT, related_name="fee_charges")
    category = models.CharField(max_length=60)
    description = models.CharField(max_length=250, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))])
    discount_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=Decimal("0.00"), validators=[MinValueValidator(Decimal("0.00"))]
    )
    currency = models.CharField(max_length=3, default="AFN")
    due_date = models.DateField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.UNPAID)

    def clean(self):
        if self.discount_amount > self.amount:
            raise ValidationError({"discount_amount": "Discount cannot exceed the charge amount."})

    @property
    def net_amount(self):
        return self.amount - self.discount_amount


class Payment(TimeStampedModel):
    class Method(models.TextChoices):
        CASH = "cash", "Cash"
        MOBILE_MONEY = "mobile_money", "Mobile money"
        BANK = "bank", "Bank"
        OTHER = "other", "Other"

    fee_charge = models.ForeignKey(FeeCharge, on_delete=models.PROTECT, related_name="payments")
    amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))])
    payment_date = models.DateField(default=timezone.localdate)
    payment_method = models.CharField(max_length=20, choices=Method.choices)
    reference_number = models.CharField(max_length=100, blank=True)
    receipt_number = models.CharField(max_length=80, unique=True)
    received_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="received_payments"
    )
    notes = models.CharField(max_length=300, blank=True)

    def clean(self):
        if self.fee_charge_id and self.amount:
            existing = (
                Payment.objects.filter(fee_charge=self.fee_charge)
                .exclude(pk=self.pk)
                .aggregate(total=models.Sum("amount"))["total"]
                or Decimal("0.00")
            )
            if existing + self.amount > self.fee_charge.net_amount:
                raise ValidationError({"amount": "Payment would exceed the outstanding charge."})


class Expense(TimeStampedModel):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="expenses")
    branch = models.ForeignKey(Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name="expenses")
    title = models.CharField(max_length=150)
    category = models.CharField(max_length=60)
    amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))])
    currency = models.CharField(max_length=3, default="AFN")
    expense_date = models.DateField()
    payment_method = models.CharField(max_length=30, blank=True)
    payee = models.CharField(max_length=120, blank=True)
    reference_number = models.CharField(max_length=100, blank=True)
    description = models.CharField(max_length=300, blank=True)
    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="recorded_expenses"
    )

    def clean(self):
        if self.branch_id and self.branch.school_id != self.school_id:
            raise ValidationError({"branch": "Branch must belong to this school."})


class PayrollEntry(TimeStampedModel):
    class Status(models.TextChoices):
        UNPAID = "unpaid", "Unpaid"
        PAID = "paid", "Paid"
        CANCELLED = "cancelled", "Cancelled"

    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="payroll_entries")
    teacher = models.ForeignKey(Teacher, on_delete=models.PROTECT, null=True, blank=True, related_name="payroll_entries")
    staff = models.ForeignKey(Staff, on_delete=models.PROTECT, null=True, blank=True, related_name="payroll_entries")
    period_start = models.DateField()
    period_end = models.DateField()
    base_amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(Decimal("0.00"))])
    bonus_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=Decimal("0.00"), validators=[MinValueValidator(Decimal("0.00"))]
    )
    deduction_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=Decimal("0.00"), validators=[MinValueValidator(Decimal("0.00"))]
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.UNPAID)
    paid_on = models.DateField(null=True, blank=True)
    payment_method = models.CharField(max_length=30, blank=True)
    reference_number = models.CharField(max_length=100, blank=True)
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="approved_payroll"
    )

    def clean(self):
        if bool(self.teacher_id) == bool(self.staff_id):
            raise ValidationError("Choose exactly one employee: teacher or staff.")
        if self.teacher_id and self.teacher.school_id != self.school_id:
            raise ValidationError({"teacher": "Teacher must belong to this school."})
        if self.staff_id and self.staff.school_id != self.school_id:
            raise ValidationError({"staff": "Staff member must belong to this school."})
        if self.period_end < self.period_start:
            raise ValidationError({"period_end": "Period end cannot predate period start."})
        if self.deduction_amount > self.base_amount + self.bonus_amount:
            raise ValidationError({"deduction_amount": "Deductions cannot exceed gross pay."})
        if self.status == self.Status.PAID and not self.paid_on:
            raise ValidationError({"paid_on": "Paid payroll entries require a payment date."})

    @property
    def net_amount(self):
        return self.base_amount + self.bonus_amount - self.deduction_amount


class Asset(TimeStampedModel):
    class Condition(models.TextChoices):
        NEW = "new", "New"
        GOOD = "good", "Good"
        NEEDS_REPAIR = "needs_repair", "Needs repair"
        DAMAGED = "damaged", "Damaged"

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        IN_STORAGE = "in_storage", "In storage"
        DISPOSED = "disposed", "Disposed"

    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name="assets")
    asset_code = models.CharField(max_length=60)
    name = models.CharField(max_length=150)
    category = models.CharField(max_length=60)
    serial_number = models.CharField(max_length=100, blank=True)
    purchase_date = models.DateField(null=True, blank=True)
    purchase_price = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(Decimal("0.00"))]
    )
    quantity = models.PositiveIntegerField(default=1, validators=[MinValueValidator(1)])
    condition = models.CharField(max_length=20, choices=Condition.choices, default=Condition.GOOD)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    location = models.CharField(max_length=120, blank=True)
    assigned_to = models.CharField(max_length=120, blank=True)
    description = models.CharField(max_length=300, blank=True)

    class Meta:
        unique_together = (("branch", "asset_code"),)


class Announcement(TimeStampedModel):
    class Audience(models.TextChoices):
        ALL = "all", "Everyone"
        STAFF = "staff", "Staff"
        TEACHERS = "teachers", "Teachers"
        GUARDIANS = "guardians", "Guardians"
        STUDENTS = "students", "Students"

    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="announcements")
    branch = models.ForeignKey(Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name="announcements")
    title = models.CharField(max_length=150)
    message = models.TextField()
    audience = models.CharField(max_length=20, choices=Audience.choices, default=Audience.ALL)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="announcements_created"
    )
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    def clean(self):
        if self.branch_id and self.branch.school_id != self.school_id:
            raise ValidationError({"branch": "Branch must belong to this school."})
        if self.is_published and not self.published_at:
            self.published_at = timezone.now()
        if self.expires_at and self.published_at and self.expires_at <= self.published_at:
            raise ValidationError({"expires_at": "Expiry must be after publication."})


class Notification(TimeStampedModel):
    class Type(models.TextChoices):
        GENERAL = "general", "General"
        ANNOUNCEMENT = "announcement", "Announcement"
        FEE = "fee", "Fee"
        ATTENDANCE = "attendance", "Attendance"
        ASSESSMENT = "assessment", "Assessment"

    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="notifications")
    title = models.CharField(max_length=150)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=Type.choices, default=Type.GENERAL)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="notifications_created"
    )


class NotificationRecipient(TimeStampedModel):
    class Channel(models.TextChoices):
        IN_APP = "in_app", "In app"
        EMAIL = "email", "Email"
        SMS = "sms", "SMS"
        PUSH = "push", "Push"

    class DeliveryStatus(models.TextChoices):
        PENDING = "pending", "Pending"
        SENT = "sent", "Sent"
        FAILED = "failed", "Failed"

    notification = models.ForeignKey(Notification, on_delete=models.CASCADE, related_name="recipients")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notification_recipients")
    channel = models.CharField(max_length=20, choices=Channel.choices, default=Channel.IN_APP)
    delivery_status = models.CharField(max_length=20, choices=DeliveryStatus.choices, default=DeliveryStatus.PENDING)
    delivered_at = models.DateTimeField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = (("notification", "user", "channel"),)

    def clean(self):
        if self.is_read and not self.read_at:
            self.read_at = timezone.now()
        if not self.is_read and self.read_at:
            raise ValidationError({"read_at": "Unread notifications cannot have a read timestamp."})


class ActivityLog(models.Model):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="activity_logs")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="activity_logs"
    )
    action = models.CharField(max_length=120)
    entity_type = models.CharField(max_length=80)
    entity_id = models.CharField(max_length=80, blank=True)
    details = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.action} {self.entity_type} {self.entity_id}".strip()
