-- Set-AspnetPermissions.sql
-- Parameters: @Database, @AdminSource, @AdminDestination, @DboSource, @DboDestination

USE [@Database]
GO

DROP USER [@AdminSource]
GO

CREATE USER [@AdminDestination] FOR LOGIN [@AdminDestination] WITH DEFAULT_SCHEMA=[dbo]
GO

DROP USER [@DboSource]
GO

CREATE USER [@DboDestination] FOR LOGIN [@DboDestination]
GO

EXEC sp_addrolemember N'db_owner', N'@DboDestination'
GO

ALTER DATABASE [@Database] SET RECOVERY SIMPLE
GO
