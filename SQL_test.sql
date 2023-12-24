#1. Написать запрос, который показывает количество выполненных заказов с X SKU в заказе (шт.)

#Решение через JOIN, что быстрее
SELECT quantity_unique_SKU, COUNT(OrderID) AS number_of_orders
FROM (
  SELECT COUNT(DISTINCT(SKU)) AS quantity_unique_SKU,
  Orders.OrderID
  FROM `sbermegamarket-test.test_sql.Orders` AS Orders
  JOIN `sbermegamarket-test.test_sql.Order_list` AS Order_list 
  ON Orders.OrderID = Order_list.OrderID
  WHERE Orders.OrderState = "Fulfilled" 
  GROUP BY Orders.OrderID
) 
GROUP BY quantity_unique_SKU
ORDER BY quantity_unique_SKU

#Решение через подзапрос
SELECT quantity_unique_SKU, COUNT(*) AS number_of_orders
FROM (
  SELECT OrderID, COUNT(DISTINCT SKU) AS quantity_unique_SKU
  FROM `sbermegamarket-test.test_sql.Order_list` AS Order_List
  WHERE OrderID IN (
    SELECT OrderID
    FROM `sbermegamarket-test.test_sql.Orders` AS Orders
    WHERE OrderState = 'Fulfilled'
  )
  GROUP BY OrderID
)
GROUP BY quantity_unique_SKU
ORDER BY quantity_unique_SKU;

#2. Написать SQL-запрос, выводящий среднюю стоимость покупки (завершенный заказ) за все время клиентов из центрального региона ("Central"), 
#совершивших и получивших первую покупку в январе 2018 года. Результаты предоставить в разбивке по городам.

SELECT  cr.CityID, ROUND(AVG(ol.Quantity * ol.Price)) AS AveragePurchase
FROM `sbermegamarket-test.test_sql.Orders` o
JOIN `sbermegamarket-test.test_sql.Customers` c ON o.CustomerID = c.CustomerID
JOIN `sbermegamarket-test.test_sql.City_Region` cr ON c.CityID = cr.CityID
JOIN `sbermegamarket-test.test_sql.Order_list` ol ON o.OrderID = ol.OrderID
WHERE cr.Region = 'Central'
    AND o.OrderState = 'Fulfilled'
    AND o.DeliveryDays IS NOT NULL
    AND o.OrderDate LIKE '201801%'
    AND c.CustomerID IN (
        SELECT CustomerID
        FROM `sbermegamarket-test.test_sql.Orders`
        WHERE OrderDate LIKE '201801%'
        GROUP BY CustomerID
        HAVING MIN(OrderDate) = MAX(OrderDate)
    )
    AND CAST(CAST(OrderDate AS int64) + CAST( DeliveryDays AS int64) AS STRING) < '20180201'
GROUP BY cr.CityID

#3. По месяцам вывести топ-3 самых покупаемых (по количеству единиц товаров в выкупленных заказах) SKU. 
#Если у нескольких товаров одинаковое количество проданных единиц, то выводить все такие товары.

WITH monthly_top_skus AS (
  SELECT SUBSTR(OrderDate, 5,2) AS OrderMonth, ol.SKU, SUM(ol.Quantity) AS TotalQuantity
  FROM `sbermegamarket-test.test_sql.Orders` o
  JOIN `sbermegamarket-test.test_sql.Order_list` ol 
  ON o.OrderID = ol.OrderID
  WHERE o.OrderState = 'Fulfilled'
  GROUP BY OrderMonth, ol.SKU
)

SELECT OrderMonth, SKU
FROM (
  SELECT OrderMonth, SKU, TotalQuantity,
    ROW_NUMBER() OVER (PARTITION BY OrderMonth ORDER BY TotalQuantity DESC) AS ranking
  FROM monthly_top_skus
) t
WHERE ranking <= 3
ORDER BY OrderMonth, TotalQuantity DESC
