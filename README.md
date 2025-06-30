# Security Presentation, SQL Saturday San Diego 2025

Many thanks to the folks who attended my presentation on security at SQL Saturday San Diego 2025!  
https://sqlsaturday.com/2025-06-28-sqlsaturday1113/

As promised I'm uploading the slide deck, the demo scripts, and most importantly the code for my stored proc "**sp_ShowUserPermissions**" (see ["_sp_ShowUserPermissions.sql_"](https://github.com/AJHull/SQLSat2025_Security/blob/main/sp_ShowUserPermissions.sql)), which I use often to assess permissions granted at the database level.  

SQL Server permissions are impacted by explicit grant/deny's as well as role memberships, but there was no convenient built-in way to visualize both of these together in one place; so I created this proc as a quick way to do this.  In addition to role memberships, it returns the permissions granted or denied to all principals (users, roles) at all levels of securables in the database: database level, schema level, object level, & column level.

In the output, please note the "**Command**" column, which shows the T-SQL command for that permission (or role membership), which can be used to duplicate or restore the permissions on another database.  

By default it will return all permissions in the database, but it can be filtered based on several parameters, see below:  

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

If there are questions/comments/compliments, please ping me here or on LinkedIn.  Thanks!  

 - AJ Hull  
   <a href="https://www.linkedin.com/in/AJHull"><img src="https://github.com/user-attachments/assets/4c58e586-23cc-48f5-8ce4-611fe04986eb" alt="LinkedIn" width="23" height="23" align="bottom"></a>  [linkedin.com/in/**AJHull**](https://www.linkedin.com/in/AJHull)  ·  [_Follow_](www.linkedin.com/comm/mynetwork/discovery-see-all?usecase=PEOPLE_FOLLOWS&followMember=ajhull)  
   <a href="https://x.com/sdsql"><img src="https://github.com/user-attachments/assets/6cac2caf-aff8-48d4-ae79-4e384d63ef2d" alt="X" width="20" height="15" align="bottom"></a>  [**@sdsql**](https://x.com/sdsql)  ·  [_Follow_](https://x.com/intent/user?screen_name=sdsql)
   
