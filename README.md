# EduTrack School Management System

EduTrack is a Django-based school management platform. This fork replaces the original SQL-first prototype with a Django-managed, multi-school architecture.

## What changed

The original repository had a hand-maintained SQL Server dump, duplicate authentication systems, no school/branch tenancy, no real Django migrations, a static frontend, and almost no backend logic. The rebuilt version uses:

- Django authentication as the only authentication system
- School and branch tenancy
- Academic years, terms, grade levels, shifts, rooms, and yearly sections
- Student/guardian profiles and enrollment history
- Teacher/staff profiles and role assignments
- Subjects, teaching assignments, conflict-aware schedules
- Attendance with source/audit metadata
- Assessments and enrollment-linked results
- Fees, payments, expenses, and payroll
- Assets, announcements, notifications, and audit logs
- Real Django migrations
- Environment-based configuration
- Authenticated, school-scoped dashboard
- Django Admin as the initial operational CRUD interface
- Automated tests and CI

## Quick start

### 1. Create and activate a virtual environment

Windows:

```powershell
py -m venv .venv
.venv\Scripts\activate
```

macOS/Linux:

```bash
python -m venv .venv
source .venv/bin/activate
```

### 2. Install dependencies

For the default SQLite development setup:

```bash
pip install -r requirements.txt
```

For SQL Server:

```bash
pip install -r requirements-mssql.txt
```

SQL Server also requires a compatible Microsoft ODBC driver.

### 3. Configure environment variables

Copy the example file:

Windows:

```powershell
copy .env.example .env
```

macOS/Linux:

```bash
cp .env.example .env
```

Change `DJANGO_SECRET_KEY` before any shared or production deployment.

### 4. Apply migrations

```bash
python manage.py migrate
```

### 5. Create an administrator

```bash
python manage.py createsuperuser
```

### 6. Run the application

```bash
python manage.py runserver
```

Open:

- App login: http://127.0.0.1:8000/
- Django Admin: http://127.0.0.1:8000/admin/

## First-time data setup

Use Django Admin in this order:

1. School
2. Branches
3. Academic year
4. Terms
5. Grade levels
6. Shifts and rooms
7. School membership for your user
8. Membership role(s)
9. Teachers/staff/guardians/students
10. Sections
11. Enrollments
12. Subjects
13. Teaching assignments
14. Schedules
15. Attendance, assessments, finance, and other modules

A normal user must have an active `SchoolMembership` to access the dashboard. Superusers can access the first active school even before a membership is created.

## Database options

SQLite is the default for local development and CI.

For SQL Server, set:

```env
DB_ENGINE=mssql
DB_NAME=school_management
DB_HOST=localhost
DB_USER=
DB_PASSWORD=
DB_DRIVER=ODBC Driver 18 for SQL Server
```

The old `School_Management.sql` dump has been removed from the active project because Django migrations are now the source of truth.

## Tests

```bash
python manage.py test
python manage.py check
python manage.py makemigrations --check --dry-run
```

## Architecture

See [docs/architecture.md](docs/architecture.md).

For notes on migrating from the original forked database design, see [docs/legacy-migration.md](docs/legacy-migration.md).
