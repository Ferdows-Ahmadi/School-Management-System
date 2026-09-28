# Legacy database migration notes

The original repository stored its schema in `School_Management.sql`. That schema is not compatible with the rebuilt model one-to-one.

## Why the old dump is not used directly

The legacy dump:

- Created the database using a developer-specific MDF/LDF path
- Included Django auth/framework tables manually
- Included a second custom `Users` authentication table
- Had no `School` or `Branch` tenancy
- Mixed grade and section concepts in `Classes`
- Had no Django application migration history for the custom schema
- Used globally unique values that should be school- or branch-scoped

## Recommended migration approach

For a project with no important production data:

1. Create a fresh database.
2. Run `python manage.py migrate`.
3. Re-enter or import business data into the new models.

For a database that already contains real data:

1. Back up the legacy database.
2. Create a separate empty target database.
3. Run Django migrations in the target.
4. Write explicit ETL/import scripts table-by-table.
5. Map:
   - legacy `Classes` → `GradeLevel` + `Section`
   - legacy `Parents` → `Guardian`
   - legacy `Student_parents` → `StudentGuardian`
   - legacy `Enrollments` → `Enrollment`
   - legacy `Users` → Django users + `SchoolMembership` + `MembershipRole`
   - legacy `Teacher_Subjects` / `Class_Subjects` / `Teacher_Classes` → `TeachingAssignment`
   - legacy exams/results → `Assessment` / `AssessmentResult`
   - legacy fees/payments → `FeeCharge` / `Payment`
6. Validate row counts and financial totals before cutover.

Do not point the new application at the old schema and use `--fake` migrations unless you have independently verified every table, key, and constraint.
