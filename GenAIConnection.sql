USE [aic_data]
GO

/****** Object:  StoredProcedure [dbo].[GenAIConnection]    Script Date: 09/10/2026 01:12:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








CREATE PROCEDURE [dbo].[GenAIConnection]
	@mode NVARCHAR(50) = '2',
	@client_db_name NVARCHAR(50),
	@client_table_name NVARCHAR(50),
	@taxonomy_db_name NVARCHAR(50) = 'gpt_test',
	@taxonomy_table_name NVARCHAR(50) = 'UNSPSC',
	@is_UNSPSC NVARCHAR(50) = '1',
	@to_merge bit = 0,
	@field1 NVARCHAR(50),
	@field2 NVARCHAR(50) = NULL,
	@field3 NVARCHAR(50) = NULL,
	@field4 NVARCHAR(50) = NULL,
	@field5 NVARCHAR(50) = NULL,
	@field6 NVARCHAR(50) = NULL,
	@field7 NVARCHAR(50) = NULL,
	@field8 NVARCHAR(50) = NULL,
	@field9 NVARCHAR(50) = NULL,
	@field10 NVARCHAR(50) = NULL,
	@prompt1 NVARCHAR(max) = 'Classify the following item or service description to the most likely UNSPSC Taxonomy Code. Just return the lowest level text of the UNSPSC only with no code: ',
	--@prompt1 NVARCHAR(max) = 'Default Prompt1',
	@system_prompt NVARCHAR(max) = 'Default',
	--@prompt2 NVARCHAR(max) = 'Default Prompt2',
	@to_clean NVARCHAR(50) = '0',
	@custom_mode NVARCHAR(50) = '0'
AS   
BEGIN
	DECLARE @cmd NVARCHAR(4000);





	-- Add in taxTaxonomy Validation


	--drop table if exists #tmpTest
	--create table #tmpTest ([Columns] nvarchar (255))
	--insert into #tmpTest ([Columns]) values
	--( 'Category 5');
	--insert into #tmpTest ([Columns]) values
	--( 'Category 4');
	--insert into #tmpTest ([Columns]) values
	--( 'Category 3');
	--insert into #tmpTest ([Columns]) values
	--( 'Category 2');
	--insert into #tmpTest ([Columns]) values
	--( 'Category 1');
	--insert into #tmpTest ([Columns]) values
	--( 'Category Code');
	----select * from #tmptest

	--if @mode in ('0','1')
	--	exec('
	--	declare @results int;


	--	with test as(SELECT * FROM ['+@taxonomy_db_name+'].INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '''+@taxonomy_table_name+''')
	--	select @results = count(*) FROM test a right join #tmpTest b on column_name = [Columns]
	--	WHERE COLUMN_NAME is null;


	--	drop table if exists #tmpTest

	--	if(@results =0) 
	--	 Select '''+@taxonomy_table_name+' validated'';
	--	ELSE
	--	select  ''Error! Please Include at least categories 1-5 and  category code in your taxTaxonomy. You may utilize the following code:'' as ''Message 1'',
	--		''ALTER TABLE taxTaxonomy
	--		ADD [Category 5] nvarchar(255);'' as ''Message 2''
	--		RETURN;


	--	')

	--drop table if exists #tmpTest


	-- Continue Process


	--IF @mode = '1'
	--	SET @cmd = 
	--	'python "G:\GenAIC - PROD\KaiT\workClassification1.py" [' + @mode + '-' + @client_db_name + '-' + @client_table_name + '-' + @taxonomy_db_name + '-' + @taxonomy_table_name + 	'-' + @is_UNSPSC + '-' + @field1
	--	;
	--ELSE IF @mode = '0'
	--	SET @cmd = 
	--	'python "G:\GenAIC - PROD\KaiT\workClassification.py" [' + @mode + '-' + @client_db_name + '-' + @client_table_name + '-' + @taxonomy_db_name + '-' + @taxonomy_table_name + 	'-' + @is_UNSPSC + '-' + @field1
	--	;
	IF @mode = '2'
		SET @cmd = 
		'python "G:\GenAIC - PROD\KaiT\workClassification2.py" [' + @mode + '-' + @client_db_name + '-' + @client_table_name + '-' + @taxonomy_db_name + '-' + @taxonomy_table_name + 	'-' + @is_UNSPSC + '-' + @field1
		;
	--ELSE IF @mode = '3'
	--	SET @cmd = 
	--	'python "G:\GenAIC - PROD\KaiT\workClassification3.py" [' + @mode + '-' + @client_db_name + '-' + @client_table_name + '-' + @taxonomy_db_name + '-' + @taxonomy_table_name + 	'-' + @is_UNSPSC + '-' + @field1
	--	;

	--ELSE IF @mode = '4'
	--	SET @cmd = 
	--	'python "G:\GenAIC - PROD\KaiT\workClassification4.py" [' + @mode + '-' + @client_db_name + '-' + @client_table_name + '-' + @taxonomy_db_name + '-' + @taxonomy_table_name + 	'-' + @is_UNSPSC + '-' + @field1
	--	;




	IF @field2 IS NOT NULL
		SET @cmd = @cmd + '-' + @field2
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field3 IS NOT NULL
		SET @cmd = @cmd + '-' + @field3
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field4 IS NOT NULL
		SET @cmd = @cmd + '-' + @field4
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field5 IS NOT NULL
		SET @cmd = @cmd + '-' + @field5
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field6 IS NOT NULL
		SET @cmd = @cmd + '-' + @field6
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field7 IS NOT NULL
		SET @cmd = @cmd + '-' + @field7
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field8 IS NOT NULL
		SET @cmd = @cmd + '-' + @field8
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field9 IS NOT NULL
		SET @cmd = @cmd + '-' + @field9
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;

	IF @field10 IS NOT NULL
		SET @cmd = @cmd + '-' + @field10
	ELSE
		SET @cmd = @cmd + '-' + 'None'
	;
	
	SET @prompt1 = REPLACE(@prompt1, ' ', '_');
	SET @system_prompt = REPLACE(@system_prompt, ' ', '_');

	SET @cmd = @cmd + '-' + @to_clean +'-' + @custom_mode + ']' + ' [' + @prompt1 + '-' + @system_prompt +']'

	-- PRINT @cmd;

	declare @user nvarchar(50)
	select @user = cast(SUSER_NAME() as nvarchar(50))

	declare @rowCount int

	exec [gpt_test].[dbo].[spGetRows] @client_db_name, @client_table_name, @rowCount output


	exec('

	INSERT INTO [GPT_TEST].[dbo].[tblAICGenAILog]
				([Client Db]
				,[Mode]
				,[Lines]
				,[Time]
				,[User]
				,[Tokens]
				,[Status])
			VALUES
				(
				'''+@client_db_name+'''
				,'''+@mode+'''
				,'+@rowCount+'
				,getdate()
				,'''+@user+'''
				,0
				,''Begin Process''
				)
	')




	EXEC master..xp_cmdshell @cmd



--------------------\\\\  Merge Data Back into SQL //////----------------



	-- IF @to_merge = 1
-- Declare variables
	DECLARE @field1_cleaned NVARCHAR(50);
	SET @field1_cleaned = REPLACE(@field1,'_',' ')

	IF @client_db_name = 'uth_tmc'
		set @client_db_name = 'uth-tmc'




	
-- Check for Destination Columns for 1 and 4
	IF @to_merge = 1 and @mode in ('2')
			EXEC('
		IF NOT EXISTS (SELECT * FROM  ['+@client_db_name+'].INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '''+@client_table_name+'''
		and COLUMN_NAME = ''Completion'')
			ALTER TABLE ['+@client_db_name+'].dbo.'+@client_table_name+' ADD [Completion] NVARCHAR(Max);

			')






	IF @to_merge = 1 and @mode in ('2')
		exec(
		
		'update a
			set
			 a.[Completion] = b.[Completion]
		from ['+@client_db_name+'].dbo.'+@client_table_name+
		' a inner join ['+@client_db_name+'].dbo.gptCompletions b on 
		a.['+@field1_cleaned+'] = b.[Description]'
		
		)

	;




--------------------\\\\  Log the process //////----------------

	
IF (NOT EXISTS (SELECT * FROM gpt_test.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'tblAICGenAILog'))
BEGIN
    CREATE TABLE tblAICGenAILog ([Id] INT NOT NULL IDENTITY (1,1), [Client Db] nvarchar(255) NULL,[Mode] nvarchar(255) NULL, [Lines] nvarchar(255) NULL, [Time] datetime NULL,[User] nvarchar(max))
END;

declare @tokenCount int


IF @mode not in ('1', '4')


	exec('

	INSERT INTO [GPT_TEST].[dbo].[tblAICGenAILog]
			   ([Client Db]
			   ,[Mode]
			   ,[Lines]
			   ,[Time]
			   ,[User]
			   ,[Tokens]
			   ,[Status])
		 VALUES
			   (
			   '''+@client_db_name+'''
			   ,'''+@mode+'''
			   ,'+@rowCount+'
			   ,getdate()
			   ,SUSER_NAME()
			   ,NULL
			   ,''Finished Process''
			   )
	')


exec('

SELECT
           '''+@client_db_name+''' as [Client Db]
           ,'''+@mode+''' as [Mode]
           ,'+@rowCount+' as [Lines]
           ,getdate() as [Date]
           ,SUSER_NAME() as [User]
		   
')

END
GO

