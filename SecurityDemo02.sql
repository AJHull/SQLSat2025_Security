USE master;
go
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'TestDB02') 
  DROP DATABASE TestDB02 ;
go
CREATE DATABASE TestDB02 ;
go

USE master;
go
DROP LOGIN TestSQLLogin;
go
CREATE LOGIN TestSQLLogin
 WITH Password = 'SuperLongComplexPassword123)(*&',
 DEFAULT_DATABASE = [TestDB02] ;
go



USE TestDB02;
go


IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'CheckPermissions')
   DROP PROC CheckPermissions ;
go
CREATE PROC CheckPermissions
AS
-- Query sys.database_permissions to see applicable permissions
SELECT 'class_desc' = CONVERT(varchar(20), dp.class_desc) , 
 CAST(s.name AS varchar(15)) AS 'Schema' , 
 'Object' = CONVERT(varchar(20), o.name) , 
 'permission_name' = CONVERT(varchar(10), dp.permission_name) ,
 'state_desc' = CONVERT(varchar(10), dp.state_desc) , 
 'UserName' = CONVERT(varchar(20), prin.[name])
FROM sys.database_permissions dp
  JOIN sys.database_principals prin
    ON dp.grantee_principal_id = prin.principal_id
  JOIN sys.objects o
    ON dp.major_id = o.object_id
  JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE LEFT(o.name, 9) = 'TestTable'
  AND dp.class_desc = 'OBJECT_OR_COLUMN'
UNION ALL
SELECT 'class_desc' = CONVERT(varchar(20), dp.class_desc) , 
  'Schema' = CONVERT(varchar(15), s.name) , 
  'Object' = CONVERT(varchar(20), '-----') ,  
  'permission_name' = CONVERT(varchar(10), dp.permission_name) , 
  'state_desc' = CONVERT(varchar(10), dp.state_desc) , 
  'UserName' = CONVERT(varchar(20), prin.[name])
FROM sys.database_permissions dp
  JOIN sys.database_principals prin
    ON dp.grantee_principal_id = prin.principal_id
  JOIN sys.schemas s
    ON dp.major_id = s.schema_id
WHERE dp.class_desc = 'SCHEMA';
go



--Create a schema & a couple of tables, insert record into tables.:
CREATE SCHEMA Test;
go 
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TestTable')
   DROP TABLE Test.TestTable;
go
CREATE TABLE Test.TestTable (tt_id int NOT NULL PRIMARY KEY CLUSTERED, tt_desc varchar(50) NULL );
go 
--TRUNCATE TABLE Test.TestTable ;
INSERT Test.TestTable (tt_id, tt_desc) VALUES (1, 'Record 1');
go


IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TestTable2')
   DROP TABLE Test.TestTable2;
go
CREATE TABLE Test.TestTable2 (tt_id int NOT NULL PRIMARY KEY CLUSTERED, tt_desc varchar(50) NULL );
go
--TRUNCATE TABLE Test.TestTable2 ;
INSERT Test.TestTable2 (tt_id, tt_desc) VALUES (2, 'Record 2');
go



CREATE USER TestSQLLogin FROM LOGIN TestSQLLogin with DEFAULT_SCHEMA = [dbo];
go

EXEC TestDB02..sp_ShowUserPermissions ;
go


ALTER ROLE db_datareader ADD MEMBER TestSQLLogin;
go
ALTER ROLE db_datawriter ADD MEMBER TestSQLLogin;
go

EXEC CheckPermissions;
go
--Note this doesn't show group memberships

EXEC TestDB02..sp_ShowUserPermissions ;
go
--This one does.


--TABLE level deny:
DENY SELECT ON Test.TestTable TO TestSQLLogin;
go

--COLUMN level deny:
DENY SELECT ON Test.TestTable2 (tt_desc) TO TestSQLLogin;
go

EXEC TestDB02..sp_ShowUserPermissions ;
go

EXECUTE AS USER = 'TestSQLLogin';
go 
SELECT * FROM Test.TestTable;

SELECT * FROM Test.TestTable2;

SELECT tt_id FROM Test.TestTable2;
go
REVERT;
go



--***