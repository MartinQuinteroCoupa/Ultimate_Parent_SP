Steps of the Ultimate Parent Sotred Procedure

Pre-requsites in DB

-luUParent table must be created with columns [Normalized Supplier] and [Ultimate Parent]

Step 1

Retrieve top 100 normalized suppliers by spend in tblRefresh

Step 2 

Is the supplier already in luUParent?

if not Step 2.1

Use GenAI to suggest the Ultimate Parent for new record
Append the new record into luUParent

if yes Step 2.2

continue with next record

Step 3 

update tblRefresh [Ultimate Parent] value by joining with updated luUParent on key [Normalized Supplier]


Constraints

-To not have many to many issues, duplicates are not allowed in luUTable, one Normalized supplier should and must
only have one Ultimate Parent



