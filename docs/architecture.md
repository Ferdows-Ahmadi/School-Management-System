# Architecture

## Core tenant structure

```text
School
├── Branch
│   ├── Shift
│   ├── Room
│   └── Section
├── AcademicYear
│   └── Term
└── GradeLevel
```

Every school-owned domain object is scoped through `School`, directly or through a relation that resolves to a school.

## Identity and authorization

Django's built-in user model is the only authentication source.

```text
User
└── SchoolMembership
    └── MembershipRole
```

A user can belong to multiple schools. Roles are represented separately from authentication and can optionally be branch-scoped.

Teacher, staff, guardian, and student profiles may optionally link to a Django user account, but they do not store passwords.

## Academic model

```text
GradeLevel
   └── Section
       ├── Enrollment ── Student
       └── TeachingAssignment
           ├── Subject
           ├── Teacher
           ├── Term
           ├── Schedule
           └── Assessment
               └── AssessmentResult ── Enrollment
```

Schedule validation rejects overlapping teacher, section, and room assignments.

Assessment results reference enrollments rather than raw students, preventing results from being attached to students outside the assessed section.

## Attendance

Attendance references `Enrollment`, not `Student`.

Each enrollment may have only one attendance record per date. Attendance validates:

- Date inside the enrollment period
- Date inside the academic year
- Check-out after check-in
- Status and source choices

## Finance

`FeeCharge` references `Enrollment`.

`Payment` references `FeeCharge` and validates that the payment does not overpay the net charge.

Expenses have dates, school/branch scope, payee, payment method, and audit actor.

Payroll supports either a teacher or staff member, with validation that exactly one employee is selected.

## Communications

Announcements are school-scoped and optionally branch-scoped.

Notifications have per-user delivery/read state through `NotificationRecipient`.

## Database ownership

Django models and migrations are authoritative.

Do not recreate the database from an exported SSMS script and then run migrations on top of it.

## Validation strategy

Important cross-entity rules are implemented in model `clean()` methods and ordinary model writes call `full_clean()` through the shared `ValidatedModel` base class.

Foreign keys are indexed by Django by default, addressing the missing-FK-index problem in the original schema.

## Current UI strategy

The authenticated dashboard is server-rendered with Django templates. Django Admin provides complete CRUD access while dedicated module screens can be added incrementally without duplicating business logic.
