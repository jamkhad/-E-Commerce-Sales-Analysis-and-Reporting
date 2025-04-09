CREATE DATABASE kofo_project

--Project Tasks and Key Requirements 
--1. Data Preparation and Setup 
--• Create the Database: Write SQL scripts to create the tables and relationships.
CREATE DATABASE sql_capstone

CREATE TABLE customers(
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR (100)NOT NULL,
    age INT,
    gender VARCHAR (10),
    country VARCHAR (50),
    email VARCHAR (100)UNIQUE,
    date_joined DATE
);

CREATE TABLE products(
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(100),
    sub_category  VARCHAR(100),
    unit_price DECIMAL(10,2),
    unit_cost DECIMAL(10,2)
);

CREATE TABLE orders(
    order_id INT PRIMARY KEY,
    customer_id INT FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    order_date DATE,
    order_status VARCHAR(100),
    payment_method VARCHAR(100),
    shipping_address VARCHAR(100)
);

CREATE TABLE order_items(
    order_item_id INT PRIMARY KEY,
    order_id  INT FOREIGN KEY (order_id) REFERENCES orders(order_id),
    product_id INT FOREIGN KEY (product_id) REFERENCES products(product_id),
    quantity INT,
    total_price INT
);


CREATE TABLE transactions(
    transaction_id INT PRIMARY KEY,
    order_id INT FOREIGN KEY (order_id) REFERENCES orders(order_id),
    transaction_date DATE,
    amount_paid INT,
    payment_status VARCHAR(20)
);

--2. Basic Data Exploration 
--• Retrieve the total number of customers, products, orders, and transactions. 

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM transactions

--• Find the earliest and latest order dates in the database.

SELECT MAX(order_date) AS [latest order date] , MIN(order_date) AS [earliest order date] FROM orders

--Calculate the total revenue, total cost, and profit for all orders.

SELECT SUM(order_items.quantity* products.unit_price) AS [Total revenue],
SUM(products.unit_cost * order_items.quantity) AS[Total cost],
SUM(order_items.quantity*products.unit_price) - SUM(products.unit_cost * order_items.quantity) AS [Profit]
FROM order_items
JOIN products
ON order_items.product_id= products.product_id

--3. Customer Analysis 
--• Demographic Breakdown: Count of customers by gender and country. 

SELECT gender,count(gender) as [customers by gender]
FROM customers 
GROUP BY gender
order by count(gender)

--Group customers into age segments (e.g., 18-25, 26-35, etc.) and find 
--the average order count and average spend per segment. 

SELECT 
CASE 
        WHEN age <=25 THEN'18-25'
        WHEN age <=35 THEN '26-35'
        WHEN age <=50 THEN '36-50'
        ELSE '50+'
END AS Age_segments,
COUNT(distinct orders.order_id) AS [average order count ],
AVG(order_items.quantity*products.unit_price) AS [average spend per segment]
FROM customers
JOIN orders ON orders.order_id=orders.customer_id
JOIN order_items on order_items.order_id = order_items.order_id
JOIN products ON order_items.product_id = products.product_id
GROUP BY age



--Top Customers: Identify the top 10 customers by total spend and by total orders placed. 

SELECT TOP 10 customer_name,SUM(order_items.quantity*products.unit_price) AS [total spend],COUNT(order_date) AS [total order]
FROM customers
JOIN orders ON orders.customer_id= customers.customer_id
JOIN order_items ON order_items.order_id=orders.order_id
JOIN products ON order_items.product_id = products.product_id
GROUP BY customer_name
ORDER BY [total spend] DESC

--4. Product Analysis 
--• Top Products: List the top 10 products by total quantity sold and by revenue.

SELECT TOP 10 product_name,SUM(quantity) AS [total quantity], 
SUM(order_items.total_price) AS [revenue]
FROM products
JOIN order_items ON order_items.product_id= products.product_id
GROUP BY product_name
ORDER BY [revenue] DESC

--Product Category Analysis: Calculate total revenue, profit, and quantity sold by each product 
--category and sub-category. 

SELECT category,sub_category,SUM(total_price)  AS [total revenue],
SUM(total_price) - SUM(products.unit_cost * order_items.quantity) AS [profit]
FROM products
JOIN order_items ON order_items.product_id = products.product_id
GROUP BY category,sub_category
ORDER BY [total revenue] DESC

--Low-Performing Products: Identify products that have not been sold in the last 6 months.

SELECT * FROM products
WHERE product_id NOT IN(
                         SELECT DISTINCT order_items.product_id 
                         FROM order_items 
                         JOIN orders ON order_items.order_id =orders.order_id
                         WHERE order_date >=DATEADD(MONTH,-6,GETDATE())
)                             
                                            
