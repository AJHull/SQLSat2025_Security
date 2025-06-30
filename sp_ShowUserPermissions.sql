USE master;
go

CREATE OR ALTER PROC [dbo].[sp_ShowUserPermissions]
--DECLARE
 @UserName varchar(100) = '%' ,   --By default returns info for all users.  Otherwise can filter based on user name.
 @SchemaName varchar(100) = '%' , --By default returns info for all schemas.  Otherwise can filter based on schema name.
 @TableName varchar(100) = '%' ,  --By default returns info for all tables.  Otherwise can filter based on table name.
 @ColumnName varchar(100) = '%' , --By default returns info for all columns.  Otherwise can filter based on column name.
 @PrivilegedOnly tinyint = 0 ,    --Default value of 0 shows all permissions.  Non-zero value excludes read-only permissions.
 @DebugMode tinyint = 0           --Non-zero value returns the code that was generated before executing it.
AS

/*-----------------------------------------------------------------------------------------------------------------------*/
--by Thomas AJ Hull.
--Run on any database to see all permissions - includes grants/denys *and* role memberships.  
--All parameters are optional.  If run with no parameters, shows all permissions and role memberships on the database.
--Otherwise can filter by UserName, SchemaName, TableName, and/or ColumnName (note it respects the % wildcard for searches)
/*-----------------------------------------------------------------------------------------------------------------------*/

IF (@DebugMode > 0)
begin	
   PRINT '-- @UserName: ' + @UserName ;
   PRINT '-- @SchemaName: ' + @SchemaName ;
   PRINT '-- @TableName: ' + @TableName ;
   PRINT '-- @ColumnName: ' + @ColumnName ;
   PRINT '-- @PrivilegedOnly: ' + CONVERT(varchar(10), @PrivilegedOnly) ;
   PRINT '' ;
end

DECLARE @SQLCommand varchar(8000) ;
SET @SQLCommand = '
DECLARE @UserName varchar(100) = ''' + @UserName + '''
 , @SchemaName varchar(100) = ''' + @SchemaName + '''
 , @TableName varchar(100) = ''' + @TableName + '''
 , @ColumnName varchar(100) = ''' + @ColumnName + '''
 , @PrivilegedOnly tinyint = ''' + CONVERT(varchar(10), @PrivilegedOnly) + ''';

SELECT  
  state_desc  = CONVERT(varchar(10), a.state_desc) , 
  permission_name = CONVERT(varchar(20), a.permission_name) , 
  class_desc  = CONVERT(varchar(17), a.class_desc) , 
  SchemaName  = CONVERT(varchar(25), a.SchemaName) , 
  ObjectName  = CONVERT(varchar(60), a.ObjectName) , 
  ColumnName  = CONVERT(varchar(50), a.ColumnName) , 
  RoleName    = CONVERT(varchar(40), a.RoleName) ,
  DBPrincipalName = CONVERT(varchar(40), a.DBPrincipalName) , 
  DBPrincipalType = CONVERT(varchar(24), a.DBPrincipalType), 
  a.[Command] ,
  ServerPrincipalName = CONVERT(varchar(40), l.name) ,
  ServerPrincipalType = CONVERT(varchar(24), l.type_desc) ,
  SQLInstanceName     = CONVERT(varchar(40), @@servername) , 
  DatabaseName        = CONVERT(varchar(100), db_name())

