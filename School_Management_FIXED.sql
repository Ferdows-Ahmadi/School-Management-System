

USE [master];
GO

IF DB_ID(N'school_management') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [school_management]');
END
GO

USE [school_management];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   ACADEMIC STRUCTURE
   ========================================================= */

CREATE TABLE [dbo].[Academic_years](
    [Academic_year_id] INT IDENTITY(1,1) NOT NULL,
    [Year_Name] NVARCHAR(20) NOT NULL,
    [Start_date] DATE NOT NULL,
    [End_Date] DATE NOT NULL,
    [IsCurrent] BIT NOT NULL CONSTRAINT [DF_Academic_years_IsCurrent] DEFAULT (0),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Academic_years_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Academic_years] PRIMARY KEY CLUSTERED ([Academic_year_id]),
    CONSTRAINT [UQ_Academic_years_Year_Name] UNIQUE ([Year_Name]),
    CONSTRAINT [CK_Academic_years_Dates] CHECK ([End_Date] > [Start_date])
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Academic_years_Current]
ON [dbo].[Academic_years]([IsCurrent])
WHERE [IsCurrent] = 1;
GO

CREATE TABLE [dbo].[Terms](
    [Term_id] INT IDENTITY(1,1) NOT NULL,
    [Academic_year_id] INT NOT NULL,
    [Term_name] NVARCHAR(50) NOT NULL,
    [Term_number] TINYINT NOT NULL,
    [Start_date] DATE NOT NULL,
    [End_date] DATE NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Terms_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Terms] PRIMARY KEY CLUSTERED ([Term_id]),
    CONSTRAINT [UQ_Terms_Year_Name] UNIQUE ([Academic_year_id], [Term_name]),
    CONSTRAINT [UQ_Terms_Year_Number] UNIQUE ([Academic_year_id], [Term_number]),
    CONSTRAINT [CK_Terms_Number] CHECK ([Term_number] BETWEEN 1 AND 12),
    CONSTRAINT [CK_Terms_Dates] CHECK ([End_date] > [Start_date]),
    CONSTRAINT [FK_Terms_Academic_years]
        FOREIGN KEY ([Academic_year_id]) REFERENCES [dbo].[Academic_years]([Academic_year_id])
);
GO

CREATE TABLE [dbo].[Class_rooms](
    [Class_room_id] INT IDENTITY(1,1) NOT NULL,
    [Room_name] NVARCHAR(50) NOT NULL,
    [Capacity] INT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Class_rooms_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Class_rooms] PRIMARY KEY CLUSTERED ([Class_room_id]),
    CONSTRAINT [UQ_Class_rooms_Room_name] UNIQUE ([Room_name]),
    CONSTRAINT [CK_Class_rooms_Capacity] CHECK ([Capacity] IS NULL OR [Capacity] > 0)
);
GO

CREATE TABLE [dbo].[Classes](
    [Class_id] INT IDENTITY(1,1) NOT NULL,
    [Class_name] NVARCHAR(50) NOT NULL,
    [Grade_level] INT NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Classes_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Classes] PRIMARY KEY CLUSTERED ([Class_id]),
    CONSTRAINT [UQ_Classes_Grade_Class] UNIQUE ([Grade_level], [Class_name]),
    CONSTRAINT [CK_Classes_Grade_level] CHECK ([Grade_level] BETWEEN 1 AND 12)
);
GO

/* =========================================================
   PEOPLE AND ACCOUNTS
   ========================================================= */

CREATE TABLE [dbo].[Students](
    [Student_id] INT IDENTITY(1,1) NOT NULL,
    [Student_number] NVARCHAR(30) NOT NULL,
    [First_name] NVARCHAR(50) NOT NULL,
    [Last_name] NVARCHAR(50) NOT NULL,
    [Date_of_birth] DATE NULL,
    [Gender] NVARCHAR(12) NOT NULL,
    [Admission_date] DATE NOT NULL,
    [Phone] NVARCHAR(20) NULL,
    [Address] NVARCHAR(250) NULL,
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Students_Status] DEFAULT (N'Active'),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Students_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Students] PRIMARY KEY CLUSTERED ([Student_id]),
    CONSTRAINT [UQ_Students_Student_number] UNIQUE ([Student_number]),
    CONSTRAINT [CK_Students_Gender] CHECK ([Gender] IN (N'Male', N'Female', N'Other')),
    CONSTRAINT [CK_Students_Status] CHECK ([Status] IN (N'Active', N'Inactive', N'Graduated', N'Withdrawn')),
    CONSTRAINT [CK_Students_Birth_Admission] CHECK ([Date_of_birth] IS NULL OR [Date_of_birth] <= [Admission_date])
);
GO

CREATE TABLE [dbo].[Parents](
    [Parent_id] INT IDENTITY(1,1) NOT NULL,
    [First_name] NVARCHAR(50) NOT NULL,
    [Last_name] NVARCHAR(50) NOT NULL,
    [Phone] NVARCHAR(20) NOT NULL,
    [Email] NVARCHAR(100) NULL,
    [Address] NVARCHAR(250) NULL,
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Parents_IsActive] DEFAULT (1),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Parents_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Parents] PRIMARY KEY CLUSTERED ([Parent_id])
);
GO

CREATE TABLE [dbo].[Teachers](
    [Teacher_id] INT IDENTITY(1,1) NOT NULL,
    [Employee_number] NVARCHAR(30) NOT NULL,
    [First_name] NVARCHAR(50) NOT NULL,
    [Last_name] NVARCHAR(50) NOT NULL,
    [National_id] NVARCHAR(30) NULL,
    [Phone] NVARCHAR(20) NULL,
    [Email] NVARCHAR(100) NULL,
    [Hire_date] DATE NULL,
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Teachers_Status] DEFAULT (N'Active'),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Teachers_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Teachers] PRIMARY KEY CLUSTERED ([Teacher_id]),
    CONSTRAINT [UQ_Teachers_Employee_number] UNIQUE ([Employee_number]),
    CONSTRAINT [CK_Teachers_Status] CHECK ([Status] IN (N'Active', N'OnLeave', N'Inactive', N'Terminated'))
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Teachers_National_id]
ON [dbo].[Teachers]([National_id])
WHERE [National_id] IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Teachers_Email]
ON [dbo].[Teachers]([Email])
WHERE [Email] IS NOT NULL;
GO

CREATE TABLE [dbo].[Staff](
    [Staff_id] INT IDENTITY(1,1) NOT NULL,
    [Employee_number] NVARCHAR(30) NOT NULL,
    [First_name] NVARCHAR(50) NOT NULL,
    [Last_name] NVARCHAR(50) NOT NULL,
    [Phone] NVARCHAR(20) NOT NULL,
    [Email] NVARCHAR(100) NULL,
    [Position] NVARCHAR(100) NOT NULL,
    [National_id] NVARCHAR(30) NOT NULL,
    [Hire_date] DATE NULL,
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Staff_Status] DEFAULT (N'Active'),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Staff_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Staff] PRIMARY KEY CLUSTERED ([Staff_id]),
    CONSTRAINT [UQ_Staff_Employee_number] UNIQUE ([Employee_number]),
    CONSTRAINT [UQ_Staff_National_id] UNIQUE ([National_id]),
    CONSTRAINT [CK_Staff_Status] CHECK ([Status] IN (N'Active', N'OnLeave', N'Inactive', N'Terminated'))
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Staff_Email]
ON [dbo].[Staff]([Email])
WHERE [Email] IS NOT NULL;
GO

