# Security Presentation, SQL Saturday San Diego 2025

Many thanks to the folks who attended my presentation on security at SQL Saturday San Diego 2025!  
https://sqlsaturday.com/2025-06-28-sqlsaturday1113/

As promised I'm uploading the slide deck, the demo scripts, and most importantly the code for my stored proc "**sp_ShowUserPermissions**" (see "_sp_ShowUserPermissions.sql_"), which I use often to assess permissions granted at the database level.  

SQL Server permissions are impacted by explicit grant/deny's as well as role memberships, but there was no defualt way to see these all together in one place; so I created this proc as a quick way to do this.  In addition to all role memberships, it returns the permissions granted or denied to all principals (users, roles) at all levels of securables in the database: database level, schema level, object level, & column level.

The output also includes a column with the T-SQL command to create that permission, so this can be used to generate a script to duplicate the permissions on another database.  See Parameters below:  

```
/*-----------------------------------------------------------------------------------------------------------------------  
--by Thomas AJ Hull.  
--Run on any database to see all permissions - includes grants/denys *and* role memberships.  
--All parameters are optional.  If run with no parameters, shows all permissions and role memberships on the database.  
--Otherwise can filter by UserName, SchemaName, TableName, and/or ColumnName (note it respects the % wildcard for searches)  

Parameters are:  
 @UserName varchar(100) = '%' ,   --By default returns info for all users.  Otherwise can filter based on user name.  
 @SchemaName varchar(100) = '%' , --By default returns info for all schemas.  Otherwise can filter based on schema name.  
 @TableName varchar(100) = '%' ,  --By default returns info for all tables.  Otherwise can filter based on table name.  
 @ColumnName varchar(100) = '%' , --By default returns info for all columns.  Otherwise can filter based on column name.  
 @PrivilegedOnly tinyint = 0 ,    --Default value of 0 shows all permissions.  Non-zero value excludes read-only permissions.  
 @DebugMode tinyint = 0           --Non-zero value returns the code that was generated before executing it.  
-----------------------------------------------------------------------------------------------------------------------*/
```