FROM (

SELECT 
  dp.state_desc, dp.permission_name,
  class_desc = ''Object'',  --dp.class_desc
  SchemaName = s.name , 
  ObjectName = o.name , 
  ColumnName = ''---'' , 
  RoleName   =  ''---'' ,
  DBPrincipalName = prin.[name] ,
  DBPrincipalType = prin.type_desc ,
  Command = CONVERT(varchar(255), dp.state_desc 
               + '' '' + dp.permission_name + '' ON '' -- + dp.class_desc + ''::''
               + ''['' + s.name + ''].['' + o.name + ''] TO ['' + prin.[name]  COLLATE SQL_Latin1_General_CP1_CI_AS + ''] ;'')
  , prin.SID
FROM sys.database_permissions dp
  JOIN sys.database_principals prin
    ON dp.grantee_principal_id = prin.principal_id
  JOIN sys.objects o   ON dp.major_id = o.object_id
  JOIN sys.schemas s   ON o.schema_id = s.schema_id
WHERE dp.class_desc = ''OBJECT_OR_COLUMN'' AND ISNULL(dp.minor_id,0) = 0

UNION ALL

SELECT 
  dp.state_desc, dp.permission_name,
  class_desc = ''Column'' ,  --dp.class_desc
  SchemaName = s.name , 
  ObjectName = o.name , 
  ColumnName = c.name , 
  RoleName   =  CONVERT(varchar(40), ''---'') ,
  DBPrincipalName = prin.[name] ,
  DBPrincipalType = prin.type_desc ,
  Command = CONVERT(varchar(255), dp.state_desc 
               + '' '' + dp.permission_name + ''(['' + c.name + ''])''
			   + '' ON ''
               + ''['' + s.name + ''].['' + o.name + ''] TO ['' + prin.[name]  COLLATE SQL_Latin1_General_CP1_CI_AS + ''] ;'')
  , prin.SID
FROM sys.database_permissions dp
  JOIN sys.database_principals prin
    ON dp.grantee_principal_id = prin.principal_id
  JOIN sys.objects o  ON dp.major_id = o.object_id
  JOIN sys.columns c  ON dp.major_id = c.object_id AND dp.minor_id = c.column_id
  JOIN sys.schemas s  ON o.schema_id = s.schema_id
WHERE dp.class_desc = ''OBJECT_OR_COLUMN'' AND dp.minor_id <> 0

UNION ALL

SELECT 
  dp.state_desc, dp.permission_name,
  dp.class_desc , --SCHEMA
  SchemaName = s.name , 
  ObjectName = ''---'' ,  
  ColumnName = ''---'' ,  
  RoleName   = ''---'' , 
  DBPrincipalName = prin.[name] ,
  DBPrincipalType = prin.type_desc ,
  Command = CONVERT(varchar(255), dp.state_desc 
               + '' '' + dp.permission_name + '' ON SCHEMA::'' --+ dp.class_desc + ''::'' 
               + ''['' + s.name + ''] TO ['' + prin.[name]  COLLATE SQL_Latin1_General_CP1_CI_AS + ''] ;'')
  , prin.SID
FROM sys.database_permissions dp
  JOIN sys.database_principals prin
    ON dp.grantee_principal_id = prin.principal_id
  JOIN sys.schemas s  ON dp.major_id = s.schema_id
WHERE dp.class_desc = ''SCHEMA''

UNION ALL

SELECT 
  dp.state_desc, dp.permission_name,
  class_desc = dp.class_desc , 
  SchemaName = ISNULL(s.name, ''---'') , 
  ObjectName = ISNULL(o.name, ''---'') ,  
  ColumnName = ISNULL(c.name, ''---'') ,   
  RoleName   = ''---'' , 
  DBPrincipalName = prin.[name] ,
  DBPrincipalType = prin.type_desc ,
  Command = CONVERT(varchar(255), dp.state_desc 
              + '' '' + dp.permission_name + '' TO ['' + prin.[name]  COLLATE SQL_Latin1_General_CP1_CI_AS + ''] ;'')
 , prin.SID
FROM sys.database_permissions dp
  JOIN sys.database_principals prin
    ON dp.grantee_principal_id = prin.principal_id
  LEFT JOIN sys.objects o  ON dp.major_id = o.object_id
  LEFT JOIN sys.columns c  ON dp.major_id = c.object_id AND dp.minor_id = c.column_id
  LEFT JOIN sys.schemas s  ON o.schema_id = s.schema_id
WHERE dp.class_desc NOT IN (''SCHEMA'', ''OBJECT_OR_COLUMN'')

UNION ALL

SELECT 
  state_desc = ''ROLE'' ,  --dp.state_desc 
  permission_name = ''(ROLE MEMBERSHIP)'' ,  --dp.permission_name
  class_desc = ''ROLE'', 
  SchemaName = ''---'' ,
  ObjectName = ''---'' ,  
  ColumnName = ''---'' ,  
  RoleName   =  rp.name ,
  DBPrincipalName = prin.[name] ,
  DBPrincipalType = prin.type_desc ,
  Command = CONVERT(varchar(255), CASE WHEN LEFT(@@Version, 25) >= ''Microsoft SQL Server 2012'' 
                    THEN ''ALTER ROLE ['' + rp.name + ''] ADD MEMBER ['' + prin.name + ''] ;''
					ELSE ''EXEC sp_addrolemember @rolename = '''''' + rp.name + '''''',  @membername = '''''' + prin.name + '''''' ;''
					END  )
  , prin.SID
FROM sys.database_role_members drm
  JOIN sys.database_principals rp on (drm.role_principal_id = rp.principal_id)
  JOIN sys.database_principals prin on (drm.member_principal_id = prin.principal_id)

) a
  LEFT JOIN sys.server_principals l 
     ON a.SID = l.SID
	 AND l.is_disabled = 0 and l.name <> ''sa''
