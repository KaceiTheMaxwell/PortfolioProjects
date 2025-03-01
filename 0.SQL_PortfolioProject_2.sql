/* 

Nashville Housing Data: Data Cleaning

*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format

-- Issue: The "SaleDate" column is formatted in datetime format. Let us remove the unnecessary timestamp


ALTER TABLE NashvilleHousing 
Add SaleDateConverted Date; -- first add a new column

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate) -- update this column to the values of the converted date format without time

--ALTER TABLE NashvilleHousing
--DROP COLUMN SaleDateConvert

SELECT * -- rerun script to show all data with the new added column included
FROM PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address Data

/* Issue: 

1. There are instances where the Property Address is listed as "NULL"
2. Reviewing the data, we notice that there is a co-relation between ParcelID and PropertyAddress. The same ParcelID is listed for multiple 
   addresses. The HAVING statement confirms this observation. This may mean they have the same addresses.

*/

-- STEP 1: Verify observation

SELECT ParcelID, COUNT(ParcelID) 
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is NULL
GROUP BY ParcelID
HAVING COUNT(ParcelID) > 1  and COUNT(PropertyAddress) > 1  -- double check which ParcelID has multiple PropertyAddress


-- STEP 2: Replace the NULL values in the Property Address column

-- Join the table to itself because although the property can be sold multiple times (hence unique ID), we can fairly assume  
--			the prperty location remains the same (same parcel ID). Where we NULL values, can simply create a new column having it 
--			containing the address of the PARCEL ID

SELECT NASH.ParcelID, VILLE.ParcelID, NASH.PropertyAddress, VILLE.PropertyAddress, ISNULL(NASH.PropertyAddress, VILLE.PropertyAddress) AS Missing_PropertyAddress
 -- ISNULL says when NASH.PropertyAddress is NULL, place VILLE.PropertyAddress in its place, which is exactly the same address
FROM PortfolioProject.dbo.NashvilleHousing AS NASH
JOIN PortfolioProject.dbo.NashvilleHousing AS VILLE
ON NASH.ParcelID = NASH.ParcelID
AND NASH.[UniqueID] <> VILLE.[UniqueID]
WHERE NASH.PropertyAddress IS NULL

-- STEP 3: Update PropertyAddress column in table

UPDATE NASH
SET PropertyAddress = ISNULL(NASH.PropertyAddress, VILLE.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing AS NASH
JOIN PortfolioProject.dbo.NashvilleHousing AS VILLE
ON NASH.ParcelID = NASH.ParcelID
AND NASH.[UniqueID] <> VILLE.[UniqueID]
WHERE NASH.PropertyAddress IS NULL

-- then ... check master table
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
-- WHERE PropertyAddress IS NULL


-- STEP 4: Rerun to check if there are any remaining null values in the column. rerun should not return any values (empty table)

--SELECT NASH.ParcelID, VILLE.ParcelID, NASH.PropertyAddress, VILLE.PropertyAddress, ISNULL(NASH.PropertyAddress, VILLE.PropertyAddress) AS Missing_PropertyAddress
-- -- ISNULL says when NASH.PropertyAddress is NULL, place VILLE.PropertyAddress in its place
--FROM PortfolioProject.dbo.NashvilleHousing AS NASH
--JOIN PortfolioProject.dbo.NashvilleHousing AS VILLE
--ON NASH.ParcelID = NASH.ParcelID
--AND NASH.[UniqueID] <> VILLE.[UniqueID]
--WHERE NASH.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out address info (Address, City, State)

SELECT PropertyAddress, OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress IS NOT NULL

/* Reviewing the non-NULL address, we observe that a comma is used as a separator, while the Address, City, State are not completed separated

We can use a SUBSTRING or PARSENAME to break up this information - just remember the correct syntax for writing each
*/

-- the more difficult or tedious SUBSTRING way
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS PropAddress, -- the position 1 indicates starting at index 1. starting at position -1 removes the common in address
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS PropCity
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress IS NOT NULL

ALTER TABLE NashvilleHousing 
Add PropertySplitAddress Nvarchar(255); -- first add a new column

ALTER TABLE NashvilleHousing 
Add PropertySplitCity Nvarchar(255); -- first add a new column

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) -- update this column to with the convert date format

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) -- update this column to with the convert date format

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress IS NOT NULL

--ALTER TABLE NashvilleHousing
--DROP COLUMN OwnerSplitAddress, OwnerSplitCity

-- the faster PARSENAME method to separate the column into multiple columns (PARSENAME(REPLACE(ColumnName,',', '.'), 3)

SELECT
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3) AS OwnerSplitAddress, -- Reminder, PARSENAME can separate your data into multiple columns by looking for a period 
											  -- as the separator. AND, it works back to front so the last items first. Placing 3, 2, 1
											  -- means TN fist, then the city then the address
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2) AS OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1) AS OwnerSplitState
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress IS NOT NULL

-- now create and add new colums to original table
ALTER TABLE NashvilleHousing 
Add OwnerSplitAddress Nvarchar(255);

ALTER TABLE NashvilleHousing 
Add OwnerSplitCity Nvarchar(255);

ALTER TABLE NashvilleHousing 
Add OwnerSplitState Nvarchar(255);

-- update new columns with the parsed name values
Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

-- check to see if the table includes new columns and new data/values

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress IS NOT NULL

--------------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerSplitName

ALTER TABLE NashvilleHousing 
Add OwnerSplitName Nvarchar(255);

-- update new columns with the parsed name values
Update NashvilleHousing
SET OwnerSplitName = PARSENAME(REPLACE(OwnerName,'&', '.'), 1)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in the "Sold as Vacant" column

-- Let us review this data field using DISTINCT. 

SELECT DISTINCT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing

-- Results show N, Y, Yes and No. Use Count to see how pervasive this mix is.

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

-- We can use a case statement to correct this issue, and  modify this for consistency

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END
FROM PortfolioProject.dbo.NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

-- Remove duplicates

-- Create a CTE to make it easier to query. The query and filter show that there are 103 rows with duplicates
WITH RowNumCTE AS 
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference ORDER BY UniqueID) AS RowNumber
FROM PortfolioProject.dbo.NashvilleHousing
-- ORDER BY ParcelID
)

SELECT *
FROM RowNumCTE
WHERE RowNumber > 1
ORDER BY PropertyAddress

-- Now delete the duplicate data. The original file was copied in case we need the data again.
-- Delete then verify that there are no more duplicates using DELETE and SELECT *

WITH RowNumCTE AS 
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference ORDER BY UniqueID) AS RowNumber
FROM PortfolioProject.dbo.NashvilleHousing
-- ORDER BY ParcelID
)

DELETE -- NOTE the delete statement here
FROM RowNumCTE
WHERE RowNumber > 1
-- ORDER BY PropertyAddress

WITH RowNumCTE AS 
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference ORDER BY UniqueID) AS RowNumber
FROM PortfolioProject.dbo.NashvilleHousing
-- ORDER BY ParcelID
)

SELECT * -- NOTE the select statement to verify deletion
FROM RowNumCTE
WHERE RowNumber > 1
ORDER BY PropertyAddress

---------------------------------------------------------------------------------------------------------------------------------------------------

-- DELETE Unused Columns (optional or simply delete only in VIEWS)

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate


