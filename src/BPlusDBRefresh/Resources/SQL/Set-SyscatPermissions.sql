-- Set-SyscatPermissions.sql
-- Parameters: @Database, @AdminSource, @AdminDestination

USE [@Database]
GO

DROP USER [syscat]
GO

CREATE USER [syscat] FOR LOGIN [syscat]
GO

EXEC sp_addrolemember N'db_datareader', N'syscat'
GO

EXEC sp_addrolemember N'db_datawriter', N'syscat'
GO

EXEC sp_addrolemember N'db_ddladmin', N'syscat'
GO

DROP USER [@AdminSource]
GO

CREATE USER [@AdminDestination] FOR LOGIN [@AdminDestination]
GO

EXEC sp_addrolemember N'db_owner', N'@AdminDestination'
GO

ALTER DATABASE [@Database] SET RECOVERY SIMPLE
GO