WHERE a.DBPrincipalName NOT LIKE ''##%''
 AND a.permission_name <> ''CONNECT''
 AND ( NOT (a.RoleName = ''db_owner'' AND a.DBPrincipalName = ''dbo'' ) )
 AND a.ObjectName <> ''dtproperties''
 AND NOT (a.permission_name = ''EXECUTE'' AND a.ObjectName IN   --LIKE ''dt_%''
           (
			''dt_addtosourcecontrol'', ''dt_addtosourcecontrol_u'', ''dt_adduserobject'', ''dt_adduserobject_vcs'', ''dt_checkinobject'', ''dt_checkinobject_u'',
			''dt_checkoutobject'', ''dt_checkoutobject_u'', ''dt_displayoaerror'', ''dt_displayoaerror_u'', ''dt_droppropertiesbyid'', ''dt_dropuserobjectbyid'',
			''dt_generateansiname'', ''dt_getobjwithprop'', ''dt_getobjwithprop_u'', ''dt_getpropertiesbyid'', ''dt_getpropertiesbyid_u'', ''dt_getpropertiesbyid_vcs'',
			''dt_getpropertiesbyid_vcs_u'', ''dt_isundersourcecontrol'', ''dt_isundersourcecontrol_u'', ''dt_removefromsourcecontrol'', ''dt_setpropertybyid'', ''dt_setpropertybyid_u'', 
			''dt_validateloginparams'', ''dt_validateloginparams_u'', ''dt_vcsenabled'', ''dt_verstamp006'', ''dt_verstamp007'', ''dt_whocheckedout'', ''dt_whocheckedout_u'',
			''fn_diagramobjects'', ''sp_alterdiagram'', ''sp_creatediagram'', ''sp_dropdiagram'', ''sp_helpdiagramdefinition'', ''sp_helpdiagrams'', ''sp_renamediagram''
            )
         ) 
 AND ( @PrivilegedOnly = 0 
       OR (state_desc <> ''DENY'' AND RoleName <> ''db_datareader'' AND RoleName NOT LIKE ''%read%''
	        AND permission_name NOT IN (''SELECT'', ''CONNECT'', ''REFERENCES'')  AND permission_name NOT LIKE ''VIEW%''
          )
     )

  AND (@UserName IS NULL OR @UserName = ''%'' OR a.DBPrincipalName LIKE @UserName) 
  AND (@TableName IS NULL OR @TableName = ''%'' OR a.ObjectName LIKE @TableName) 
  AND (@SchemaName IS NULL OR @SchemaName = ''%'' OR a.SchemaName LIKE @SchemaName) 
  AND (@ColumnName IS NULL OR @ColumnName = ''%'' OR a.ColumnName LIKE @ColumnName) 

ORDER BY a.DBPrincipalName ASC, CASE a.class_desc WHEN ''ROLE'' THEN 1 WHEN ''DATABASE'' THEN 2 WHEN ''SCHEMA'' THEN 3 ELSE 4 END ASC, 
 a.RoleName ASC , a.SchemaName ASC , a.ObjectName ASC, a.permission_name ASC;
 
 
' ;

IF (@DebugMode > 0)  PRINT @SQLCommand ;

EXEC (@SQLCommand) ;

