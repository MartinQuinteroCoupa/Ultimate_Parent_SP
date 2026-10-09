-- Import Variables for SP and create procedure

create procedure [dbo].[UltimateParentSP]
    @client_db_name NVARCHAR(50) = 'aic_data'


-- Step 1 (Top 100 Suppliers) into temp_table
Drop table if exists #temp_suppliers ;

Create Table #temp_suppliers (
    [Normalized Supplier] varchar(max),
    [Ultimate Parent] varchar(max)
) ;

insert into #temp_suppliers ([Normalized Supplier], [Ultimate Parent])
select top 100 [Normalized Supplier] , [Ultimate Parent] as NULL 
from @client_db_name.[tblRefresh] order by sum([Spend]) DESC ;



-- Step 2.1 (Using SP to connect to Coupa's GenAI freeform resource, to get new Ultimate Parents) 
-- considering table luUParent is created

Drop table if exists #new_entries

select b.[Normalized Supplier] , b.[Ultimate Parent]
into #new_entries a
from #temp_suppliers b
where b.[Normalized Supplier] not in (
    select [Normalized Supplier] from luUParent
)

/* Executing AI Process */

EXEC [aic_data].[dbo].[GenAIConnection]
@mode = '2',
@client_db_name = @client_db_name,
@client_table_name = '#new_entries',
@field1 = 'Normalized Supplier',
@prompt1 = 'Return the Ultimate Supplier or Parent Company of the following supplier. Do not return extra information',
@to_merge = 1;

/*Merging back to luUParent after AI populated Ultimate Parent */

insert into luUParent ([Normalized Supplier], [Ultimate Parent])
select b.[Normalized Supplier], b.[Ultimate Parent] 
from #new_entries b
where b.[Normalized Supplier] not in (
    select [Normalized Supplier] from luUParent
) -- Safeguard to avoid storing duplicates if table luUParent was manually edited


-- Step 2.2 (Populating Ultimate Parent from global tblUParent)

update a
set a.[ultimate Parent] = b.[Ultimate Parent]
from tblRefresh a
join luUParent b on a.[Normalized Supplier] = b.[Supplier Name]
where a.[Normalized Supplier] in (
    select [Supplier Name] from #temp_suppliers
)





