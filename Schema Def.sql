SELECT  
    t.name  AS [Table Name],
    c.name  AS [Column Name],
    ty.name AS [Data Type],
    c.max_length AS [Length],
    CASE c.is_nullable
        WHEN 1 THEN 'Yes'
        ELSE 'No'
    END AS [Nullable]
FROM sys.tables t
JOIN sys.columns c 
    ON t.object_id = c.object_id
JOIN sys.types ty 
    ON c.user_type_id = ty.user_type_id
ORDER BY t.name, c.column_id;
