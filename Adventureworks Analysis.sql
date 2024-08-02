--1. Show Each Country's sales by customer age group

with sales_by_country_cte as (
select EnglishCountryRegionName,datediff(MONTH,BirthDate,GETDATE())/12 as Age, SalesOrderNumber
from AdventureWorksDW2022..FactInternetSales i
join AdventureWorksDW2022..DimCustomer c
on i.CustomerKey = c.CustomerKey
join AdventureWorksDW2022..DimGeography g
on i.SalesTerritoryKey = g.SalesTerritoryKey )


select EnglishCountryRegionName,
case when Age < 40 then 'Below 40'
	when age between 40 and 50 then 'Between 40 to 50'
	when age between 50 and 60 then 'Between 50 to 60'
	when age > 60 then 'Sr Citizen'
	else 'other'
	end as Age_group,
count(SalesOrderNumber) as Sales
from sales_by_country_cte
group by EnglishCountryRegionName,
case when Age < 40 then 'Below 40'
	when age between 40 and 50 then 'Between 40 to 50'
	when age between 50 and 60 then 'Between 50 to 60'
	when age > 60 then 'Sr Citizen'
	else 'other'
	end
order by EnglishCountryRegionName,Age_group ;

-- 2.Show each product sales by age group

with Product_sales_cte as (
select EnglishProductSubcategoryName, datediff(month,BirthDate,getdate())/12 as Age, SalesOrderNumber 
from AdventureWorksDW2022..FactInternetSales i
join AdventureWorksDW2022..DimCustomer c
on i.CustomerKey = c.CustomerKey
join AdventureWorksDW2022..DimProduct p
on i.ProductKey = p.ProductKey
join AdventureWorksDW2022..DimProductSubcategory s
on p.ProductSubcategoryKey = s.ProductCategoryKey)

select EnglishProductSubcategoryName as Product,
case when Age < 40 then 'Below 40'
	when age between 40 and 50 then 'Between 40 to 50'
	when age between 50 and 60 then 'Between 50 to 60'
	when age > 60 then 'Sr Citizen'
	else 'other'
	end as Age_group,
count(salesordernumber) as Sales
from Product_sales_cte
group by EnglishProductSubcategoryName,
case when Age < 40 then 'Below 40'
	when age between 40 and 50 then 'Between 40 to 50'
	when age between 50 and 60 then 'Between 50 to 60'
	when age > 60 then 'Sr Citizen'
	else 'other'
	end
order by EnglishProductSubcategoryName, Age_group ;

-- 3. Monthly Sales of USA vs Monthly Sales of Australia

select substring(cast(orderdatekey as varchar),1,6) as monthkey, SalesOrderNumber, OrderDate, SalesTerritoryCountry
from AdventureWorksDW2022..FactInternetSales i
join AdventureWorksDW2022..DimSalesTerritory s
on i.SalesTerritoryKey = s.SalesTerritoryKey
where SalesTerritoryCountry in ('united states','australia')
and substring(cast(OrderDateKey as varchar),1,4) = 2012 ;


-- 4. Display each products first reorder date

with main_cte as (
select EnglishProductName, SafetyStockLevel, ReorderPoint, OrderDateKey, sum(OrderQuantity) as Sales
from AdventureWorksDW2022..DimProduct p
join AdventureWorksDW2022..FactInternetSales i
on p.ProductKey = i.ProductKey
group by EnglishProductName, SafetyStockLevel, ReorderPoint, OrderDateKey),

reorder_cte as (
select *,
case when (safetystocklevel - running_total_sales) <= reorderpoint then 1 else 0 end as reorder_flag 
from
(select *, sum(sales) over (partition by englishproductname order by orderdatekey) as Running_total_sales
from main_cte
group by EnglishProductName, SafetyStockLevel, ReorderPoint, OrderDateKey, Sales) as main_sq
)

select EnglishProductName, min(orderdatekey) as first_reorder_date
from reorder_cte
group by EnglishProductName ;

-- 5. Products with high stock level

with main_cte as (
select EnglishProductName, SafetyStockLevel, ReorderPoint, OrderDateKey, sum(OrderQuantity) as Sales
from AdventureWorksDW2022..DimProduct p
join AdventureWorksDW2022..FactInternetSales i
on p.ProductKey = i.ProductKey
group by EnglishProductName, SafetyStockLevel, ReorderPoint, OrderDateKey),

reorder_cte as (
select *,
case when (safetystocklevel - running_total_sales) <= reorderpoint then 1 else 0 end as reorder_flag 
from
(select *, sum(sales) over (partition by englishproductname order by orderdatekey) as Running_total_sales
from main_cte
group by EnglishProductName, SafetyStockLevel, ReorderPoint, OrderDateKey, Sales) as main_sq
)

select EnglishProductName, max(product_first_orderdate) as product_first_orderdate, max(first_reorder_date) as first_reorder_date,
  datediff(day,max(cast(cast(product_first_orderdate as varchar) as date)),max(cast(cast(first_reorder_date as varchar) as date))) as days_reorder
from (select EnglishProductName, min(orderdatekey) as product_first_orderdate, null as first_reorder_date
from main_cte 
group by EnglishProductName
union all
select EnglishProductName, null as product_first_orderdate, min(orderdatekey) as first_reorder_date
from reorder_cte
group by EnglishProductName) as sq
group by EnglishProductName ;

-- 6. Sales on Promotion

select OrderDate, i.SalesOrderNumber, SalesReasonName, SalesAmount,round((SalesAmount * 0.75),2) as 'sales amount after 25% discount'
from AdventureWorksDW2022..FactInternetSales i
join AdventureWorksDW2022..FactInternetSalesReason r
on i.SalesOrderNumber = r.SalesOrderNumber
join AdventureWorksDW2022..DimSalesReason sr
on r.SalesReasonKey = sr.SalesReasonKey
where SalesReasonName = 'on promotion';

-- 7. Change in value between customer's first and last order


with first_purchase as (
select OrderDateKey,i.CustomerKey, SalesAmount,
ROW_NUMBER() over (partition by i.customerkey order by orderdatekey) as purchase_number
from DimCustomer c
join AdventureWorksDW2022..FactInternetSales i
on c.CustomerKey= i.CustomerKey ),

last_purchase as (
select OrderDateKey,i.CustomerKey, SalesAmount,
ROW_NUMBER() over (partition by i.customerkey order by orderdatekey desc) as purchase_number
from DimCustomer c
join AdventureWorksDW2022..FactInternetSales i
on c.CustomerKey= i.CustomerKey )

select customerkey,sum(first_purchase_value) as first_purchase_value, sum(last_purchase_value) as last_purchase_value, (sum(last_purchase_value) - sum(first_purchase_value)) as Change,
case when (sum(last_purchase_value) - sum(first_purchase_value)) > 0 then 'Positive'
	else 'Negetive'
	end as Performance
from
(select CustomerKey, SalesAmount as first_purchase_value, null as last_purchase_value
from first_purchase 
where purchase_number = 1 
union all
select CustomerKey, null as first_purchase_value, SalesAmount as last_purchase_value
from last_purchase
where purchase_number = 1) as mainsq
group by customerkey
having (sum(last_purchase_value) - sum(first_purchase_value)) <> 0
order by CustomerKey 