CREATE TABLE [dbo].[Users](
    [User_id] INT IDENTITY(1,1) NOT NULL,
    [User_name] NVARCHAR(50) NOT NULL,
    [Password_Hash] NVARCHAR(255) NOT NULL,
    [Role] NVARCHAR(30) NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Users_IsActive] DEFAULT (1),
    [First_name] NVARCHAR(50) NOT NULL,
    [Last_name] NVARCHAR(50) NOT NULL,
    [Email] NVARCHAR(100) NULL,
    [teacher_id] INT NULL,
    [staff_id] INT NULL,
    [parent_id] INT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Users_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([User_id]),
    CONSTRAINT [UQ_Users_User_name] UNIQUE ([User_name]),
    CONSTRAINT [CK_Users_Role] CHECK ([Role] IN (N'Admin', N'Manager', N'Teacher', N'Staff', N'Parent')),
    CONSTRAINT [CK_Users_Profile_Match] CHECK (
        ([Role] IN (N'Admin', N'Manager') AND [teacher_id] IS NULL AND [staff_id] IS NULL AND [parent_id] IS NULL)
        OR
        ([Role] = N'Teacher' AND [teacher_id] IS NOT NULL AND [staff_id] IS NULL AND [parent_id] IS NULL)
        OR
        ([Role] = N'Staff' AND [staff_id] IS NOT NULL AND [teacher_id] IS NULL AND [parent_id] IS NULL)
        OR
        ([Role] = N'Parent' AND [parent_id] IS NOT NULL AND [teacher_id] IS NULL AND [staff_id] IS NULL)
    ),
    CONSTRAINT [FK_Users_Teachers] FOREIGN KEY ([teacher_id]) REFERENCES [dbo].[Teachers]([Teacher_id]),
    CONSTRAINT [FK_Users_Staff] FOREIGN KEY ([staff_id]) REFERENCES [dbo].[Staff]([Staff_id]),
    CONSTRAINT [FK_Users_Parents] FOREIGN KEY ([parent_id]) REFERENCES [dbo].[Parents]([Parent_id])
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Users_Teacher]
ON [dbo].[Users]([teacher_id])
WHERE [teacher_id] IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Users_Staff]
ON [dbo].[Users]([staff_id])
WHERE [staff_id] IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Users_Parent]
ON [dbo].[Users]([parent_id])
WHERE [parent_id] IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Users_Email]
ON [dbo].[Users]([Email])
WHERE [Email] IS NOT NULL;
GO

CREATE TABLE [dbo].[Student_parents](
    [Student_parent_id] INT IDENTITY(1,1) NOT NULL,
    [Student_id] INT NOT NULL,
    [Parent_id] INT NOT NULL,
    [Relationship] NVARCHAR(30) NOT NULL,
    [IsPrimary] BIT NOT NULL CONSTRAINT [DF_Student_parents_IsPrimary] DEFAULT (0),
    [IsEmergencyContact] BIT NOT NULL CONSTRAINT [DF_Student_parents_IsEmergencyContact] DEFAULT (0),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Student_parents_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Student_parents] PRIMARY KEY CLUSTERED ([Student_parent_id]),
    CONSTRAINT [UQ_Student_parents] UNIQUE ([Student_id], [Parent_id]),
    CONSTRAINT [FK_Student_parents_Students] FOREIGN KEY ([Student_id]) REFERENCES [dbo].[Students]([Student_id]),
    CONSTRAINT [FK_Student_parents_Parents] FOREIGN KEY ([Parent_id]) REFERENCES [dbo].[Parents]([Parent_id])
);
GO

CREATE TABLE [dbo].[Emergency_contacts](
    [Emergency_contact_id] INT IDENTITY(1,1) NOT NULL,
    [Student_id] INT NOT NULL,
    [First_name] NVARCHAR(50) NOT NULL,
    [Last_name] NVARCHAR(50) NOT NULL,
    [Relationship] NVARCHAR(30) NOT NULL,
    [Phone] NVARCHAR(20) NOT NULL,
    [IsPrimary] BIT NOT NULL CONSTRAINT [DF_Emergency_contacts_IsPrimary] DEFAULT (0),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Emergency_contacts_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Emergency_contacts] PRIMARY KEY CLUSTERED ([Emergency_contact_id]),
    CONSTRAINT [FK_Emergency_contacts_Students] FOREIGN KEY ([Student_id]) REFERENCES [dbo].[Students]([Student_id])
);
GO

/* =========================================================
   SUBJECTS, ENROLLMENT AND TEACHING
   ========================================================= */

CREATE TABLE [dbo].[Subjects](
    [Subject_id] INT IDENTITY(1,1) NOT NULL,
    [Subject_code] NVARCHAR(20) NOT NULL,
    [Subject_name] NVARCHAR(100) NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Subjects_IsActive] DEFAULT (1),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Subjects_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Subjects] PRIMARY KEY CLUSTERED ([Subject_id]),
    CONSTRAINT [UQ_Subjects_Code] UNIQUE ([Subject_code]),
    CONSTRAINT [UQ_Subjects_Name] UNIQUE ([Subject_name])
);
GO

CREATE TABLE [dbo].[Enrollments](
    [Enrollment_id] INT IDENTITY(1,1) NOT NULL,
    [Student_id] INT NOT NULL,
    [Class_id] INT NOT NULL,
    [Academic_year_id] INT NOT NULL,
    [Enrollment_date] DATE NOT NULL,
    [End_date] DATE NULL,
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Enrollments_Status] DEFAULT (N'Active'),
    [Roll_number] NVARCHAR(30) NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Enrollments_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Enrollments] PRIMARY KEY CLUSTERED ([Enrollment_id]),
    CONSTRAINT [CK_Enrollments_Dates] CHECK ([End_date] IS NULL OR [End_date] >= [Enrollment_date]),
    CONSTRAINT [CK_Enrollments_Status] CHECK ([Status] IN (N'Active', N'Transferred', N'Withdrawn', N'Completed')),
    CONSTRAINT [FK_Enrollments_Students] FOREIGN KEY ([Student_id]) REFERENCES [dbo].[Students]([Student_id]),
    CONSTRAINT [FK_Enrollments_Classes] FOREIGN KEY ([Class_id]) REFERENCES [dbo].[Classes]([Class_id]),
    CONSTRAINT [FK_Enrollments_Academic_years] FOREIGN KEY ([Academic_year_id]) REFERENCES [dbo].[Academic_years]([Academic_year_id])
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Enrollments_Active_Student_Year]
ON [dbo].[Enrollments]([Student_id], [Academic_year_id])
WHERE [Status] = N'Active';
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Enrollments_Roll_Number]
ON [dbo].[Enrollments]([Class_id], [Academic_year_id], [Roll_number])
WHERE [Roll_number] IS NOT NULL AND [Status] = N'Active';
GO

