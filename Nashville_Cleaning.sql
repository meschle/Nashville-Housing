-- Cleaning in SQL using queries :) 


 -- in this cleaning session we used a lot of really cool SQL qeuries to clean the databse, including UPDATE(), ALTER TABLE(), 
 -- CONVERT(), JOIN(), SUBSTRING(), PARSENAME(), a CTE, OVER(PARTITION BY()), and lastly DROP COLUMN()

 -- This data will now be able to be more efficently for the project! 

select *
from PortfolioProject.dbo.Nashville_Housing

----------------------------------------------------------------------------------------------------------------------------

-- Standardising Date Format --

select SaleDate, CONVERT(Date,SaleDate) -- selecting Sale Date and converting this into a date data type
from PortfolioProject.dbo.Nashville_Housing

Update PortfolioProject.dbo.Nashville_Housing -- updating the table to this change
SET SaleDate = CONVERT(Date, SaleDate)

--Adding new column with converted sale date
ALTER TABLE PortfolioProject.dbo.Nashville_Housing --Adding new column with converted sale date
Add SaleDateConverted Date;

Update PortfolioProject.dbo.Nashville_Housing -- updating the table to this change
SET SaleDateConverted = CONVERT(Date, SaleDate)
--checking that it worked

select SaleDateConverted, SaleDate
from PortfolioProject.dbo.Nashville_Housing

----------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data --

-- checking for null values
select *
from PortfolioProject.dbo.Nashville_Housing
where PropertyAddress is null 
--noticing there is 29 null values in Property Address column

select *
from PortfolioProject.dbo.Nashville_Housing
--where PropertyAddress is null
order by ParcelID

-- in this database, each row has a parcel ID which is matched to the purchase of the house. Some are repeating Parcel ID's
-- each Parcel ID is always matched to the same address
-- therefore, some null's may be able to be populated with the correct address, if there are matching Parcel ID's! 

-- first we create a JOIN table that is able to compare unpopulated addresses with a result that has the correct address
-- we do this by having the original and joined duplicate table match on the Parcel ID but differ on the unique ID (which is different on each sale)
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from PortfolioProject.dbo.Nashville_Housing a 
JOIN PortfolioProject.dbo.Nashville_Housing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
where a.PropertyAddress is null

-- next we will use the ISNULL() function to start the process of replacing the null result with the b.PropertyAddress result of the previous table
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.Nashville_Housing a 
JOIN PortfolioProject.dbo.Nashville_Housing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
where a.PropertyAddress is null

-- sweet, it worked! we will update the table now with the correct informaiton! 

UPDATE a
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.Nashville_Housing a 
JOIN PortfolioProject.dbo.Nashville_Housing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
where a.PropertyAddress is null

-- checking to make sure it worked correctly!
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from PortfolioProject.dbo.Nashville_Housing a 
JOIN PortfolioProject.dbo.Nashville_Housing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
where a.PropertyAddress is null

----------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State) -- 

select PropertyAddress
from PortfolioProject.dbo.Nashville_Housing

-- creating the first substring of just the address
-- using CHARINDEX() to search for a specific value in a string and then substracting one (erase the comma)
Select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address
from PortfolioProject.dbo.Nashville_Housing

-- creating second substring starting at one value after the comma and ending at the length of the Property Address field
Select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City
from PortfolioProject.dbo.Nashville_Housing

-- updating database so these are included 
ALTER TABLE PortfolioProject.dbo.Nashville_Housing -- adds the column, sets it as nvarchar
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject.dbo.Nashville_Housing -- populates column with address
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE PortfolioProject.dbo.Nashville_Housing ---- adds the column, sets it as nvarchar
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject.dbo.Nashville_Housing -- populates column with city
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

-- checking to make sure it works
select *
from PortfolioProject.dbo.Nashville_Housing

-- doing a similar thing with OwnerAddress column, using parsename
-- since parsename uses periods, we will replace comma with periods
-- also since parsename works backwords, we will go in reverse order

select 
parsename(replace(OwnerAddress,',','.'),3) as OwnerSplitAddress,
parsename(replace(OwnerAddress,',','.'),2) as OwnerSplitCity,
parsename(replace(OwnerAddress,',','.'),1) as OwnerSplitState
from PortfolioProject.dbo.Nashville_Housing

-- updating database as before

ALTER TABLE PortfolioProject.dbo.Nashville_Housing -- adds the column, sets it as nvarchar
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject.dbo.Nashville_Housing -- populates column with address
SET OwnerSplitAddress = parsename(replace(OwnerAddress,',','.'),3)

ALTER TABLE PortfolioProject.dbo.Nashville_Housing ---- adds the column, sets it as nvarchar
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject.dbo.Nashville_Housing -- populates column with city
SET OwnerSplitCity = parsename(replace(OwnerAddress,',','.'),2)

ALTER TABLE PortfolioProject.dbo.Nashville_Housing ---- adds the column, sets it as nvarchar
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject.dbo.Nashville_Housing -- populates column with state
SET OwnerSplitState = parsename(replace(OwnerAddress,',','.'),1)

-- checking to make sure it worked
select *
from PortfolioProject.dbo.Nashville_Housing

----------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sole as Vacant" Field --

select Distinct(SoldAsVacant), Count(SoldAsVacant)
from PortfolioProject.dbo.Nashville_Housing
group by SoldAsVacant
order by 2

select SoldAsVacant,
    CASE When SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldasVacant = 'N' THEN 'No'
    Else SoldAsVacant
    End
from PortfolioProject.dbo.Nashville_Housing

Update PortfolioProject.dbo.Nashville_Housing
SET SoldAsVacant= CASE When SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldasVacant = 'N' THEN 'No'
    Else SoldAsVacant
    End

--checking it worked
select Distinct(SoldAsVacant), Count(SoldAsVacant)
from PortfolioProject.dbo.Nashville_Housing
group by SoldAsVacant
order by 2

----------------------------------------------------------------------------------------------------------------------------

-- Remove duplicates --


-- creating a CTE to act where we can select the duplicates 
-- and using DELETE to delete all duplicates
WITH RowNumCTE as (
select *,
    ROW_NUMBER() OVER (
    PARTITION by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
    ORDER BY UniqueID) row_num
from PortfolioProject.dbo.Nashville_Housing
--order by ParcelID
)
DELETE
from RowNumCTE
where row_num > 1
--order by PropertyAddress

--checking if it worked
WITH RowNumCTE as (
select *,
    ROW_NUMBER() OVER (
    PARTITION by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
    ORDER BY UniqueID) row_num
from PortfolioProject.dbo.Nashville_Housing
--order by ParcelID
)
Select *
from RowNumCTE
where row_num > 1
--order by PropertyAddress

----------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns --

select *
from PortfolioProject.dbo.Nashville_Housing

-- dropping columns that were cleaned and converted into more usable columns
ALTER TABLE PortfolioProject.dbo.Nashville_Housing
DROP COLUMN OwnerAddress, PropertyAddress

ALTER TABLE PortfolioProject.dbo.Nashville_Housing
DROP COLUMN SaleDate


----------------------------------------------------------------------------------------------------------------------------