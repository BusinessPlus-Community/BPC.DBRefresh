-- CI-CreateTables.sql
-- Creates minimal stub tables for CI integration testing
-- This script sets up a basic "bplus" database schema with only the columns
-- referenced by existing SQL scripts in the module.

-- Workflow tables (referenced by Disable-Workflows.sql)
CREATE TABLE wf_model (
    wf_model_id VARCHAR(50) PRIMARY KEY,
    wf_status CHAR(1) NOT NULL
);

CREATE TABLE wf_schedule (
    wf_schedule_id INT IDENTITY(1,1) PRIMARY KEY,
    wf_model_id VARCHAR(50) NOT NULL,
    wf_status CHAR(1) NOT NULL
);

CREATE TABLE wf_instance (
    wf_instance_id INT IDENTITY(1,1) PRIMARY KEY,
    wf_model_id VARCHAR(50) NOT NULL,
    wf_status CHAR(1) NOT NULL
);

-- User and employee tables (referenced by Disable-Workflows.sql)
CREATE TABLE us_usno_mstr (
    us_usno_id INT IDENTITY(1,1) PRIMARY KEY,
    us_email VARCHAR(255),
    us_status CHAR(1) NOT NULL,
    us_mgr_cd VARCHAR(20)
);

CREATE TABLE hr_empmstr (
    hr_emp_id INT IDENTITY(1,1) PRIMARY KEY,
    e_mail VARCHAR(255)
);

-- Connection info tables (referenced by Backup-DatabaseConnectionInfo.ps1)
CREATE TABLE bsi_sys_blob (
    unique_key INT IDENTITY(1,1) PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    app VARCHAR(50) NOT NULL,
    [name] VARCHAR(100) NOT NULL,
    [value] VARBINARY(MAX)
);

CREATE TABLE ifas_data (
    unique_key INT IDENTITY(1,1) PRIMARY KEY,
    [name] VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    app VARCHAR(50) NOT NULL,
    [value] VARBINARY(MAX)
);

-- Seed data for verification
INSERT INTO wf_model (wf_model_id, wf_status) VALUES
    ('JOB', 'A'),
    ('DO_ARCHIVE', 'A'),
    ('TEST_MODEL_1', 'A'),
    ('TEST_MODEL_2', 'Z');

INSERT INTO wf_schedule (wf_model_id, wf_status) VALUES
    ('JOB', 'A'),
    ('DO_ARCHIVE', 'A'),
    ('TEST_MODEL_1', 'A'),
    ('TEST_MODEL_2', 'Z');

INSERT INTO wf_instance (wf_model_id, wf_status) VALUES
    ('JOB', 'I'),
    ('DO_ARCHIVE', 'I'),
    ('TEST_MODEL_1', 'I'),
    ('TEST_MODEL_2', 'H');

INSERT INTO us_usno_mstr (us_email, us_status, us_mgr_cd) VALUES
    ('user1@example.com', 'A', 'DBA'),
    ('user2@example.com', 'A', 'MGR'),
    ('user3@example.com', 'I', 'USR'),
    ('user4@example.com', 'A', 'QA');

INSERT INTO hr_empmstr (e_mail) VALUES
    ('employee1@example.com'),
    ('employee2@example.com'),
    ('employee3@example.com');

INSERT INTO bsi_sys_blob (category, app, [name], [value]) VALUES
    ('CONNECT', 'CONNECT', 'bplus', 0x0123456789ABCDEF);

INSERT INTO ifas_data ([name], category, app, [value]) VALUES
    ('Hostnames', 'Settings', 'Admin', 0x0123456789ABCDEF);