CREATE TABLE [dbo].[Class_Subjects](
    [Class_subject_id] INT IDENTITY(1,1) NOT NULL,
    [Class_id] INT NOT NULL,
    [Subject_id] INT NOT NULL,
    [Academic_year_id] INT NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Class_Subjects_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Class_Subjects] PRIMARY KEY CLUSTERED ([Class_subject_id]),
    CONSTRAINT [UQ_Class_Subjects] UNIQUE ([Class_id], [Subject_id], [Academic_year_id]),
    CONSTRAINT [FK_Class_Subjects_Classes] FOREIGN KEY ([Class_id]) REFERENCES [dbo].[Classes]([Class_id]),
    CONSTRAINT [FK_Class_Subjects_Subjects] FOREIGN KEY ([Subject_id]) REFERENCES [dbo].[Subjects]([Subject_id]),
    CONSTRAINT [FK_Class_Subjects_Academic_years] FOREIGN KEY ([Academic_year_id]) REFERENCES [dbo].[Academic_years]([Academic_year_id])
);
GO

CREATE TABLE [dbo].[Teacher_Subjects](
    [TeacherSubject_id] INT IDENTITY(1,1) NOT NULL,
    [Teacher_id] INT NOT NULL,
    [Subject_id] INT NOT NULL,
    [Academic_year_id] INT NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Teacher_Subjects_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Teacher_Subjects] PRIMARY KEY CLUSTERED ([TeacherSubject_id]),
    CONSTRAINT [UQ_Teacher_Subjects] UNIQUE ([Teacher_id], [Subject_id], [Academic_year_id]),
    CONSTRAINT [FK_Teacher_Subjects_Teachers] FOREIGN KEY ([Teacher_id]) REFERENCES [dbo].[Teachers]([Teacher_id]),
    CONSTRAINT [FK_Teacher_Subjects_Subjects] FOREIGN KEY ([Subject_id]) REFERENCES [dbo].[Subjects]([Subject_id]),
    CONSTRAINT [FK_Teacher_Subjects_Academic_years] FOREIGN KEY ([Academic_year_id]) REFERENCES [dbo].[Academic_years]([Academic_year_id])
);
GO

CREATE TABLE [dbo].[Teacher_Classes](
    [Teacher_Class_id] INT IDENTITY(1,1) NOT NULL,
    [Teacher_id] INT NOT NULL,
    [Class_id] INT NOT NULL,
    [Academic_year_id] INT NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Teacher_Classes_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Teacher_Classes] PRIMARY KEY CLUSTERED ([Teacher_Class_id]),
    CONSTRAINT [UQ_Teacher_Classes] UNIQUE ([Teacher_id], [Class_id], [Academic_year_id]),
    CONSTRAINT [FK_Teacher_Classes_Teachers] FOREIGN KEY ([Teacher_id]) REFERENCES [dbo].[Teachers]([Teacher_id]),
    CONSTRAINT [FK_Teacher_Classes_Classes] FOREIGN KEY ([Class_id]) REFERENCES [dbo].[Classes]([Class_id]),
    CONSTRAINT [FK_Teacher_Classes_Academic_years] FOREIGN KEY ([Academic_year_id]) REFERENCES [dbo].[Academic_years]([Academic_year_id])
);
GO

CREATE TABLE [dbo].[Class_Schedules](
    [Schedule_id] INT IDENTITY(1,1) NOT NULL,
    [Class_id] INT NOT NULL,
    [Subject_id] INT NOT NULL,
    [Teacher_id] INT NOT NULL,
    [Classroom_id] INT NULL,
    [Academic_year_id] INT NOT NULL,
    [Term_id] INT NOT NULL,
    [Day_of_Week] TINYINT NOT NULL,
    [Start_time] TIME(0) NOT NULL,
    [End_time] TIME(0) NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Class_Schedules_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Class_Schedules] PRIMARY KEY CLUSTERED ([Schedule_id]),
    CONSTRAINT [UQ_Class_Schedules_Exact] UNIQUE (
        [Class_id], [Subject_id], [Teacher_id], [Academic_year_id],
        [Term_id], [Day_of_Week], [Start_time], [End_time]
    ),
    CONSTRAINT [CK_Class_Schedules_Day] CHECK ([Day_of_Week] BETWEEN 1 AND 7),
    CONSTRAINT [CK_Class_Schedules_Time] CHECK ([End_time] > [Start_time]),
    CONSTRAINT [FK_Class_Schedules_Classes] FOREIGN KEY ([Class_id]) REFERENCES [dbo].[Classes]([Class_id]),
    CONSTRAINT [FK_Class_Schedules_Subjects] FOREIGN KEY ([Subject_id]) REFERENCES [dbo].[Subjects]([Subject_id]),
    CONSTRAINT [FK_Class_Schedules_Teachers] FOREIGN KEY ([Teacher_id]) REFERENCES [dbo].[Teachers]([Teacher_id]),
    CONSTRAINT [FK_Class_Schedules_Class_rooms] FOREIGN KEY ([Classroom_id]) REFERENCES [dbo].[Class_rooms]([Class_room_id]),
    CONSTRAINT [FK_Class_Schedules_Academic_years] FOREIGN KEY ([Academic_year_id]) REFERENCES [dbo].[Academic_years]([Academic_year_id]),
    CONSTRAINT [FK_Class_Schedules_Terms] FOREIGN KEY ([Term_id]) REFERENCES [dbo].[Terms]([Term_id]),
    CONSTRAINT [FK_Class_Schedules_Class_Subjects]
        FOREIGN KEY ([Class_id], [Subject_id], [Academic_year_id])
        REFERENCES [dbo].[Class_Subjects]([Class_id], [Subject_id], [Academic_year_id]),
    CONSTRAINT [FK_Class_Schedules_Teacher_Subjects]
        FOREIGN KEY ([Teacher_id], [Subject_id], [Academic_year_id])
        REFERENCES [dbo].[Teacher_Subjects]([Teacher_id], [Subject_id], [Academic_year_id]),
    CONSTRAINT [FK_Class_Schedules_Teacher_Classes]
        FOREIGN KEY ([Teacher_id], [Class_id], [Academic_year_id])
        REFERENCES [dbo].[Teacher_Classes]([Teacher_id], [Class_id], [Academic_year_id])
);
GO

/* =========================================================
   ATTENDANCE
   ========================================================= */

