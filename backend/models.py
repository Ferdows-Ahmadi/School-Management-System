from django.db import models

# Create your models here.
class Student(models.Model):
    Student_id = models.AutoField(
        db_column='Student_id'
    )

    first_name = models.CharField(
        max_length=50,
        db_column='First_name'
    )

    last_name = models.CharField(
        max_length=50,
        db_column='Last_name'
    )
    date_of_birth = models.DateField(
     null=True,
     blank=True,
     db_column='Date_of_birth'   
    )
    admission_date = models.DateField(
        db_column='Admission_date'

    )
    address = models.CharField(
        max_length=250,
        null=True,
        blank=True,
        db_column='Address'
    )

    class Meta:
        manage = False
        db_table = 'Students'
    def __str__(self):
        return f"{self.first_name}{self.last_name}"
