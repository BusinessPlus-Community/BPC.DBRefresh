-- Set-IfasPermissions.sql
-- Parameters: @Database, @IusrSource, @IusrDestination, @AdminSource, @AdminDestination, @DboSource, @DboDestination
-- Purpose: Configure database permissions after restore for IFAS/BusinessPlus database

USE [@Database]
GO

DROP USER [@IusrSource]
GO

CREATE USER [@IusrDestination] FOR LOGIN [@IusrDestination]
GO

EXEC sp_addrolemember N'db_owner', N'@IusrDestination'
GO

DROP USER [@AdminSource]
GO

CREATE USER [@AdminDestination] FOR LOGIN [@AdminDestination]
GO

EXEC sp_addrolemember N'db_owner', N'@AdminDestination'
GO

DROP USER [@DboSource]
GO

CREATE USER [@DboDestination] FOR LOGIN [@DboDestination]
GO

EXEC sp_addrolemember N'db_owner', N'@DboDestination'
GO

EXEC sp_addrolemember N'db_datareader', N'@DboDestination'
GO

EXEC sp_addrolemember N'db_datawriter', N'@DboDestination'
GO

EXEC sp_addrolemember N'db_ddladmin', N'@DboDestination'
GO

ALTER DATABASE [@Database] SET RECOVERY SIMPLE
GO

DBCC OPENTRAN([@Database])
GO

CHECKPOINT
GO

USE [@Database]
GO

DBCC SHRINKFILE (N'bplus_log', 8192)
GO