CREATE TABLE [dbo].[Attendance](
    [Attendance_id] INT IDENTITY(1,1) NOT NULL,
    [Enrollment_id] INT NOT NULL,
    [Attendance_Date] DATE NOT NULL,
    [Status] NVARCHAR(20) NOT NULL,
    [Check_inTime] TIME(0) NULL,
    [Check_outTime] TIME(0) NULL,
    [Source] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Attendance_Source] DEFAULT (N'Manual'),
    [Remarks] NVARCHAR(250) NULL,
    [Recorded_by] INT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Attendance_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Attendance] PRIMARY KEY CLUSTERED ([Attendance_id]),
    CONSTRAINT [UQ_Attendance] UNIQUE ([Enrollment_id], [Attendance_Date]),
    CONSTRAINT [CK_Attendance_Status] CHECK ([Status] IN (N'Present', N'Absent', N'Late', N'Excused')),
    CONSTRAINT [CK_Attendance_Source] CHECK ([Source] IN (N'Manual', N'Fingerprint', N'Device', N'Import')),
    CONSTRAINT [CK_Attendance_Times] CHECK (
        [Check_outTime] IS NULL OR [Check_inTime] IS NULL OR [Check_outTime] > [Check_inTime]
    ),
    CONSTRAINT [CK_Attendance_Absent_Times] CHECK (
        ([Status] IN (N'Absent', N'Excused') AND [Check_inTime] IS NULL AND [Check_outTime] IS NULL)
        OR
        ([Status] IN (N'Present', N'Late'))
    ),
    CONSTRAINT [FK_Attendance_Enrollments] FOREIGN KEY ([Enrollment_id]) REFERENCES [dbo].[Enrollments]([Enrollment_id]),
    CONSTRAINT [FK_Attendance_Users] FOREIGN KEY ([Recorded_by]) REFERENCES [dbo].[Users]([User_id])
);
GO

/* =========================================================
   EXAMS AND RESULTS
   ========================================================= */

CREATE TABLE [dbo].[Exams](
    [Exam_id] INT IDENTITY(1,1) NOT NULL,
    [Exam_name] NVARCHAR(100) NOT NULL,
    [Exam_type] NVARCHAR(30) NOT NULL,
    [Term_id] INT NOT NULL,
    [Class_id] INT NOT NULL,
    [Start_date] DATE NOT NULL,
    [End_date] DATE NOT NULL,
    [IsPublished] BIT NOT NULL CONSTRAINT [DF_Exams_IsPublished] DEFAULT (0),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Exams_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Exams] PRIMARY KEY CLUSTERED ([Exam_id]),
    CONSTRAINT [UQ_Exams_Name] UNIQUE ([Class_id], [Term_id], [Exam_name]),
    CONSTRAINT [CK_Exams_Type] CHECK ([Exam_type] IN (N'Quiz', N'Midterm', N'Final', N'Other')),
    CONSTRAINT [CK_Exams_Dates] CHECK ([End_date] >= [Start_date]),
    CONSTRAINT [FK_Exams_Terms] FOREIGN KEY ([Term_id]) REFERENCES [dbo].[Terms]([Term_id]),
    CONSTRAINT [FK_Exams_Classes] FOREIGN KEY ([Class_id]) REFERENCES [dbo].[Classes]([Class_id])
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Exams_Midterm]
ON [dbo].[Exams]([Class_id], [Term_id])
WHERE [Exam_type] = N'Midterm';
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Exams_Final]
ON [dbo].[Exams]([Class_id], [Term_id])
WHERE [Exam_type] = N'Final';
GO

CREATE TABLE [dbo].[Exam_Subjects](
    [Exam_subject_id] INT IDENTITY(1,1) NOT NULL,
    [Exam_id] INT NOT NULL,
    [Subject_id] INT NOT NULL,
    [Exam_date] DATE NOT NULL,
    [Max_score] DECIMAL(7,2) NOT NULL,
    [Pass_score] DECIMAL(7,2) NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Exam_Subjects_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Exam_Subjects] PRIMARY KEY CLUSTERED ([Exam_subject_id]),
    CONSTRAINT [UQ_Exam_Subjects] UNIQUE ([Exam_id], [Subject_id]),
    CONSTRAINT [CK_Exam_Subjects_Scores] CHECK ([Max_score] > 0 AND [Pass_score] >= 0 AND [Pass_score] <= [Max_score]),
    CONSTRAINT [FK_Exam_Subjects_Exams] FOREIGN KEY ([Exam_id]) REFERENCES [dbo].[Exams]([Exam_id]),
    CONSTRAINT [FK_Exam_Subjects_Subjects] FOREIGN KEY ([Subject_id]) REFERENCES [dbo].[Subjects]([Subject_id])
);
GO

CREATE TABLE [dbo].[Exams_Results](
    [Exam_result_id] INT IDENTITY(1,1) NOT NULL,
    [Exam_subject_id] INT NOT NULL,
    [Enrollment_id] INT NOT NULL,
    [Score] DECIMAL(7,2) NULL,
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Exams_Results_Status] DEFAULT (N'NotGraded'),
    [Remarks] NVARCHAR(250) NULL,
    [Recorded_by] INT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Exams_Results_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Exams_Results] PRIMARY KEY CLUSTERED ([Exam_result_id]),
    CONSTRAINT [UQ_Exams_Results] UNIQUE ([Exam_subject_id], [Enrollment_id]),
    CONSTRAINT [CK_Exams_Results_Status] CHECK ([Status] IN (N'Graded', N'Absent', N'Excused', N'NotGraded')),
    CONSTRAINT [CK_Exams_Results_Score_Status] CHECK (
        ([Status] = N'Graded' AND [Score] IS NOT NULL AND [Score] >= 0)
        OR
        ([Status] <> N'Graded' AND [Score] IS NULL)
    ),
    CONSTRAINT [FK_Exams_Results_Exam_Subjects] FOREIGN KEY ([Exam_subject_id]) REFERENCES [dbo].[Exam_Subjects]([Exam_subject_id]),
    CONSTRAINT [FK_Exams_Results_Enrollments] FOREIGN KEY ([Enrollment_id]) REFERENCES [dbo].[Enrollments]([Enrollment_id]),
    CONSTRAINT [FK_Exams_Results_Users] FOREIGN KEY ([Recorded_by]) REFERENCES [dbo].[Users]([User_id])
);
GO

/* =========================================================
   FINANCE
   ========================================================= */

CREATE TABLE [dbo].[Fees](
    [Fee_id] INT IDENTITY(1,1) NOT NULL,
    [Enrollment_id] INT NOT NULL,
    [Amount] DECIMAL(12,2) NOT NULL,
    [Discount_amount] DECIMAL(12,2) NOT NULL CONSTRAINT [DF_Fees_Discount] DEFAULT (0),
    [Description] NVARCHAR(250) NULL,
    [Fee_Month] TINYINT NULL,
    [FeeType] NVARCHAR(30) NOT NULL CONSTRAINT [DF_Fees_FeeType] DEFAULT (N'Tuition'),
    [Due_date] DATE NOT NULL,
    [Currency] CHAR(3) NOT NULL CONSTRAINT [DF_Fees_Currency] DEFAULT ('AFN'),
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Fees_Status] DEFAULT (N'Unpaid'),
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Fees_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Fees] PRIMARY KEY CLUSTERED ([Fee_id]),
    CONSTRAINT [CK_Fees_Amount] CHECK ([Amount] > 0),
    CONSTRAINT [CK_Fees_Discount] CHECK ([Discount_amount] >= 0 AND [Discount_amount] <= [Amount]),
    CONSTRAINT [CK_Fees_Month] CHECK ([Fee_Month] IS NULL OR [Fee_Month] BETWEEN 1 AND 12),
    CONSTRAINT [CK_Fees_Type] CHECK ([FeeType] IN (N'Tuition', N'Transport', N'Other')),
    CONSTRAINT [CK_Fees_Status] CHECK ([Status] IN (N'Unpaid', N'Partial', N'Paid', N'Waived')),
    CONSTRAINT [FK_Fees_Enrollments] FOREIGN KEY ([Enrollment_id]) REFERENCES [dbo].[Enrollments]([Enrollment_id])
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Fees_Monthly]
ON [dbo].[Fees]([Enrollment_id], [Fee_Month], [FeeType])
WHERE [Fee_Month] IS NOT NULL;
GO

