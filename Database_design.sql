-- Welcome to the Job Tracking and Analytics Platform Data Model

-- Companies and Jobs

-- Companies table to store details about employers
CREATE TABLE Companies (
    CompanyID INT PRIMARY KEY,
    CompanyName VARCHAR(100) NOT NULL,
    Industry VARCHAR(50),
    HeadquartersLocation VARCHAR(100),
    CompanyDescription TEXT,
    CompanyRate INT
);

-- Jobs table to store job titles and associated details
CREATE TABLE Jobs (
    JobID INT PRIMARY KEY,
    CompanyID INT,
    PositionTitle VARCHAR(100) NOT NULL,
    PositionType VARCHAR(30) NOT NULL,
    AverageSalary INT,
    PostDate DATE,
    ApplicationDeadline DATE,
    ScheduleType VARCHAR(20),
    WorkDays VARCHAR(50),
    WorkHours VARCHAR(50),
    FOREIGN KEY (CompanyID) REFERENCES Companies(CompanyID)
);

-- JobPosts table to store information about job posts
CREATE TABLE JobPosts (
    JobPostID INT PRIMARY KEY,
    JobID INT,
    CompanyID INT,
    Location VARCHAR(100),
    Remote BOOLEAN,
    OnSite BOOLEAN,
    Hybrid BOOLEAN,
    TheRole TEXT,
    JobRequirements TEXT,
    Qualifications TEXT,
    ToApply TEXT,
    Requirements TEXT, -- Additional details about job requirements
    FOREIGN KEY (JobID) REFERENCES Jobs(JobID),
    FOREIGN KEY (CompanyID) REFERENCES Companies(CompanyID)
);

-- Skills in Jobs table
CREATE TABLE JobSkills (
    JobID INT,
    SkillID INT,
    FOREIGN KEY (JobID) REFERENCES Jobs(JobID),
    FOREIGN KEY (SkillID) REFERENCES Skills(SkillID)
);

-- Tools and Software table to store required tools and software
CREATE TABLE ToolsAndSoftware (
    ToolID INT PRIMARY KEY,
    ToolName VARCHAR(50) NOT NULL
);

-- JobRequirements table to associate jobs with required skills and tools
CREATE TABLE JobRequirements (
    RequirementID INT PRIMARY KEY,
    JobID INT,
    SkillID INT,
    ToolID INT,
    FOREIGN KEY (JobID) REFERENCES Jobs(JobID),
    FOREIGN KEY (SkillID) REFERENCES Skills(SkillID),
    FOREIGN KEY (ToolID) REFERENCES ToolsAndSoftware(ToolID)
);

-- Populate Skills and Tools tables with initial data
INSERT INTO Skills (SkillName) VALUES ('Programming'), ('Data Analysis'), ('Machine Learning'), ('Communication');
INSERT INTO ToolsAndSoftware (ToolName) VALUES ('Python'), ('SQL'), ('Tableau');

-- Extend JobRequirements table to include additional requirements like education level, certifications, etc.
ALTER TABLE JobRequirements ADD COLUMN EducationLevel VARCHAR(100), ADD COLUMN Certifications VARCHAR(100);

-- Users table to store information about job seekers
CREATE TABLE Users (
    UserID INT PRIMARY KEY,
    UserName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    PreferredIndustry VARCHAR(50),
    PreferredWorkSchedule VARCHAR(20),
    PreferredLocation VARCHAR(100)
);

-- JobApplications table to track job applications
CREATE TABLE JobApplications (
    ApplicationID INT PRIMARY KEY,
    JobID INT,
    UserID INT,
    ApplicationDate DATE,
    ApplicationStatus VARCHAR(20),
    FOREIGN KEY (JobID) REFERENCES Jobs(JobID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- JobPosts table to store information about job posts
CREATE TABLE JobPosts (
    JobPostID INT PRIMARY KEY,
    JobID INT,
    CompanyID INT,
    Location VARCHAR(100),
    Remote BOOLEAN,
    OnSite BOOLEAN,
    Hybrid BOOLEAN,
    Requirements TEXT, -- Additional details about job requirements
    FOREIGN KEY (JobID) REFERENCES Jobs(JobID),
    FOREIGN KEY (CompanyID) REFERENCES Companies(CompanyID)
);

-- Salaries table to store salary information
CREATE TABLE Salaries (
    SalaryID INT PRIMARY KEY,
    JobID INT,
    MinSalary DECIMAL(15, 2),
    MaxSalary DECIMAL(15, 2),
    FOREIGN KEY (JobID) REFERENCES Jobs(JobID)
);

-- Labor Market Analytics

-- LaborMarketStats table to store labor market statistics
CREATE TABLE LaborMarketStats (
    StatsID INT PRIMARY KEY,
    UnemploymentRate DECIMAL(5, 2),
    AvgTimeToFindJob INT, -- in days
    JobSeekers INT,
    StatDate DATE
);

-- JobSeekerJobRatio table to track the comparison between job availability and job seekers
CREATE TABLE JobSeekerJobRatio (
    RatioID INT PRIMARY KEY,
    AvailableJobs INT,
    JobSeekers INT,
    RatioDate DATE
);

-- Full-text Search Index

-- Create a full-text index for searching
CREATE INDEX JobPosts_SearchIndex ON JobPosts (PositionTitle, Description, Requirements) USING gin(to_tsvector('english', PositionTitle || ' ' || Description || ' ' || Requirements));

-- Stored Procedures

-- Stored Procedure to Update Job Application Status
CREATE OR REPLACE FUNCTION UpdateApplicationStatus(application_id INT, new_status VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE JobApplications SET ApplicationStatus = new_status WHERE ApplicationID = application_id;
END;
$$ LANGUAGE plpgsql;

-- Triggers

-- Trigger to Update Labor Market Statistics
CREATE OR REPLACE FUNCTION UpdateLaborMarketStats()
RETURNS TRIGGER AS $$
BEGIN
    -- Logic to update labor market statistics
    -- Calculate the average time to find a job and update the AvgTimeToFindJob column in LaborMarketStats
    UPDATE LaborMarketStats
    SET AvgTimeToFindJob = (SELECT AVG(ApplicationDate - JobPosts.PostDate) FROM JobApplications
                           JOIN JobPosts ON JobApplications.JobID = JobPosts.JobID
                           WHERE JobApplications.ApplicationStatus = 'Approved');
                           
    -- Update the unemployment rate, job seekers, and stat date
    UPDATE LaborMarketStats
    SET UnemploymentRate = (JobSeekers / AvailableJobs) * 100,
        JobSeekers = (SELECT COUNT(*) FROM Users WHERE PreferredIndustry IS NOT NULL),
        StatDate = CURRENT_DATE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a Trigger to Update Labor Market Statistics after every JobApplication insertion
CREATE TRIGGER AfterInsertJobApplication
AFTER INSERT ON JobApplications
FOR EACH ROW
EXECUTE FUNCTION UpdateLaborMarketStats();
