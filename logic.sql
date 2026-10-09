USE [aic_data];
GO

/*
    UltimateParentSP
    Populates tblRefresh.[Ultimate Parent] in a client database using luUParent as lookup.
    New suppliers in the Top 100 by spend are sent to GenAI (GenAIConnection) and appended to luUParent.

    Usage:  EXEC [aic_data].[dbo].[UltimateParentSP] @client_db_name = 'client_db';
*/
CREATE OR ALTER PROCEDURE [dbo].[UltimateParentSP]
    @client_db_name NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- Any error rolls back the open transaction

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @new_count INT = 0;  -- New suppliers sent to AI
    DECLARE @found     INT = 0;  -- AI returned a parent
    DECLARE @unknown   INT = 0;  -- AI returned UNKNOWN (saved with NULL parent)
    DECLARE @retry     INT = 0;  -- Error / empty answer, retried on next run
    DECLARE @updated   INT = 0;  -- Rows updated in tblRefresh
    DECLARE @pending   INT = 0;  -- Suppliers in luUParent with NULL parent (manual review)

    -- Same name mapping GenAIConnection applies internally
    DECLARE @real_db_name SYSNAME =
        CASE WHEN @client_db_name = N'uth_tmc' THEN N'uth-tmc' ELSE @client_db_name END;
    DECLARE @db NVARCHAR(260) = QUOTENAME(@real_db_name);

    IF DB_ID(@real_db_name) IS NULL
        THROW 50001, N'UltimateParentSP: client database not found.', 1;

    RAISERROR(N'UltimateParentSP started for database %s', 0, 1, @real_db_name) WITH NOWAIT;


    -- Step 0: Create luUParent in the client database if it does not exist yet
    IF OBJECT_ID(@db + N'.dbo.luUParent', N'U') IS NULL
    BEGIN
        SET @sql = N'
        CREATE TABLE {db}.dbo.luUParent (
            [Normalized Supplier] NVARCHAR(255) NOT NULL PRIMARY KEY,
            [Ultimate Parent]     NVARCHAR(255) NULL,
            [Source]              NVARCHAR(20)  NOT NULL DEFAULT (N''Manual'')
        );';
        SET @sql = REPLACE(@sql, N'{db}', @db);
        EXEC sp_executesql @sql;

        RAISERROR(N'Step 0: luUParent created', 0, 1) WITH NOWAIT;
    END;


    -- Step 1 + 2: Top 100 suppliers by spend that are not yet in luUParent, into staging table
    SET @sql = N'
    DROP TABLE IF EXISTS {db}.dbo.gptUParent;

    SELECT t.[Normalized Supplier] AS [Supplier],
           CAST(NULL AS NVARCHAR(MAX)) AS [Completion]
    INTO {db}.dbo.gptUParent
    FROM (
        SELECT TOP (100) [Normalized Supplier]
        FROM {db}.dbo.tblRefresh
        WHERE NULLIF(LTRIM(RTRIM([Normalized Supplier])), N'''') IS NOT NULL
        GROUP BY [Normalized Supplier]
        ORDER BY SUM([Spend]) DESC
    ) t
    WHERE NOT EXISTS (
        SELECT 1 FROM {db}.dbo.luUParent u
        WHERE u.[Normalized Supplier] = t.[Normalized Supplier]
    );

    SET @new_count = @@ROWCOUNT;';
    SET @sql = REPLACE(@sql, N'{db}', @db);
    EXEC sp_executesql @sql, N'@new_count INT OUTPUT', @new_count = @new_count OUTPUT;

    RAISERROR(N'Step 1-2: %d new suppliers in Top 100 not found in luUParent', 0, 1, @new_count) WITH NOWAIT;


    -- Step 2.1: GenAI suggests the Ultimate Parent (only if there are new suppliers)
    -- Must stay outside any transaction: the Python process uses its own connection
    IF @new_count > 0
    BEGIN
        RAISERROR(N'Step 2.1: sending %d suppliers to GenAI...', 0, 1, @new_count) WITH NOWAIT;

        EXEC [aic_data].[dbo].[GenAIConnection]
            @mode = '2',
            @client_db_name = @client_db_name,
            @client_table_name = 'gptUParent',
            @field1 = 'Supplier',
            @prompt1 = 'Return only the name of the ultimate parent company that owns the following supplier. If the supplier is independent return the supplier name itself. If unknown return UNKNOWN. No extra text. Supplier:',
            @to_merge = 1;
    END
    ELSE
        RAISERROR(N'Step 2.1: no new suppliers, GenAI call skipped', 0, 1) WITH NOWAIT;


    -- Step 2.1 (cont.) + Step 3: Append AI results to luUParent and refresh tblRefresh
    SET @sql = N'
    BEGIN TRAN;

    /* Errors and empty answers are skipped so they are retried on the next run */
    INSERT INTO {db}.dbo.luUParent ([Normalized Supplier], [Ultimate Parent], [Source])
    SELECT s.[Supplier],
           CASE WHEN c.[Parent] IN (N''UNKNOWN'', N''UNKNOWN.'') THEN NULL ELSE c.[Parent] END,
           N''AI''
    FROM {db}.dbo.gptUParent s
    CROSS APPLY (
        SELECT LTRIM(RTRIM(
                   REPLACE(REPLACE(REPLACE(s.[Completion], N''"'', N''''), CHAR(13), N''''), CHAR(10), N'''')
               )) AS [Parent]
    ) c
    WHERE c.[Parent] <> N''''
      AND s.[Completion] NOT LIKE N''%*error*%''
      AND LEN(c.[Parent]) <= 255
      AND NOT EXISTS (  -- Safeguard in case luUParent was edited during the run
          SELECT 1 FROM {db}.dbo.luUParent u
          WHERE u.[Normalized Supplier] = s.[Supplier]
      );

    /* Run summary: outcome of the suppliers sent to AI in this run */
    SELECT @found   = COUNT(CASE WHEN u.[Ultimate Parent] IS NOT NULL THEN 1 END),
           @unknown = COUNT(CASE WHEN u.[Ultimate Parent] IS NULL THEN 1 END)
    FROM {db}.dbo.gptUParent s
    INNER JOIN {db}.dbo.luUParent u
        ON u.[Normalized Supplier] = s.[Supplier];

    /* tblRefresh is reloaded monthly with [Ultimate Parent] = NULL, so every match is updated */
    UPDATE r
    SET r.[Ultimate Parent] = u.[Ultimate Parent]
    FROM {db}.dbo.tblRefresh r
    INNER JOIN {db}.dbo.luUParent u
        ON u.[Normalized Supplier] = r.[Normalized Supplier];

    SET @updated = @@ROWCOUNT;

    COMMIT;

    SELECT @pending = COUNT(*)
    FROM {db}.dbo.luUParent
    WHERE [Ultimate Parent] IS NULL;';
    SET @sql = REPLACE(@sql, N'{db}', @db);
    EXEC sp_executesql @sql,
        N'@found INT OUTPUT, @unknown INT OUTPUT, @updated INT OUTPUT, @pending INT OUTPUT',
        @found = @found OUTPUT, @unknown = @unknown OUTPUT, @updated = @updated OUTPUT, @pending = @pending OUTPUT;

    SET @retry = @new_count - @found - @unknown;


    -- Run log
    RAISERROR(N'Step 2.1: %d parents assigned by GenAI', 0, 1, @found) WITH NOWAIT;
    RAISERROR(N'Step 2.1: %d suppliers returned UNKNOWN (saved with NULL parent)', 0, 1, @unknown) WITH NOWAIT;
    RAISERROR(N'Step 2.1: %d suppliers failed (error or empty answer), will be retried next run', 0, 1, @retry) WITH NOWAIT;
    RAISERROR(N'Step 3: %d rows updated in tblRefresh', 0, 1, @updated) WITH NOWAIT;
    RAISERROR(N'%d suppliers in luUParent pending manual review (Ultimate Parent is NULL)', 0, 1, @pending) WITH NOWAIT;
    RAISERROR(N'UltimateParentSP finished', 0, 1) WITH NOWAIT;
END;
GO