CREATE TABLE [dbo].[Fees_payments](
    [Payment_id] INT IDENTITY(1,1) NOT NULL,
    [fee_id] INT NOT NULL,
    [Amount] DECIMAL(12,2) NOT NULL,
    [Payment_date] DATE NOT NULL,
    [payment_method] NVARCHAR(30) NOT NULL,
    [Reference_Number] NVARCHAR(100) NULL,
    [Receipt_Number] NVARCHAR(80) NOT NULL,
    [Received_by] INT NULL,
    [Notes] NVARCHAR(250) NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Fees_payments_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Fees_payments] PRIMARY KEY CLUSTERED ([Payment_id]),
    CONSTRAINT [UQ_Fees_payments_Receipt] UNIQUE ([Receipt_Number]),
    CONSTRAINT [CK_Fees_payments_Amount] CHECK ([Amount] > 0),
    CONSTRAINT [CK_Fees_payments_Method] CHECK ([payment_method] IN (N'Cash', N'MobileMoney', N'Bank', N'Other')),
    CONSTRAINT [FK_Fees_payments_Fees] FOREIGN KEY ([fee_id]) REFERENCES [dbo].[Fees]([Fee_id]),
    CONSTRAINT [FK_Fees_payments_Users] FOREIGN KEY ([Received_by]) REFERENCES [dbo].[Users]([User_id])
);
GO

CREATE TABLE [dbo].[Expenses](
    [Expenses_id] INT IDENTITY(1,1) NOT NULL,
    [Expenses_title] NVARCHAR(150) NOT NULL,
    [Amount] DECIMAL(12,2) NOT NULL,
    [Category] NVARCHAR(50) NOT NULL,
    [Expense_date] DATE NOT NULL,
    [Payment_method] NVARCHAR(30) NULL,
    [Payee] NVARCHAR(120) NULL,
    [Reference_Number] NVARCHAR(100) NULL,
    [Description] NVARCHAR(250) NULL,
    [Recorded_by] INT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Expenses_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Expenses] PRIMARY KEY CLUSTERED ([Expenses_id]),
    CONSTRAINT [CK_Expenses_Amount] CHECK ([Amount] > 0),
    CONSTRAINT [CK_Expenses_Payment_method] CHECK (
        [Payment_method] IS NULL OR [Payment_method] IN (N'Cash', N'MobileMoney', N'Bank', N'Other')
    ),
    CONSTRAINT [FK_Expenses_Users] FOREIGN KEY ([Recorded_by]) REFERENCES [dbo].[Users]([User_id])
);
GO

CREATE TABLE [dbo].[Salaries](
    [Salary_id] INT IDENTITY(1,1) NOT NULL,
    [Teacher_id] INT NULL,
    [Staff_id] INT NULL,
    [Salary_month] TINYINT NOT NULL,
    [Salary_year] SMALLINT NOT NULL,
    [Base_amount] DECIMAL(12,2) NOT NULL,
    [Bonus_amount] DECIMAL(12,2) NOT NULL CONSTRAINT [DF_Salaries_Bonus] DEFAULT (0),
    [Deduction_amount] DECIMAL(12,2) NOT NULL CONSTRAINT [DF_Salaries_Deduction] DEFAULT (0),
    [Payment_status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Salaries_Status] DEFAULT (N'Unpaid'),
    [Payment_date] DATE NULL,
    [Payment_method] NVARCHAR(30) NULL,
    [Reference_Number] NVARCHAR(100) NULL,
    [Recorded_by] INT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Salaries_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Salaries] PRIMARY KEY CLUSTERED ([Salary_id]),
    CONSTRAINT [CK_Salaries_Employee] CHECK (
        ([Teacher_id] IS NOT NULL AND [Staff_id] IS NULL)
        OR
        ([Teacher_id] IS NULL AND [Staff_id] IS NOT NULL)
    ),
    CONSTRAINT [CK_Salaries_Month] CHECK ([Salary_month] BETWEEN 1 AND 12),
    CONSTRAINT [CK_Salaries_Year] CHECK ([Salary_year] BETWEEN 2000 AND 2200),
    CONSTRAINT [CK_Salaries_Amounts] CHECK (
        [Base_amount] > 0 AND [Bonus_amount] >= 0 AND [Deduction_amount] >= 0
        AND [Deduction_amount] <= [Base_amount] + [Bonus_amount]
    ),
    CONSTRAINT [CK_Salaries_Status] CHECK ([Payment_status] IN (N'Paid', N'Unpaid')),
    CONSTRAINT [CK_Salaries_Payment_date] CHECK (
        ([Payment_status] = N'Paid' AND [Payment_date] IS NOT NULL AND [Payment_method] IS NOT NULL)
        OR
        ([Payment_status] = N'Unpaid' AND [Payment_date] IS NULL)
    ),
    CONSTRAINT [CK_Salaries_Payment_method] CHECK (
        [Payment_method] IS NULL OR [Payment_method] IN (N'Cash', N'MobileMoney', N'Bank', N'Other')
    ),
    CONSTRAINT [FK_Salaries_Teachers] FOREIGN KEY ([Teacher_id]) REFERENCES [dbo].[Teachers]([Teacher_id]),
    CONSTRAINT [FK_Salaries_Staff] FOREIGN KEY ([Staff_id]) REFERENCES [dbo].[Staff]([Staff_id]),
    CONSTRAINT [FK_Salaries_Users] FOREIGN KEY ([Recorded_by]) REFERENCES [dbo].[Users]([User_id])
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Salaries_Teacher_Period]
ON [dbo].[Salaries]([Teacher_id], [Salary_year], [Salary_month])
WHERE [Teacher_id] IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Salaries_Staff_Period]
ON [dbo].[Salaries]([Staff_id], [Salary_year], [Salary_month])
WHERE [Staff_id] IS NOT NULL;
GO

/* =========================================================
   ASSETS, COMMUNICATION AND AUDIT
   ========================================================= */

