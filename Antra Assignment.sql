--1.	List of Persons’ full name, all their fax and phone numbers, 
--as well as the phone number and fax of the company they are working for (if any). 

SELECT ap.FullName, ap.FaxNumber, ap.PhoneNumber,ap2.FaxNumber 'Company FaxNumber',ap2.PhoneNumber 'Company Phone Number'
FROM Application.People ap
Left JOIN Application.People ap2 ON ap.PersonID = ap2.PersonID and ap2.IsEmployee = 1

--2.	If the customer's primary contact person has the same phone number as
--the customer’s phone number, list the customer companies. 

SELECT sc.CustomerName
FROM Sales.Customers sc 
JOIN Application.People ap	ON sc.PrimaryContactPersonID = ap.PersonID
WHERE sc.PhoneNumber = ap.PhoneNumber

--3.	List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.
SELECT sc.CustomerName 
FROM Sales.Customers  sc
JOIN Sales.Orders so ON sc.CustomerID = so.CustomerID 
WHERE so.CustomerID NOT IN(SELECT CustomerID FROM Sales.Orders WHERE OrderDate > '2016-01-01')

--SECOND WAY
WITH CTE AS (SELECT sc.CustomerName , so.OrderDate
FROM Sales.Customers  sc
LEFT JOIN Sales.Orders so ON sc.CustomerID = so.CustomerID WHERE so.OrderDate > '2016-01-01')
SELECT CustomerName FROM CTE WHERE OrderDate IS NULL


--4.	List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.

SELECT ws.StockItemName, SUM(ws1.Quantity) Total_quantity
FROM Warehouse.StockItems ws
JOIN Warehouse.StockItemTransactions ws1 ON ws.StockItemID = ws1.StockItemID
JOIN Purchasing.PurchaseOrderLines pp ON ws1.StockItemID = pp.StockItemID
JOIN Purchasing.PurchaseOrders pp2 ON pp.PurchaseOrderID = pp2.PurchaseOrderID
WHERE year(pp2.OrderDate) = 2013
GROUP BY ws.StockItemName
Order BY Total_quantity DESC
--5.	List of stock items that have at least 10 characters in description.

SELECT StockItemName FROM Warehouse.StockItems
WHERE len(StockItemName) >= 10

--6.	List of stock items that are not sold to the state of Alabama and Georgia in 2014.

SELECT ws.StockItemName
FROM Warehouse.StockItems ws 
JOIN Sales.OrderLines so ON ws.StockItemID = so.StockItemID
JOIN Sales.Orders so1 ON so.OrderID = so1.OrderID and YEAR(so1.OrderDate) =2014
JOIN Sales.Customers sc ON so1.CustomerID = sc.CustomerID
WHERE PostalCityID NOT IN(SELECT StateProvinceID FROM Application.StateProvinces WHERE StateProvinceName <> 'Georgia' and StateProvinceName <> 'Alabama')

--7.	List of States and Avg dates for processing (confirmed delivery date – order date).

SELECT st.StateProvinceName, AVG(DATEDIFF(DAY,so.OrderDate, si.ConfirmedDeliveryTime )) 'Avg date for processing'
FROM Sales.Invoices si
join Sales.Orders so ON si.CustomerID = so.CustomerID
join Sales.Customers sc on so.CustomerID = sc.CustomerID
join Application.Cities ac ON sc.PostalCityID = ac.CityID
join Application.StateProvinces st ON ac.StateProvinceID = st.StateProvinceID
GROUP BY st.StateProvinceName

--8.	List of States and Avg dates for processing (confirmed delivery date – order date) by month.
SELECT st.StateProvinceName, month(so.OrderDate) as 'Month',   AVG(DATEDIFF(DAY,so.OrderDate,si.ConfirmedDeliveryTime )) 'Avg date for processing'
FROM Sales.Invoices si
join Sales.Orders so ON si.CustomerID = so.CustomerID
join Sales.Customers sc on so.CustomerID = sc.CustomerID
join Application.Cities ac ON sc.PostalCityID = ac.CityID
join Application.StateProvinces st ON ac.StateProvinceID = st.StateProvinceID
GROUP BY st.StateProvinceName, month(so.OrderDate)
ORDER BY st.StateProvinceName, 'Month'

--9.	List of StockItems that the company purchased more than sold in the year of 2015.

