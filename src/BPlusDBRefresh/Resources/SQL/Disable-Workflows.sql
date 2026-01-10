-- Disable-Workflows.sql
-- Parameters: @Database, @DummyEmail, @ManagerCodes

USE [@Database]
GO

-- Turn Off Triggered WorkFlow Models
UPDATE wf_model
SET wf_status = 'Z'
WHERE wf_status = 'A'
AND wf_model_id NOT IN ('JOB','DO_ARCHIVE','DO_ATTACH','REBUILD_SECURITY','PY_ABSENCE','PY_CANCEL','PY_OVERTIME','PY_TIMETRACKING','TO.NET_APPROVAL')
GO

-- Turn Off Scheduled WorkFlow Models
UPDATE wf_schedule
SET wf_status = 'Z'
WHERE wf_status = 'A'
AND wf_model_id NOT IN ('JOB','REBUILD_SECURITY','DO_ARCHIVE','DO_ATTACH','PY_ABSENCE','PY_CANCEL','PY_OVERTIME','PY_TIMETRACKING','TO.NET_APPROVAL')
GO

-- Turn Off Instances with Inactive Models
UPDATE wf_instance
SET wf_status = 'H'
WHERE wf_status = 'I'
AND wf_model_id NOT IN ('JOB','REBUILD_SECURITY','DO_ARCHIVE','DO_ATTACH','PY_ABSENCE','PY_CANCEL','PY_OVERTIME','PY_TIMETRACKING','TO.NET_APPROVAL')
GO

-- Update User Email Accounts
UPDATE us_usno_mstr
SET us_email = '@DummyEmail'
GO

-- Update Employee Email Accounts
UPDATE hr_empmstr
SET e_mail = '@DummyEmail'
GO

-- Inactivate User Accounts (except specified manager codes)
UPDATE us_usno_mstr
SET us_status = 'I'
WHERE us_mgr_cd NOT IN (@ManagerCodes)
GO
