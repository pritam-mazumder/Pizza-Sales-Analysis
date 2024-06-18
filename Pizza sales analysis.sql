CREATE DATABASE pizza;

USE pizza;

CREATE TABLE orders
(
    order_id   INT  NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY (order_id)
);

CREATE TABLE orders_details
(
    order_details_id INT  NOT NULL,
    order_id         INT  NOT NULL,
    pizza_id         TEXT NOT NULL,
    quantity         INT  NOT NULL,
    PRIMARY KEY (order_details_id)
);

-- Retrieve the total number of orders placed.
SELECT count(order_id) AS total_orders
FROM orders;


-- Calculate the total revenue generated from pizza sales.
SELECT round(sum(orders_details.quantity * pizzas.price), 2) AS total_revenue
FROM orders_details
         JOIN
     pizzas ON pizzas.pizza_id = orders_details.pizza_id;


-- Identify the highest-priced pizza.
SELECT pizza_types.name,
       pizzas.price
FROM pizza_types
         JOIN
     pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;


-- Identify the most common pizza size ordered.
SELECT pizzas.size,
       count(orders_details.order_details_id) AS order_count
FROM pizzas
         JOIN
     orders_details ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC;


-- List the top 5 most ordered pizza types along with their quantities.
SELECT pizza_types.name, sum(orders_details.quantity) AS ordered_quantities
FROM pizza_types
         JOIN
     pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
         JOIN
     orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY ordered_quantities DESC
LIMIT 5;


-- Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pizza_types.category,
       sum(orders_details.quantity) AS category_quantity
FROM pizza_types
         JOIN
     pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
         JOIN
     orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category;


-- Determine the distribution of orders by hour of the day.
SELECT hour(order_time),
       count(order_id) AS order_count
FROM orders
GROUP BY hour(order_time);


-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT category, count(name)
FROM pizza_types
GROUP BY category;


-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT round(avg(quantity), 0) AS average_orders_per_day
FROM (SELECT sum(orders_details.quantity) AS quantity
      FROM orders
               JOIN
           orders_details ON orders.order_id = orders_details.order_id
      GROUP BY orders.order_date) AS order_quantity;


-- Determine the top 3 most ordered pizza types based on revenue.
SELECT pizza_types.name,
       sum(orders_details.quantity * pizzas.price) AS revenue
FROM pizza_types
         JOIN
     pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
         JOIN
     orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;


-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT pizza_types.category,
       round((sum(orders_details.quantity * pizzas.price) /
              (SELECT round(sum(orders_details.quantity * pizzas.price), 2) AS total_revenue
               FROM orders_details
                        JOIN
                    pizzas ON pizzas.pizza_id = orders_details.pizza_id)) * 100, 2) AS revenue
FROM pizza_types
         JOIN
     pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
         JOIN
     orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;


-- Analyze the cumulative revenue generated over time.
SELECT order_date,
       sum(revenue) OVER (ORDER BY order_date) AS cum_revenue
FROM (SELECT orders.order_date,
             sum(orders_details.quantity * pizzas.price) AS revenue
      FROM orders_details
               JOIN
           pizzas ON pizzas.pizza_id = orders_details.pizza_id
               JOIN
           orders ON orders.order_id = orders_details.order_id
      GROUP BY orders.order_date)
         AS sales;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

SELECT name,
       revenue
FROM (SELECT category,
             name,
             revenue,
             rank() OVER (PARTITION BY category ORDER BY revenue DESC ) AS ranking
      FROM (SELECT pizza_types.category,
                   pizza_types.name,
                   sum((orders_details.quantity) * (pizzas.price)) AS revenue
            FROM pizza_types
                     JOIN pizzas
                          ON pizza_types.pizza_type_id = pizzas.pizza_type_id
                     JOIN orders_details
                          ON orders_details.pizza_id = pizzas.pizza_id
            GROUP BY pizza_types.category, pizza_types.name) AS a) AS b
WHERE ranking <= 3;