WITH Purchased_2015 AS
( SELECT pl.StockItemID, SUM(pl.ReceivedOuters) AS Purchased
FROM Purchasing.PurchaseOrderLines pl
JOIN Purchasing.PurchaseOrders po ON pl.PurchaseOrderID = po.PurchaseOrderID
WHERE year(po.OrderDate) = 2015
GROUP BY pl.StockItemID),
SOLD_2015 AS( SELECT sl.StockItemID, SUM(sl.Quantity) AS sold
FROM Sales.OrderLines sl
JOIN Sales.Orders so ON sl.OrderID = so.OrderID
WHERE year(so.OrderDate) = 2015
GROUP BY sl.StockItemID)

SELECT p.StockItemID 'Purchased Items'
FROM Purchased_2015 p
JOIN SOLD_2015 s ON p.StockItemID = s.StockItemID WHERE p.purchased > s.sold 

--10 List of Customers and their phone number,
--together with the primary contact person’s name, to whom we did not sell more than 10  mugs (search by name) in the year 2016.

SELECT CONCAT(sc.CustomerName,' ' ,sc.PhoneNumber, ' ' ,sc.PrimaryContactPersonID) AS Customer , sl.Quantity
FROM Sales.Customers sc
JOIN Sales.Orders so ON sc.CustomerID=so.CustomerID and YEAR(so.OrderDate)=2016
JOIN Sales.OrderLines sl ON so.OrderID = sl.OrderID
JOIN Warehouse.StockItemStockGroups ws ON sl.StockItemID = ws.StockItemID
JOIN Warehouse.StockGroups wg ON ws.StockGroupID = wg.StockGroupID and  wg.StockGroupName = 'Mugs'
WHERE Quantity< 10
ORDER BY Quantity DESC


-- 11.	List all the cities that were updated after 2015-01-01.

SELECT CityName FROM Application.Cities FOR SYSTEM_TIME BETWEEN'2015-01-01 00:00:00.0000000' AND'9999-12-31 23:59:59.9999999'

--12.	List all the Order Detail (Stock Item name, delivery address, delivery state, city, country, 
--customer name, customer contact person name, customer phone, quantity)for the date of 2014-07-01.
--Info should be relevantto that date.

SELECT ws.StockItemName ,sl.Quantity ,sc.CustomerName,si.ContactPersonID,sc.PhoneNumber,CONCAT(sc.DeliveryAddressLine1,' ' ,sc.DeliveryAddressLine1, ' ' ,sc.PostalPostalCode) AS Address, sc.PostalCityID, 
 ac.CityName, ast.StateProvinceName, aco.CountryName
FROM Warehouse.StockItems  ws
JOIN Sales.InvoiceLines sl ON ws.StockItemID = sl.StockItemID
JOIN Sales.Invoices si ON sl.InvoiceID =si.InvoiceID and si.InvoiceDate = '2014-07-01'
JOIN Sales.Customers sc ON si.CustomerID = sc.CustomerID
JOIN Application.Cities ac ON sc.PostalCityID =ac.CityID
JOIN Application.StateProvinces ast ON ac.StateProvinceID = ast.StateProvinceID
JOIN Application.Countries aco ON ast.CountryID = aco.CountryID

 --13.	List of stock item groups and total quantity purchased, total quantity sold, 
 --and the remaining stock quantity (quantity purchased – quantity sold)

 With Purchased AS ( SELECT wg.StockItemStockGroupID, SUM(po.ReceivedOuters) AS total_purchased , po.StockItemID
 FROM Warehouse.StockItemStockGroups wg
 JOIN Purchasing.PurchaseOrderLines po ON wg.StockItemID = po.StockItemID
 GROUP BY wg.StockItemStockGroupID,po.StockItemID),
 SOLD AS(SELECT SUM(Quantity) AS total_sold , StockItemID
 FROM Sales.InvoiceLines
 GROUP BY StockItemID)

 SELECT p.StockItemStockGroupID, p.total_purchased , s.total_sold , (p.total_purchased - s.total_sold) as 'Remaining Stock Quantity'
 FROM Purchased p
 JOIN SOLD s ON p.StockItemID = s.StockItemID
 GROUP BY p.StockItemStockGroupID, p.total_purchased , s.total_sold

 --14.	List of Cities in the US and the stock item that the city got the most deliveries in 2016.
 --If the city did not purchase any stock items in 2016, print “No Sales”.

