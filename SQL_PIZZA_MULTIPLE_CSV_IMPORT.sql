CREATE DATABASE pizzahut
use pizzahut
SELECT * FROM pizzas
SELECT * FROM order_details
SELECT * FROM orders
SELECT * FROM pizza_types
-- BASIC:
--1)Retrieve the total number of orders placed.
SELECT * FROM orders
SELECT COUNT(order_id) as total_orders FROM orders

--2)Calculate the total revenue generated from pizza sales.
SELECT  round(sum(order_details.quantity * pizzas.price),2) AS total_sales
FROM order_details JOIN pizzas 
ON  order_details.pizza_id = pizzas.pizza_id;
-- (the quantity because it represents the number of pizzas sold for each order.
--To calculate the total revenue,)

-- 3)Identify the highest-priced pizza.
SELECT TOP 1 pizza_types.name , pizzas.price
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY 
    pizzas.price DESC

-- 4)Identify the most common pizza size ordered.
SELECT quantity,count(order_details_id)
from order_details group by quantity -- most comman is quantity 1 

select pizzas.size , count(order_details.order_details_id) as order_count 
from pizzas join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizzas.size order by order_count desc

-- 5)List the top 5 most ordered pizza types along with their quantities.

select top 5 pizza_types.name, sum(order_details.quantity) as quantity
from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.name order by quantity desc

--Intermediate:
-- 6)Join the necessary tables to find the total quantity of each pizza category ordered.

select pizza_types.category , sum(order_details.quantity) as quantity
from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category order by quantity desc

--7) Determine the distribution of orders by hour of the day.

-- the HOUR() function is not recognized in the SQL dialect you're using. 
--In SQL Server, you should use the DATEPART() function to extract the hour from a datetime column.

SELECT 
    DATEPART(HOUR,time) AS order_hour, 
    COUNT(order_id) AS order_count
FROM orders
GROUP BY DATEPART(HOUR,time)
ORDER BY order_hour desc

-- 8)Join relevant tables to find the category-wise distribution of pizzas

select * from pizza_types
select category , count(name) from pizza_types
group by category

--9)Group the orders by date 
--and calculate the average number of pizzas ordered per day.

select avg(quantity) as avg_pizza_per_day
from 
	(select orders.date , sum(order_details.quantity) as quantity
	from orders join order_details
	on orders.order_id = order_details.order_id
	group by orders.date)
					as order_quantity

-- CTE
WITH order_quantity AS (
    SELECT 
        orders.date, 
        SUM(order_details.quantity) AS total_quantity
    FROM orders
    JOIN order_details
        ON orders.order_id = order_details.order_id
    GROUP BY orders.date
)
SELECT AVG(total_quantity) AS avg_pizzas_per_day
FROM order_quantity;

-- 10)Determine the top 3 most ordered pizza types based on revenue.

select top 3 pizza_types.name , sum(order_details.quantity * pizzas.price) as revenue 
from pizza_types join pizzas 
on pizzas.pizza_type_id=pizza_types.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.name order by revenue desc 

-- Advanced:
-- 11)Calculate the percentage contribution of each pizza type to total revenue.

-- percentage : (SUM(order_details.quantity * pizzas.price) / total_sales) * 100

SELECT  
    pizza_types.category, 
    ROUND((SUM(order_details.quantity * pizzas.price) / -- this part calculate the revenue for each category
        (
            SELECT ROUND(SUM(order_details.quantity * pizzas.price), 2) 
            FROM order_details 
            JOIN pizzas 
            ON pizzas.pizza_id = order_details.pizza_id
        )
    ) * 100,2)AS revenue
FROM pizza_types 
JOIN pizzas 
    ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details 
    ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category 
ORDER BY revenue DESC;


-- 12)Analyze the cumulative revenue generated over time.
--har din kitna kitna revenue generate hoke increase horaha hai 
--200 200
--300 200+300=500

SELECT 
    sales.date, 
    SUM(sales.revenue) OVER (ORDER BY sales.date) AS cum_revenue
FROM (
    SELECT 
        orders.date, 
        SUM(order_details.quantity * pizzas.price) AS revenue
    FROM order_details
    JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
    JOIN orders ON orders.order_id = order_details.order_id
    GROUP BY orders.date
) AS sales
ORDER BY sales.date;

-- 13)Determine the top 3 most ordered pizza types based on revenue for each pizza category.

select name , revenue from 
(select category , name , revenue,
rank() over (partition by category order by revenue desc) as rn
from 
(select pizza_types.category , pizza_types.name,
sum((order_details.quantity)* pizzas.price) as revenue
from pizza_types join pizzas 
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category , pizza_types.name) as a) as b
where rn<=3