CREATE TABLE [dbo].[Assets](
    [Asset_id] INT IDENTITY(1,1) NOT NULL,
    [Asset_code] NVARCHAR(50) NOT NULL,
    [Asset_name] NVARCHAR(150) NOT NULL,
    [Asset_Category] NVARCHAR(50) NOT NULL,
    [Purchase_Date] DATE NULL,
    [Purchase_price] DECIMAL(12,2) NULL,
    [Quantity] INT NOT NULL CONSTRAINT [DF_Assets_Quantity] DEFAULT (1),
    [Condition] NVARCHAR(30) NOT NULL,
    [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Assets_Status] DEFAULT (N'Active'),
    [Location] NVARCHAR(100) NULL,
    [Assigned_to] NVARCHAR(120) NULL,
    [Description] NVARCHAR(250) NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Assets_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Assets] PRIMARY KEY CLUSTERED ([Asset_id]),
    CONSTRAINT [UQ_Assets_Code] UNIQUE ([Asset_code]),
    CONSTRAINT [CK_Assets_Purchase_price] CHECK ([Purchase_price] IS NULL OR [Purchase_price] >= 0),
    CONSTRAINT [CK_Assets_Quantity] CHECK ([Quantity] >= 0),
    CONSTRAINT [CK_Assets_Condition] CHECK ([Condition] IN (N'New', N'Good', N'NeedsRepair', N'Damaged')),
    CONSTRAINT [CK_Assets_Status] CHECK ([Status] IN (N'Active', N'InStorage', N'Disposed'))
);
GO

CREATE TABLE [dbo].[Announcements](
    [Announcement_id] INT IDENTITY(1,1) NOT NULL,
    [Title] NVARCHAR(150) NOT NULL,
    [Message] NVARCHAR(1000) NOT NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Announcements_CreatedAt] DEFAULT (SYSDATETIME()),
    [Created_by] INT NULL,
    [IsPublished] BIT NOT NULL CONSTRAINT [DF_Announcements_IsPublished] DEFAULT (0),
    [PublishedAt] DATETIME2(0) NULL,
    [ExpiresAt] DATETIME2(0) NULL,
    CONSTRAINT [PK_Announcements] PRIMARY KEY CLUSTERED ([Announcement_id]),
    CONSTRAINT [CK_Announcements_Published] CHECK (
        ([IsPublished] = 0 AND [PublishedAt] IS NULL)
        OR
        ([IsPublished] = 1 AND [PublishedAt] IS NOT NULL)
    ),
    CONSTRAINT [CK_Announcements_Expiry] CHECK (
        [ExpiresAt] IS NULL OR [PublishedAt] IS NULL OR [ExpiresAt] > [PublishedAt]
    ),
    CONSTRAINT [FK_Announcements_Users] FOREIGN KEY ([Created_by]) REFERENCES [dbo].[Users]([User_id])
);
GO

CREATE TABLE [dbo].[Notifications](
    [Notification_id] INT IDENTITY(1,1) NOT NULL,
    [Title] NVARCHAR(150) NOT NULL,
    [Message] NVARCHAR(500) NOT NULL,
    [NotificationType] NVARCHAR(30) NOT NULL,
    [Created_by] INT NULL,
    [Created_At] DATETIME2(0) NOT NULL CONSTRAINT [DF_Notifications_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Notifications] PRIMARY KEY CLUSTERED ([Notification_id]),
    CONSTRAINT [CK_Notifications_Type] CHECK ([NotificationType] IN (N'General', N'Announcement', N'Fee', N'Attendance', N'Exam')),
    CONSTRAINT [FK_Notifications_Users] FOREIGN KEY ([Created_by]) REFERENCES [dbo].[Users]([User_id])
);
GO

CREATE TABLE [dbo].[Notification_recipients](
    [Notification_recipient_id] INT IDENTITY(1,1) NOT NULL,
    [Notification_id] INT NOT NULL,
    [parent_id] INT NULL,
    [User_id] INT NULL,
    [Channel] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Notification_recipients_Channel] DEFAULT (N'InApp'),
    [DeliveryStatus] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Notification_recipients_DeliveryStatus] DEFAULT (N'Pending'),
    [DeliveredAt] DATETIME2(0) NULL,
    [IsRead] BIT NOT NULL CONSTRAINT [DF_Notification_recipients_IsRead] DEFAULT (0),
    [ReadAt] DATETIME2(0) NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Notification_recipients_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Notification_recipients] PRIMARY KEY CLUSTERED ([Notification_recipient_id]),
    CONSTRAINT [CK_Notification_recipients_Recipient] CHECK (
        ([parent_id] IS NOT NULL AND [User_id] IS NULL)
        OR
        ([parent_id] IS NULL AND [User_id] IS NOT NULL)
    ),
    CONSTRAINT [CK_Notification_recipients_Channel] CHECK ([Channel] IN (N'InApp', N'Email', N'SMS', N'Push')),
    CONSTRAINT [CK_Notification_recipients_Delivery] CHECK ([DeliveryStatus] IN (N'Pending', N'Sent', N'Failed')),
    CONSTRAINT [CK_Notification_recipients_DeliveredAt] CHECK (
        [DeliveryStatus] <> N'Sent' OR [DeliveredAt] IS NOT NULL
    ),
    CONSTRAINT [CK_Notification_recipients_Read] CHECK (
        ([IsRead] = 0 AND [ReadAt] IS NULL)
        OR
        ([IsRead] = 1 AND [ReadAt] IS NOT NULL)
    ),
    CONSTRAINT [FK_Notification_recipients_Notifications] FOREIGN KEY ([Notification_id]) REFERENCES [dbo].[Notifications]([Notification_id]),
    CONSTRAINT [FK_Notification_recipients_Parents] FOREIGN KEY ([parent_id]) REFERENCES [dbo].[Parents]([Parent_id]),
    CONSTRAINT [FK_Notification_recipients_Users] FOREIGN KEY ([User_id]) REFERENCES [dbo].[Users]([User_id])
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Notification_recipients_Parent]
ON [dbo].[Notification_recipients]([Notification_id], [parent_id], [Channel])
WHERE [parent_id] IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_Notification_recipients_User]
ON [dbo].[Notification_recipients]([Notification_id], [User_id], [Channel])
WHERE [User_id] IS NOT NULL;
GO

CREATE TABLE [dbo].[Activity_log](
    [Activity_log_id] INT IDENTITY(1,1) NOT NULL,
    [User_id] INT NULL,
    [Action] NVARCHAR(100) NOT NULL,
    [Table_name] NVARCHAR(100) NOT NULL,
    [Record_id] INT NULL,
    [Details] NVARCHAR(1000) NULL,
    [CreatedAt] DATETIME2(0) NOT NULL CONSTRAINT [DF_Activity_log_CreatedAt] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_Activity_log] PRIMARY KEY CLUSTERED ([Activity_log_id]),
    CONSTRAINT [FK_Activity_log_Users] FOREIGN KEY ([User_id]) REFERENCES [dbo].[Users]([User_id])
);
GO

/* =========================================================
   SUPPORTING INDEXES FOR FOREIGN KEYS AND COMMON QUERIES
   ========================================================= */