WITH rnk AS 
(SELECT sl.StockItemID,sl.Description, c.PostalCityID, SUM(sl.Quantity) AS Total, RANK()OVER(PARTITION BY c.PostalCityID ORDER BY SUM(sl.Quantity) DESC) AS rn

FROM Sales.Orderlines AS sl
JOIN Sales.Orders AS so ON sl.OrderID = so.OrderID
JOIN Sales.Customers AS c ON so.CustomerID = c.CustomerID and year(so.OrderDate) = 2016
GROUP BY c.PostalCityID, sl.StockItemID, sl.Description)

SELECT ac.CityName,  ISNULL(rnk1.Description, 'No Sales') AS 'Sales Order Description'
FROM Application.Cities AS ac
LEFT JOIN rnk AS rnk1 ON ac.CityID =rnk1.PostalCityID and rnk1.rn =1
JOIN Application.StateProvinces AS ast ON ac.StateProvinceID = ast.StateProvinceID
JOIN Application.Countries AS aco ON ast.CountryID = aco.CountryID and aco.CountryName = 'United States'
ORDER BY ac.CityName

 --15.	List any orders that had more than one delivery attempt (located in invoice table).

SELECT OrderID, Count(OrderID) ordernumber, JSON_VALUE(si.ReturnedDeliveryData, '$.Events[0].EventTime') as DeliveryAttempt
FROM Sales.Invoices si
GROUP BY OrderID,JSON_VALUE(si.ReturnedDeliveryData, '$.Events[0].EventTime')
HAVING COUNT(OrderID)>1

 --16	List all stock items that are manufactured in China. (Country of Manufacture)
SELECT 
JSON_VALUE(c.CustomFields, '$.CountryOfManufacture') AS country,c.StockItemID, c.StockItemName
FROM Warehouse.StockItems AS c
WHERE JSON_VALUE(c.CustomFields, '$.CountryOfManufacture') = 'China'

 --17.	Total quantity of stock items sold in 2015, group by country of manufacturing.

SELECT JSON_VALUE(ws.CustomFields, '$.CountryOfManufacture') AS 'Country of Manufacturing',SUM(sl.Quantity) 'Total quantity'
FROM Warehouse.StockItems ws 
JOIN Sales.OrderLines sl ON sl.StockItemID =ws.StockItemID
JOIN Sales.Orders so ON sl.OrderID = so.OrderID 
WHERE year(so.OrderDate) = 2015
GROUP BY JSON_VALUE(ws.CustomFields, '$.CountryOfManufacture')
 --
-- 18.	Create a view that shows the total quantity of stock items of each stock group sold 
--(in orders) by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]
DROP VIEW IF EXISTS Sales.Sales20132017
GO
CREATE VIEW Sales.Sales20132017 AS
SELECT * from(
SELECT  wg.StockGroupName,sl.Quantity AS Quantity,YEAR(so.OrderDate) AS 'year'
FROM Sales.Orders so
JOIN Sales.OrderLines sl ON so.OrderID = sl.OrderID
JOIN Warehouse.StockItemStockGroups ws ON sl.StockItemID = ws.StockItemID
JOIN Warehouse.StockGroups wg ON ws.StockGroupID = wg.StockGroupID
GROUP BY YEAR(so.OrderDate), wg.StockGroupName, sl.Quantity
) temp_table
pivot
(SUM(Quantity)
for year in([2013],[2014],[2015],[2016],[2017]))
pivot_table
SELECT * FROM Sales.Sales20132017
ORDER BY StockGroupName

--19.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. 
--[Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10]

DROP VIEW IF EXISTS Sales.Quantity20132017
GO
CREATE VIEW Sales.Quantity20132017 AS
SELECT * from(
SELECT  wg.StockGroupName StockGroupName,sl.Quantity AS Quantity,YEAR(so.OrderDate) AS 'year'
FROM Sales.Orders so
JOIN Sales.OrderLines sl ON so.OrderID = sl.OrderID
JOIN Warehouse.StockItemStockGroups ws ON sl.StockItemID = ws.StockItemID
JOIN Warehouse.StockGroups wg ON ws.StockGroupID = wg.StockGroupID
GROUP BY YEAR(so.OrderDate), wg.StockGroupName, sl.Quantity
) temp_table2
pivot
(SUM(Quantity)
for StockGroupName in([Clothing],[Computing Novelties],[Furry Footwear],[Mugs],[Novelty Items],[Packing Materials],[Toys],[T-Shirts],[USB Novelties]))
pivot_table
SELECT * FROM Sales.Quantity20132017