--5. Order Analysis 
--• Order Status Summary: Count of orders by status (Completed, Pending, Canceled).

SELECT count(*) AS [count of orders], order_status FROM orders
GROUP BY order_status
ORDER BY count(*)

--• Payment Methods Analysis: Count of orders by payment method, and percentage of total.

SELECT 
COUNT(order_id) AS [Count of orders],
payment_status,
(COUNT(order_id))*100.0 /SUM((COUNT(order_id)))*100.0 AS [percentage of total]
FROM transactions
GROUP BY payment_status


--Monthly Sales Trend: 
--Calculate total revenue and number of orders by month to identify sales trends. 

SELECT SUM(total_price) AS [total revenue per month],
COUNT(*) AS [number of orders per month], 
DATENAME(MONTH,order_date) AS[month], DATENAME(YEAR,order_date) AS[year]
FROM order_items
JOIN orders 
ON orders.order_id = order_items.order_id
GROUP BY order_date
ORDER BY SUM(total_price) DESC

--6. Revenue and Profit Analysis 
--• Total Revenue and Profit: Calculate overall revenue and profit for completed orders. 

SELECT order_status,
SUM(total_price) AS [overall revenue], 
SUM(total_price) - SUM(products.unit_cost * order_items.quantity) AS [Profit]
FROM order_items
JOIN orders ON orders.order_id = order_items.order_id
JOIN products ON products.product_id=order_items.product_id
GROUP BY order_status
HAVING order_status IN ('completed')

--Profit by Product: Calculate profit margins by product, product category, and sub-category.

SELECT distinct product_name,category,sub_category,
((SUM(products.unit_price *order_items.quantity) - SUM(products.unit_cost * order_items.quantity))/SUM(products.unit_price *order_items.quantity))*100.0 AS [profit margin]
FROM products
JOIN order_items 
ON order_items.product_id = products.product_id
GROUP BY product_name,category,sub_category
ORDER BY [profit margin]DESC

--High-Profit Orders: Identify the top 5 orders with the highest profit margins.

SELECT TOP 5 order_date, product_name,category,
((SUM(total_price) - SUM(products.unit_cost * order_items.quantity))/SUM(total_price)) AS [profit margin]
FROM products
JOIN order_items 
ON order_items.product_id = products.product_id
JOIN orders 
ON orders.order_id = order_items.order_id
GROUP BY product_name,category,sub_category,total_price,unit_cost,quantity,order_date
ORDER BY [profit margin]DESC

--7. Transaction Analysis 
--• Payment Status: Count transactions by payment status (Paid, Pending) and calculate the amount 
--of pending revenue. 

SELECT COUNT(*) AS [Count transactions], payment_status FROM transactions
GROUP BY payment_status
ORDER BY COUNT(*)

SELECT payment_status ,SUM(amount_paid) AS [pending revenue] 
FROM transactions
GROUP BY payment_status
HAVING payment_status IN ('pending')
ORDER BY SUM(amount_paid)

--Transaction Completeness: Identify orders that do not have matching transactions (potential 
--data issue). 

--Transaction Trends: Calculate total transactions and average transaction amount by month
SELECT SUM(amount_paid) AS [total transactions],
AVG(amount_paid) AS [average transaction],
MONTH(transaction_date) AS [Month] 
FROM transactions 
GROUP BY transaction_date
ORDER BY SUM(amount_paid) DESC

--8. Advanced Insights 
--• Customer Retention: Calculate the percentage of customers who placed more than one order.
SELECT (COUNT(DISTINCT orders.customer_id)*100.0 /COUNT(*)) AS [Customer Retention Rate]
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id)> 1
ORDER BY COUNT(order_id)DESC

--Repeat Purchase Rate: Calculate the repeat purchase rate for customers. 
SELECT COUNT(*) AS [Repeat Purchase Rate],customer_name FROM orders
JOIN customers ON customers.customer_id = orders.customer_id
GROUP BY customer_name
HAVING COUNT(*) > 1

--• Cross-Category Purchases: Identify customers who have purchased products from more than 
--one category. 

SELECT COUNT(*) AS [Count of Purchases],customer_name,category FROM products
JOIN order_items ON order_items.product_id = products.product_id
JOIN orders ON orders.order_id =order_items.order_id
JOIN customers ON customers.customer_id = orders.customer_id
GROUP BY category,customer_name 
HAVING COUNT(*) > 1


SELECT * FROM customers
SELECT * FROM products
SELECT * FROM orders
SELECT * FROM order_items
SELECT * FROM transactions