CREATE NONCLUSTERED INDEX [IX_Terms_Academic_year] ON [dbo].[Terms]([Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Student_parents_Parent] ON [dbo].[Student_parents]([Parent_id]);
CREATE NONCLUSTERED INDEX [IX_Emergency_contacts_Student] ON [dbo].[Emergency_contacts]([Student_id]);
CREATE NONCLUSTERED INDEX [IX_Enrollments_Class_Year] ON [dbo].[Enrollments]([Class_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Subjects_Subject_Year] ON [dbo].[Class_Subjects]([Subject_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Teacher_Subjects_Subject_Year] ON [dbo].[Teacher_Subjects]([Subject_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Teacher_Classes_Class_Year] ON [dbo].[Teacher_Classes]([Class_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Teacher_Term_Day] ON [dbo].[Class_Schedules]([Teacher_id], [Term_id], [Day_of_Week], [Start_time], [End_time]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Class_Term_Day] ON [dbo].[Class_Schedules]([Class_id], [Term_id], [Day_of_Week], [Start_time], [End_time]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Room_Term_Day] ON [dbo].[Class_Schedules]([Classroom_id], [Term_id], [Day_of_Week], [Start_time], [End_time]) WHERE [Classroom_id] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Attendance_Date] ON [dbo].[Attendance]([Attendance_Date], [Status]);
CREATE NONCLUSTERED INDEX [IX_Attendance_Recorded_by] ON [dbo].[Attendance]([Recorded_by]) WHERE [Recorded_by] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Exams_Term_Class] ON [dbo].[Exams]([Term_id], [Class_id]);
CREATE NONCLUSTERED INDEX [IX_Exam_Subjects_Subject] ON [dbo].[Exam_Subjects]([Subject_id]);
CREATE NONCLUSTERED INDEX [IX_Exams_Results_Enrollment] ON [dbo].[Exams_Results]([Enrollment_id]);
CREATE NONCLUSTERED INDEX [IX_Fees_Enrollment_Status] ON [dbo].[Fees]([Enrollment_id], [Status]);
CREATE NONCLUSTERED INDEX [IX_Fees_payments_Fee_Date] ON [dbo].[Fees_payments]([fee_id], [Payment_date]);
CREATE NONCLUSTERED INDEX [IX_Expenses_Date] ON [dbo].[Expenses]([Expense_date]);
CREATE NONCLUSTERED INDEX [IX_Notifications_Created_by] ON [dbo].[Notifications]([Created_by]) WHERE [Created_by] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Activity_log_User_Date] ON [dbo].[Activity_log]([User_id], [CreatedAt]) WHERE [User_id] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Enrollments_Academic_year] ON [dbo].[Enrollments]([Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Subjects_Academic_year] ON [dbo].[Class_Subjects]([Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Teacher_Subjects_Academic_year] ON [dbo].[Teacher_Subjects]([Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Teacher_Classes_Academic_year] ON [dbo].[Teacher_Classes]([Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Subject_Year] ON [dbo].[Class_Schedules]([Subject_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Academic_year] ON [dbo].[Class_Schedules]([Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Term] ON [dbo].[Class_Schedules]([Term_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Class_Subject_Year] ON [dbo].[Class_Schedules]([Class_id], [Subject_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Teacher_Subject_Year] ON [dbo].[Class_Schedules]([Teacher_id], [Subject_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Class_Schedules_Teacher_Class_Year] ON [dbo].[Class_Schedules]([Teacher_id], [Class_id], [Academic_year_id]);
CREATE NONCLUSTERED INDEX [IX_Exams_Results_Recorded_by] ON [dbo].[Exams_Results]([Recorded_by]) WHERE [Recorded_by] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Fees_payments_Received_by] ON [dbo].[Fees_payments]([Received_by]) WHERE [Received_by] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Expenses_Recorded_by] ON [dbo].[Expenses]([Recorded_by]) WHERE [Recorded_by] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Salaries_Recorded_by] ON [dbo].[Salaries]([Recorded_by]) WHERE [Recorded_by] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Announcements_Created_by] ON [dbo].[Announcements]([Created_by]) WHERE [Created_by] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Notification_recipients_Parent_lookup] ON [dbo].[Notification_recipients]([parent_id], [Notification_id]) WHERE [parent_id] IS NOT NULL;
CREATE NONCLUSTERED INDEX [IX_Notification_recipients_User_lookup] ON [dbo].[Notification_recipients]([User_id], [Notification_id]) WHERE [User_id] IS NOT NULL;
GO

/* =========================================================
   CROSS-TABLE INTEGRITY TRIGGERS
   ========================================================= */

CREATE OR ALTER TRIGGER [dbo].[TR_Terms_Validate_AcademicYear]
ON [dbo].[Terms]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Academic_years] y ON y.[Academic_year_id] = i.[Academic_year_id]
        WHERE i.[Start_date] < y.[Start_date]
           OR i.[End_date] > y.[End_Date]
    )
    BEGIN
        THROW 50001, 'Term dates must fall inside the academic year.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Terms] t
          ON t.[Academic_year_id] = i.[Academic_year_id]
         AND t.[Term_id] <> i.[Term_id]
         AND t.[Start_date] <= i.[End_date]
         AND t.[End_date] >= i.[Start_date]
    )
    BEGIN
        THROW 50010, 'Terms in the same academic year cannot overlap.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_Enrollments_Validate_Dates]
ON [dbo].[Enrollments]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Academic_years] y ON y.[Academic_year_id] = i.[Academic_year_id]
        WHERE i.[Enrollment_date] < y.[Start_date]
           OR i.[Enrollment_date] > y.[End_Date]
           OR (i.[End_date] IS NOT NULL AND i.[End_date] > y.[End_Date])
    )
    BEGIN
        THROW 50002, 'Enrollment dates must fall inside the academic year.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_Class_Schedules_Validate]
ON [dbo].[Class_Schedules]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Terms] t ON t.[Term_id] = i.[Term_id]
        WHERE t.[Academic_year_id] <> i.[Academic_year_id]
    )
    BEGIN
        THROW 50003, 'Schedule term must belong to the selected academic year.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Class_Schedules] s
          ON s.[Schedule_id] <> i.[Schedule_id]
         AND s.[Term_id] = i.[Term_id]
         AND s.[Day_of_Week] = i.[Day_of_Week]
         AND s.[Start_time] < i.[End_time]
         AND s.[End_time] > i.[Start_time]
         AND (
             s.[Teacher_id] = i.[Teacher_id]
             OR s.[Class_id] = i.[Class_id]
             OR (
                 i.[Classroom_id] IS NOT NULL
                 AND s.[Classroom_id] = i.[Classroom_id]
             )
         )
    )
    BEGIN
        THROW 50004, 'Schedule conflict: teacher, class, or classroom has an overlapping period.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_Attendance_Validate_Date]
ON [dbo].[Attendance]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Enrollments] e ON e.[Enrollment_id] = i.[Enrollment_id]
        JOIN [dbo].[Academic_years] y ON y.[Academic_year_id] = e.[Academic_year_id]
        WHERE i.[Attendance_Date] < e.[Enrollment_date]
           OR (e.[End_date] IS NOT NULL AND i.[Attendance_Date] > e.[End_date])
           OR i.[Attendance_Date] < y.[Start_date]
           OR i.[Attendance_Date] > y.[End_Date]
    )
    BEGIN
        THROW 50005, 'Attendance date must be within the student enrollment and academic year.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_Exams_Validate_Dates]
