--EXPLORING DATA TO FIND ISSUES

Select *
from dbo.Housing_data

--------------------------------------------------------------------------------------------------------------------------------------


-- Number of rows
Select COUNT(*)
from dbo.Housing_data
-- 56477 rows

--------------------------------------------------------------------------------------------------------------------------------------


-- Checking for NULL Values
Select
(Select COUNT(*) From Housing_data where ParcelID is  NULL) as ParcelID,
--(Select COUNT(*) From Housing_data where LandUse is NULL) as LandUse,
(Select COUNT(*) From Housing_data where PropertyAddress is NULL) as PropertyAddress,
(Select COUNT(*) From Housing_data where LegalReference is NULL) as LegalReference,
(Select COUNT(*) From Housing_data where SoldAsVacant is NULL) as SoldAsVacant
--Property Address has 29 Null Values


--------------------------------------------------------------------------------------------------------------------------------------


--Finding Count of Distinct Values to check for duplicates
Select count(distinct(UniqueID)) as unique_count_UniqueID ,count(distinct(ParcelID))as unique_count_ParcelID, count(distinct(LegalReference))as unique_count_LegalReference
From Housing_data
-- Parcel ID & LegalReference do not have Unique Values and Null values i.e values are repeated


--------------------------------------------------------------------------------------------------------------------------------------


-- Checking for Distinct Values 
Select SoldAsVacant,(count(SoldAsVacant))
From Housing_data
group by SoldAsVacant

Select Distinct(TaxDistrict)
From Housing_data

--------------------------------------------------------------------------------------------------------------------------------------

--DATA CLEANING

--Updating SoldAsVacant values to be consistent
Select SoldAsVacant,
Case when SoldasVacant = 'Y' then 'Yes'
when SoldasVacant = 'N' then 'No'
Else SoldasVacant
end 
from Housing_data

--Updating the Table
Update Housing_data
Set SoldAsVacant = 
Case when SoldasVacant = 'Y' then 'Yes'
when SoldasVacant = 'N' then 'No'
Else SoldasVacant
end 
from Housing_data


--------------------------------------------------------------------------------------------------------------------------------------


--Converting Datetime into Date
Select CONVERT(date,SaleDate) as Sale_Date
From Housing_data

-- Updating the Table
Alter TABLE Housing_data
Add Sale_Date date

Update Housing_data
Set Sale_Date = CONVERT(date,SaleDate)


--------------------------------------------------------------------------------------------------------------------------------------


--Populating PropertyAddress in NULL cells from Duplicate Parcel IDs having a Property Address

--Explanation: Since Parcel IDs refer to the same real estate land and the data has duplicate Parcel IDs, We can populate the cells with no
--Property Addresses by checking if its Parcel ID has a duplicate and populating the PropertyAddress corresponding to the Duplicate
--Parcel ID

--Joining the data set to match the Null Property Address Values with Rows with duplicate ParcelIDs and corresponding PropertyAddress

Select a.ParcelID ,b.ParcelID, a.PropertyAddress,b.PropertyAddress  --Joining dataset with itself
From Housing_data a
JOIN Housing_data b
on a.ParcelID = b.ParcelID    --Joining on parcel ID to match the IDs
	and a.uniqueID <> b.uniqueID  -- Ensuring Unique IDs do not match so that the same row is not joined to each other
Where a.PropertyAddress is NULL -- Renders the left table with only Null Cell values 

--Populating data into the Null values
Update a
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From Housing_data a
JOIN Housing_data b
on a.ParcelID = b.ParcelID
	and a.uniqueID <> b.uniqueID
Where a.PropertyAddress is NULL


--------------------------------------------------------------------------------------------------------------------------------------


-- Removing Duplicate Rows

With ROWCTE as(
Select * ,
Row_Number() OVER(Partition by ParcelID, LegalReference, PropertyAddress, Sale_Date Order by UniqueID) as row_num
from Housing_data)
Delete
from ROWCTE
Where row_num >1


--------------------------------------------------------------------------------------------------------------------------------------


--Rounding Acreage Numbers and Updating Table
ALTER TABLE Housing_data
Add Acreage_rounded float

Update Housing_data
Set Acreage_rounded = Round(Acreage,2)


--------------------------------------------------------------------------------------------------------------------------------------


--Splitting PropertyAddress into different columns for Address and City

Select PropertyAddress, SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Property_Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as Property_City
from Housing_data

--Updating the Table
Alter Table Housing_data
Add Property_Address nvarchar(100)

Update Housing_data
Set Property_Address = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

Alter Table Housing_data
Add Property_City nvarchar(100)

Update Housing_data
Set Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))


--------------------------------------------------------------------------------------------------------------------------------------


--Splitting OwnerAddress into different columns for Address, City and State

Select PARSENAME(REPLACE(OwnerAddress,',','.') , 3),
PARSENAME(REPLACE(OwnerAddress,',','.') , 2),
PARSENAME(REPLACE(OwnerAddress,',','.') , 1)
From Housing_data

--Updating the Table

Alter Table Housing_data
Add Owner_Address nvarchar(100)

Update Housing_data
Set Owner_Address = PARSENAME(REPLACE(OwnerAddress,',','.') , 3)

Alter Table Housing_data
Add Owner_City nvarchar(100)

Update Housing_data
Set Owner_City = PARSENAME(REPLACE(OwnerAddress,',','.') , 2)

Alter Table Housing_data
Add Owner_State nvarchar(100)

Update Housing_data
Set Owner_State = PARSENAME(REPLACE(OwnerAddress,',','.') , 1)


--------------------------------------------------------------------------------------------------------------------------------------


--Deleting Columns that are not needed
Alter Table Housing_data
DROP Column PropertyAddress,OwnerAddress,Acreage, SaleDate