--20	Create a function, input: order id; return: total of that order. 
--List invoices and use that function to attach the order total to the other fields of invoices. 

CREATE OR ALTER FUNCTION Total_order(@order_id INT)
RETURNS int
AS 
BEGIN
	DECLARE @total INT
	SELECT @total = sl.UnitPrice*sl.Quantity + sl.TaxAmount
	FROM Sales.InvoiceLines sl
	JOIN Sales.Invoices si ON sl.InvoiceID = si.InvoiceID and si.OrderID = @order_id
	RETURN @total
END;
GO
SELECT sv.* , dbo.Total_order(sv.OrderID) AS Total
FROM Sales.Invoices sv

--21.	Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions, 
--that input is a date; when executed, it would find orders of that day, calculate order total, 
--and save the information (order id, order date, order total, customer id) into the new table. 
--If a given date is already existing in the new table, 
--throw an error and roll back. Execute the stored procedure 5 times using different dates. 
CREATE SCHEMA ods;
GO
DROP TABLE IF EXISTS ods.Orders
GO
CREATE TABLE ods.Orders(
orderID int,
customerID int,
OrderDate date,
order_total decimal(18,2) );

DROP PROCEDURE IF EXISTS orderofrows 
GO
CREATE PROCEDURE orderofrows @orderdate date
AS 
BEGIN
	SET NOCOUNT ON;
	BEGIN TRAN
		BEGIN TRY
		INSERT INTO ods.Orders(orderID,customerID,OrderDate,order_total)
		SELECT  so.OrderID,sc.CustomerID, so.OrderDate,SUM((sl.UnitPrice * sl.Quantity)) AS Total
		FROM Sales.OrderLines AS sl
		JOIN Sales.Orders AS so
		ON so.OrderID = sl.OrderID
		JOIN Sales.Customers AS sc
		ON sc.CustomerID = so.CustomerID and so.OrderDate = @orderdate 
		GROUP BY sc.CustomerID, so.OrderID, so.OrderDate
		DECLARE @row date
		IF @row =( SELECT OrderDate FROM ods.Orders WHERE OrderDate= @orderdate)
		ROLLBACK TRANSACTION 

		END TRY

		BEGIN CATCH
		IF @row != ( SELECT OrderDate FROM ods.Orders WHERE OrderDate= @orderdate)
		COMMIT TRANSACTION
		END CATCH
	END
exec orderofrows '2017-01-01'
exec orderofrows '2013-01-01'
exec orderofrows '2014-01-08'
exec orderofrows '2015-02-11'
exec orderofrows '2016-09-21'

