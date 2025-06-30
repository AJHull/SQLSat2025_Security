--SecurityDemo01.sql


--Cleanup database:

USE master;
go
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'TestDB01') 
  DROP DATABASE TestDB01 ;
go
CREATE DATABASE TestDB01 ;
go


SET NOCOUNT ON;
USE TestDB01 ;
go

--Cleanup objects:

if EXISTS (select 1 from sys.database_principals where name='TestUser' and Type_Desc = 'SQL_USER') DROP USER TestUser ;
go
IF EXISTS (select 1 from sys.database_principals where name='TestRole' and Type_Desc = 'DATABASE_ROLE') DROP ROLE TestRole ;
go
IF EXISTS (SELECT name FROM sys.tables WHERE name = 'TestTable' AND SCHEMA_NAME(schema_id) = 'Test') DROP TABLE Test.TestTable ;
IF EXISTS (SELECT name FROM sys.tables WHERE name = 'TestTable2' AND SCHEMA_NAME(schema_id) = 'Test') DROP TABLE Test.TestTable2 ;
go
IF EXISTS (SELECT name FROM sys.schemas WHERE name = 'Test') DROP SCHEMA Test ;
go
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'CheckPermissions') DROP PROC CheckPermissions ;
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

EXEC CheckPermissions ;
go


--Create Test User and Test Role, Make user a member of the role.
--This allows us to see how multiple permissions entries interact.
USE TestDB01;
CREATE ROLE TestRole;
go
CREATE USER TestUser WITHOUT LOGIN;
go
EXEC sp_addrolemember @rolename = 'TestRole', @membername = 'TestUser';
go
--Command(s) completed successfully.


--Create a schema & a couple of tables, insert record into tables.:
CREATE SCHEMA Test;
go 
CREATE TABLE Test.TestTable (tt_id int NOT NULL PRIMARY KEY CLUSTERED);
go 
--TRUNCATE TABLE Test.TestTable ;
INSERT Test.TestTable (tt_id) VALUES (1);
go

CREATE TABLE Test.TestTable2 (tt_id int NOT NULL PRIMARY KEY CLUSTERED);
go
--TRUNCATE TABLE Test.TestTable2 ;
INSERT Test.TestTable2 (tt_id) VALUES (2);
go

--So at this point there are no explicit permissions, right?
EXEC CheckPermissions ;
go


--Explictly GRANT the ability for the Role to select against the first table.
GRANT SELECT ON OBJECT::Test.TestTable TO TestRole;
go 

--Do we see that GRANT in the query results?
EXEC CheckPermissions ;
go




-- Run under context of TestUser:
EXECUTE AS USER = 'TestUser';
go 

--Test  to verify how permissions work for Test.TestTable.
SELECT * FROM Test.TestTable;
go 

-- Test  to verify how permissions work for Test.TestTable2.
SELECT * FROM Test.TestTable2;
go 

--REVERT to original user context:
REVERT;
go 

EXEC CheckPermissions;
go

-- Let's undo the permission using REVOKE;
REVOKE SELECT ON OBJECT::Test.TestTable FROM TestRole;
go

EXEC CheckPermissions;
go
--(0 row(s) affected)

--Can it access the table now?
EXECUTE AS USER = 'TestUser';
go 
SELECT * FROM Test.TestTable;
go 
REVERT;
go 


--Create Conflicting GRANT and DENY:
GRANT SELECT ON SCHEMA::Test TO TestRole;
go 
DENY SELECT ON OBJECT::Test.TestTable TO TestUser;
go
EXEC CheckPermissions;
go
--we can see both the SCHEMA GRANT and the TABLE DENY


--Can it access TestTable now?
EXECUTE AS USER = 'TestUser';
go 
SELECT * FROM Test.TestTable;
go 
















--DENY takes precedence


--What about TestTable2?
SELECT * FROM Test.TestTable2;
go 

















--Granted via SCHEMA level



REVERT;
go


--REVOKE the DENY:
SET NOCOUNT ON;
PRINT '';  PRINT 'BEFORE:';  PRINT '';  
EXEC CheckPermissions;
go
PRINT 'REVOKE SELECT ON OBJECT::Test.TestTable TO TestUser' ;
REVOKE SELECT ON OBJECT::Test.TestTable TO TestUser;
go
PRINT '';  PRINT 'AFTER:';  PRINT '';  
EXEC CheckPermissions;
go

--Can it access the table now?
EXECUTE AS USER = 'TestUser';
go 
SELECT * FROM Test.TestTable;
go 
REVERT;
go


--Now clear all permissions and see what happens if we do a DENY, 
--  then a GRANT at the SAME level:
REVOKE SELECT ON SCHEMA::Test TO TestRole;
go
EXEC CheckPermissions;
go
--OK we can see permissions are cleared out

--So do a DENY to TestUser on TestTable
DENY SELECT ON OBJECT::Test.TestTable TO TestUser;
go
--look at permissions:
EXEC CheckPermissions;
go

--Now do a GRANT to TestUser on TestTable  
--  (NOTE - SAME SCOPE as before, for both Grantee and Securable)
PRINT '';  PRINT 'BEFORE:';  PRINT '';  
EXEC CheckPermissions;
go
PRINT 'GRANT SELECT ON OBJECT::Test.TestTable TO TestUser' ;
GRANT SELECT ON OBJECT::Test.TestTable TO TestUser;
go
PRINT '';  PRINT 'AFTER:';  PRINT '';  
EXEC CheckPermissions;
go


--Can it access the table now?
EXECUTE AS USER = 'TestUser';
go 
SELECT * FROM Test.TestTable;
go 
REVERT;
go

--look at permissions, see what happened?:
EXEC CheckPermissions;
go

--DENY overriding GRANT rule only applies for OVERLAPPING SCOPES.

--Does NOT apply if EXACT SAME SCOPE for user and object.
--In that case, the LAST ONE APPLIED WINS.



--Cleanup:  (wrong order - see how it doesn't allow role to be dropped if it has users)
IF EXISTS (select 1 from sys.database_principals where name='TestRole' and Type_Desc = 'DATABASE_ROLE') 
  DROP ROLE TestRole ;
go

--Drop user first then the role will go
if EXISTS (select 1 from sys.database_principals where name='TestUser' and Type_Desc = 'SQL_USER') 
  DROP USER TestUser ;
go

--Note permissions records automatically disappear once user is dropped
EXEC CheckPermissions;
go





--***