ON [dbo].[Exams]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Terms] t ON t.[Term_id] = i.[Term_id]
        WHERE i.[Start_date] < t.[Start_date]
           OR i.[End_date] > t.[End_date]
    )
    BEGIN
        THROW 50006, 'Exam dates must fall inside the selected term.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_Exam_Subjects_Validate]
ON [dbo].[Exam_Subjects]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Exams] e ON e.[Exam_id] = i.[Exam_id]
        JOIN [dbo].[Terms] t ON t.[Term_id] = e.[Term_id]
        LEFT JOIN [dbo].[Class_Subjects] cs
          ON cs.[Class_id] = e.[Class_id]
         AND cs.[Subject_id] = i.[Subject_id]
         AND cs.[Academic_year_id] = t.[Academic_year_id]
        WHERE cs.[Class_subject_id] IS NULL
           OR i.[Exam_date] < e.[Start_date]
           OR i.[Exam_date] > e.[End_date]
           OR i.[Exam_date] < t.[Start_date]
           OR i.[Exam_date] > t.[End_date]
    )
    BEGIN
        THROW 50007, 'Exam subject must belong to the class/year and its date must fall inside the exam and term.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_Exams_Results_Validate]
ON [dbo].[Exams_Results]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Exam_Subjects] es ON es.[Exam_subject_id] = i.[Exam_subject_id]
        JOIN [dbo].[Exams] e ON e.[Exam_id] = es.[Exam_id]
        JOIN [dbo].[Terms] t ON t.[Term_id] = e.[Term_id]
        JOIN [dbo].[Enrollments] en ON en.[Enrollment_id] = i.[Enrollment_id]
        WHERE en.[Class_id] <> e.[Class_id]
           OR en.[Academic_year_id] <> t.[Academic_year_id]
           OR en.[Enrollment_date] > es.[Exam_date]
           OR (en.[End_date] IS NOT NULL AND en.[End_date] < es.[Exam_date])
           OR (i.[Score] IS NOT NULL AND i.[Score] > es.[Max_score])
    )
    BEGIN
        THROW 50008, 'Exam result does not match the student enrollment/class/year or exceeds the maximum score.', 1;
    END
END;
GO


CREATE OR ALTER TRIGGER [dbo].[TR_Fees_Validate]
ON [dbo].[Fees]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[Enrollments] e ON e.[Enrollment_id] = i.[Enrollment_id]
        JOIN [dbo].[Academic_years] y ON y.[Academic_year_id] = e.[Academic_year_id]
        WHERE i.[Due_date] < y.[Start_date]
           OR i.[Due_date] > y.[End_Date]
           OR i.[Due_date] < e.[Enrollment_date]
           OR (e.[End_date] IS NOT NULL AND i.[Due_date] > e.[End_date])
    )
    BEGIN
        THROW 50011, 'Fee due date must fall inside the enrollment and academic year.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE (
            SELECT ISNULL(SUM(p.[Amount]), 0)
            FROM [dbo].[Fees_payments] p
            WHERE p.[fee_id] = i.[Fee_id]
        ) > (i.[Amount] - i.[Discount_amount])
    )
    BEGIN
        THROW 50012, 'Existing payments exceed the net fee amount.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.[Status] <> N'Waived'
          AND i.[Status] <> CASE
                WHEN (
                    SELECT ISNULL(SUM(p.[Amount]), 0)
                    FROM [dbo].[Fees_payments] p
                    WHERE p.[fee_id] = i.[Fee_id]
                ) >= (i.[Amount] - i.[Discount_amount]) THEN N'Paid'
                WHEN (
                    SELECT ISNULL(SUM(p.[Amount]), 0)
                    FROM [dbo].[Fees_payments] p
                    WHERE p.[fee_id] = i.[Fee_id]
                ) > 0 THEN N'Partial'
                ELSE N'Unpaid'
              END
    )
    BEGIN
        THROW 50013, 'Fee status must match its payment total.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER [dbo].[TR_Fees_payments_Recalculate]
ON [dbo].[Fees_payments]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FeeIds TABLE ([Fee_id] INT PRIMARY KEY);

    INSERT INTO @FeeIds([Fee_id])
    SELECT [fee_id] FROM inserted
    UNION
    SELECT [fee_id] FROM deleted;

    IF EXISTS (
        SELECT 1
        FROM @FeeIds x
        JOIN [dbo].[Fees] f ON f.[Fee_id] = x.[Fee_id]
        WHERE (
            SELECT ISNULL(SUM(p.[Amount]), 0)
            FROM [dbo].[Fees_payments] p
            WHERE p.[fee_id] = f.[Fee_id]
        ) > (f.[Amount] - f.[Discount_amount])
    )
    BEGIN
        THROW 50009, 'Payment would exceed the net fee amount.', 1;
    END;

    UPDATE f
       SET [Status] =
           CASE
               WHEN f.[Status] = N'Waived' THEN N'Waived'
               WHEN (
                   SELECT ISNULL(SUM(p.[Amount]), 0)
                   FROM [dbo].[Fees_payments] p
                   WHERE p.[fee_id] = f.[Fee_id]
               ) >= (f.[Amount] - f.[Discount_amount]) THEN N'Paid'
               WHEN (
                   SELECT ISNULL(SUM(p.[Amount]), 0)
                   FROM [dbo].[Fees_payments] p
                   WHERE p.[fee_id] = f.[Fee_id]
               ) > 0 THEN N'Partial'
               ELSE N'Unpaid'
           END
    FROM [dbo].[Fees] f
    JOIN @FeeIds x ON x.[Fee_id] = f.[Fee_id];
END;
GO

/* =========================================================
   USEFUL REPORTING VIEW
   ========================================================= */

CREATE OR ALTER VIEW [dbo].[vw_Fee_Balances]
AS
SELECT
    f.[Fee_id],
    f.[Enrollment_id],
    f.[FeeType],
    f.[Fee_Month],
    f.[Amount],
    f.[Discount_amount],
    CAST(f.[Amount] - f.[Discount_amount] AS DECIMAL(12,2)) AS [Net_amount],
    CAST(ISNULL(SUM(p.[Amount]), 0) AS DECIMAL(12,2)) AS [Paid_amount],
    CAST((f.[Amount] - f.[Discount_amount]) - ISNULL(SUM(p.[Amount]), 0) AS DECIMAL(12,2)) AS [Outstanding_amount],
    f.[Due_date],
    f.[Currency],
    f.[Status]
FROM [dbo].[Fees] f
LEFT JOIN [dbo].[Fees_payments] p ON p.[fee_id] = f.[Fee_id]
GROUP BY
    f.[Fee_id], f.[Enrollment_id], f.[FeeType], f.[Fee_Month], f.[Amount],
    f.[Discount_amount], f.[Due_date], f.[Currency], f.[Status];
GO

PRINT N'Corrected school_management schema created successfully.';
GO