--22.	Create a new table called ods.StockItem. It has following columns: 
--[StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID]
--,[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,
--[UnitPrice],[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments],
--[CountryOfManufacture], [Range], 
--[Shelflife]. Migrate all the data in the original stock item table.

DROP TABLE IF EXISTS ods.StockItem
GO
CREATE TABLE ods.StockItem(
	StockItemID int,
	StockItemName nvarchar(100)
      ,SupplierID int
      ,ColorID int
      ,UnitPackageID int
      ,OuterPackageID int
      ,Brand nvarchar(20)
      ,Size nvarchar(20)
      ,LeadTimeDays int
      ,QuantityPerOuter int
      ,IsChillerStock bit
      ,Barcode nvarchar(50)
      ,TaxRate decimal(18,3)
      ,UnitPrice decimal(18,2)
      ,RecommendedRetailPrice decimal(18,2)
      ,TypicalWeightPerUnit decimal(18,3)
      ,MarketingComments nvarchar(max)
      ,InternalComments nvarchar(max)
      ,CountryOfManufacture nvarchar(max)
      ,[Range] nvarchar(max)
      ,Shelflife nvarchar(max) )


INSERT INTO ods.StockItem
		SELECT  StockItemID, StockItemName ,SupplierID ,ColorID ,UnitPackageID ,OuterPackageID
,Brand ,Size ,LeadTimeDays ,QuantityPerOuter ,IsChillerStock ,Barcode ,TaxRate ,
UnitPrice,RecommendedRetailPrice,TypicalWeightPerUnit ,MarketingComments  ,InternalComments, JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
JSON_VALUE(CustomFields, '$.Range') AS 'Range', JSON_VALUE(CustomFields, '$.Range') AS Shelflife
FROM Warehouse.StockItems

SELECT * FROM ods.StockItem

--23.	Rewrite your stored procedure in (21). Now with a given date, it should wipe out all the order data prior to
--the input date and load the order data that was placed in the next 7 days following the input date.

DROP PROCEDURE IF EXISTS orderofdate 
GO
CREATE PROCEDURE orderofdate
AS 
BEGIN
	SET NOCOUNT ON;
	BEGIN TRAN
 
		INSERT INTO ods.Orders(orderID,customerID,OrderDate,order_total)
		SELECT  so.OrderID,sc.CustomerID, so.OrderDate,SUM((sl.UnitPrice * sl.Quantity)) AS Total
		FROM Sales.OrderLines AS sl
		JOIN Sales.Orders AS so
		ON so.OrderID = sl.OrderID
		JOIN Sales.Customers AS sc
		ON sc.CustomerID = so.CustomerID						
		GROUP BY sc.CustomerID, so.OrderID, so.OrderDate
		
		DECLARE @orderdate date = '2013-01-01'
		SELECT TOP 7 * FROM ods.Orders WHERE OrderDate > @orderdate
		--GROUP BY OrderDate
		ORDER BY OrderDate
		COMMIT TRAN
	END

orderofdate

-- 24
{
   "PurchaseOrders":[
      {
		"StockItemID":"",
         "StockItemName":"Panzer Video Game",
         "SupplierID":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "SupplierID":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}


--Looks like that it is our missed purchase orders. Migrate these data into Stock Item, 
--Purchase Order and Purchase Order Lines tables. Of course, save the script.



DECLARE @json NVARCHAR(4000) = N'{ 

            "PurchaseOrders" : [
            { 
			"StockItemID":"220",
			"StockItemName":"Panzer Video Game_01", 
             "SupplierID":"7", 
            "UnitPackageId":"1",, 
			"OuterPackageId" : "6",
			"Brand":"EA Sports",
			"LeadTimeDays":"5",
			"QuantityPerOuter":"1",
			 "TaxRate":"6",
			 "UnitPrice":"59.99",
			 "RecommendedRetailPrice":"69.99",
			          "TypicalWeightPerUnit":"0.5",
		            "CustomFields" : [
            { "CountryOfManufacture" : Canada, "Range" : "Adult" } ],
         "OrderDate":"2018-01-01",
         "DeliveryMethodID":"1",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"

			},
            { 
			"StockItemID":"221",
			"StockItemName":"Panzer Video Game_02", 
             "SupplierID":"7", 
            "UnitPackageId":"1",, 
			"OuterPackageId" : "7",
			"Brand":"EA Sports",
			"LeadTimeDays":"5",
			"QuantityPerOuter":"1",
			 "TaxRate":"6",
			 "UnitPrice":"59.99",
			 "RecommendedRetailPrice":"69.99",
			   "TypicalWeightPerUnit":"0.5",
		            "CustomFields" : [
            { "CountryOfManufacture" : Canada, "Range" : "Adult" } ],
         "OrderDate":"2018-01-01",
         "DeliveryMethodID":"1",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"

			},
                  {
				  "StockItemID":"58",
         "StockItemName":"Panzer Video Game_03",
         "SupplierID":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
		            "CustomFields" : [
            { "CountryOfManufacture" : Canada, "Range" : "Adult" } ],
         "OrderDate":"2018-01-025",
         "DeliveryMethodID":"1",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }

        ]

}';

GO

SELECT * INTO mystocktable1
FROM OPENJSON(@json, '$.PurchaseOrders')
WITH  (
        StockItemID     int             '$.StockItemID',  
        StockItemName  nvarchar(100)     '$.StockItemName', 
        SupplierID       int      '$.SupplierID', 
		UnitPackageID     int             '$.UnitPackageID',  
        OuterPackageID  int     '$.OuterPackageID', 
        Brand       nvarchar(50)      '$.Brand',
		LeadTimeDays	int			'$.LeadTimeDays',
		QuantityPerOuter int		'$.QuantityPerOuter',
		TaxRate	decimal(18,3)		'$.TaxRate',
		UnitPrice decimal(18,3)		'$.UnitPrice',
		RecommendedRetailPrice decimal(18,2)		'$.RecommendedRetailPrice',
		TypicalWeightPerUnit decimal(18,3)		'$.TypicalWeightPerUnit',
        CustomFields      nvarchar(max)   '$' AS JSON ,
		OrderDate date '$.OrderDate',
		DeliveryMethodID int '$.DeliveryMethodID',
		ExpectedDeliveryDate	date '$.ExpectedDeliveryDate',
		SupplierReference  nvarchar(20)   '$.SupplierReference'

    );

--25	Revisit your answer in (19). Convert the result in JSON string and 
--save it to the server using TSQL FOR JSON PATH.

DROP VIEW IF EXISTS Sales.Quantity20132017
GO
CREATE VIEW Sales.Quantity20132017 AS
SELECT * from(
SELECT  wg.StockGroupName StockGroupName,sl.Quantity AS Quantity,YEAR(so.OrderDate) AS 'year'
FROM Sales.Orders so
JOIN Sales.OrderLines sl ON so.OrderID = sl.OrderID
JOIN Warehouse.StockItemStockGroups ws ON sl.StockItemID = ws.StockItemID
JOIN Warehouse.StockGroups wg ON ws.StockGroupID = wg.StockGroupID
GROUP BY YEAR(so.OrderDate), wg.StockGroupName, sl.Quantity
) temp_table2
pivot
(SUM(Quantity)
for StockGroupName in([Clothing],[Computing Novelties],[Furry Footwear],[Mugs],[Novelty Items],[Packing Materials],[Toys],[T-Shirts],[USB Novelties]))
pivot_table

SELECT  
       [Clothing] AS Clothing, 
	   [Computing Novelties] AS [Computing Novelties], 
	   [Furry Footwear] AS [Furry Footwear], 
	   [Mugs] AS Mugs,
	   [Novelty Items] AS [Novelty Items],
	   [Packing Materials] AS [Packing Materials], 
	   [Toys] AS [Toys], 
	   [T-Shirts] AS [TShirts],
	   [USB Novelties] AS [USB_Novelties]
FROM (SELECT * FROM Sales.Quantity20132017) AS SQ
FOR JSON PATH, ROOT('Total_Quantity')

--26.	Revisit your answer in (19). 
--Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.

DROP VIEW IF EXISTS Sales.Quantity20132017
GO
CREATE VIEW Sales.Quantity20132017 AS
SELECT * from(
SELECT  wg.StockGroupName StockGroupName,sl.Quantity AS Quantity,YEAR(so.OrderDate) AS 'year'
FROM Sales.Orders so
JOIN Sales.OrderLines sl ON so.OrderID = sl.OrderID
JOIN Warehouse.StockItemStockGroups ws ON sl.StockItemID = ws.StockItemID
JOIN Warehouse.StockGroups wg ON ws.StockGroupID = wg.StockGroupID
GROUP BY YEAR(so.OrderDate), wg.StockGroupName, sl.Quantity
) temp_table2
pivot
(SUM(Quantity)
for StockGroupName in([Clothing],[Computing Novelties],[Furry Footwear],[Mugs],[Novelty Items],[Packing Materials],[Toys],[T-Shirts],[USB Novelties]))
pivot_table

SELECT  
       [Clothing] AS Clothing, 
	   [Computing Novelties] AS Computing_Novelties, 
	   [Furry Footwear] AS Furry_Footwear, 
	   [Mugs] AS Mugs,
	   [Novelty Items] AS Novelty_Items,
	   [Packing Materials] AS Packing_Materials, 
	   [Toys] AS Toys, 
	   [T-Shirts] AS TShirts,
	   [USB Novelties] AS USB_Novelties
FROM (SELECT * FROM Sales.Quantity20132017) AS SQ
FOR XML PATH, ROOT('Total_Quantity_2')

-- 27.	Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . 
--Create a stored procedure, input is a date. The logic would load invoice information
--(all columns) as well as invoice line information (all columns) and forge them into a JSON string 
--and then insert into the new table just created. Then write a query to 
--run the stored procedure for each DATE that customer id 1 got something delivered to him.

DROP TABLE IF EXISTS ods.ConfirmDeliveryJason
GO
CREATE TABLE ods.ConfirmedDeviveryJson (
[ID] int
[date] date
[value] int)

DROP PROC IF EXISTS 
GO
CREATE PROC 