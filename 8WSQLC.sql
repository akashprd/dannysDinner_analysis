use 8WSQLC;

show tables;

+------------------+
| Tables_in_8wsqlc |
+------------------+
| members          |
| menu             |
| sales            |
+------------------+

select * from members;

+-------------+------------+
| customer_id | join_date  |
+-------------+------------+
| A           | 2021-01-07 |
| B           | 2021-01-09 |
+-------------+------------+


select * from menu;

+------------+--------------+-------+
| product_id | product_name | price |
+------------+--------------+-------+
|          1 | sushi        |    10 |
|          2 | curry        |    15 |
|          3 | ramen        |    12 |
+------------+--------------+-------+


select * from sales;

+-------------+------------+------------+
| customer_id | order_date | product_id |
+-------------+------------+------------+
| A           | 2021-01-01 |          1 |
| A           | 2021-01-01 |          2 |
| A           | 2021-01-07 |          2 |
| A           | 2021-01-10 |          3 |
| A           | 2021-01-11 |          3 |
| A           | 2021-01-11 |          3 |
| B           | 2021-01-01 |          2 |
| B           | 2021-01-02 |          2 |
| B           | 2021-01-04 |          1 |
| B           | 2021-01-11 |          1 |
| B           | 2021-01-16 |          3 |
| B           | 2021-02-01 |          3 |
| C           | 2021-01-01 |          3 |
| C           | 2021-01-01 |          3 |
| C           | 2021-01-07 |          3 |
+-------------+------------+------------+


-- 1. What is the total amount each customer spent at the restaurant?


SELECT s.customer_id, SUM(m.price) as total_amount_spent
FROM SALES s JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;
 
+-------------+--------------------+
| customer_id | total_amount_spent |
+-------------+--------------------+
| A           |                 76 |
| B           |                 74 |
| C           |                 36 |
+-------------+--------------------+



-- 2. How many days has each customer visited the restaurant?


SELECT customer_id, COUNT(DISTINCT order_date) as total_visit
FROM SALES
GROUP BY customer_id;

+-------------+-------------+
| customer_id | total_visit |
+-------------+-------------+
| A           |           4 |
| B           |           6 |
| C           |           2 |
+-------------+-------------+



-- 3. What was the first item from the menu purchased by each customer?


-- finding out row number based on the purchase date
SELECT *,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as order_rank 
FROM sales;

+-------------+------------+------------+------------+
| customer_id | order_date | product_id | order_rank |
+-------------+------------+------------+------------+
| A           | 2021-01-01 |          1 |          1 |
| A           | 2021-01-01 |          2 |          2 |
| A           | 2021-01-07 |          2 |          3 |
| A           | 2021-01-10 |          3 |          4 |
| A           | 2021-01-11 |          3 |          5 |
| A           | 2021-01-11 |          3 |          6 |
| B           | 2021-01-01 |          2 |          1 |
| B           | 2021-01-02 |          2 |          2 |
| B           | 2021-01-04 |          1 |          3 |
| B           | 2021-01-11 |          1 |          4 |
| B           | 2021-01-16 |          3 |          5 |
| B           | 2021-02-01 |          3 |          6 |
| C           | 2021-01-01 |          3 |          1 |
| C           | 2021-01-01 |          3 |          2 |
| C           | 2021-01-07 |          3 |          3 |
+-------------+------------+------------+------------+

--main code

WITH first_order AS(
    select *,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as order_rank 
    FROM sales
    )
SELECT fo.customer_id, mn.product_name
FROM first_order fo JOIN menu mn
ON fo.product_id = mn.product_id
WHERE order_rank = 1;

+-------------+--------------+
| customer_id | product_name |
+-------------+--------------+
| A           | sushi        |
| B           | curry        |
| C           | ramen        |
+-------------+--------------+



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT customer_id, product_id, count(product_id)
FROM SALES
WHERE product_id = (SELECT product_id FROM SALES GROUP BY 1 ORDER BY COUNT(product_id) DESC LIMIT 1)
GROUP BY 1,2;

+-------------+------------+-------------------+
| customer_id | product_id | count(product_id) |
+-------------+------------+-------------------+
| A           |          3 |                 3 |
| B           |          3 |                 2 |
| C           |          3 |                 3 |
+-------------+------------+-------------------+



-- 5. Which item was the most popular for each customer?


WITH sales_result AS(
    SELECT customer_id, PRODUCT_ID, COUNT(product_id) as sales_count,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) as SALES_RANK
    FROM SALES
    GROUP BY 1, 2
    )
SELECT sr.customer_id, mnu.product_name
FROM sales_result sr JOIN menu mnu
ON sr.product_id = mnu.product_id
WHERE SALES_RANK = 1
ORDER BY sr.customer_id;

+-------------+--------------+
| customer_id | product_name |
+-------------+--------------+
| A           | ramen        |
| B           | curry        |
| C           | ramen        |
+-------------+--------------+



-- 6. Which item was purchased first by the customer after they became a member?


WITH ord_rank as(
    SELECT S1.customer_id, S1.product_id,
    RANK() OVER(PARTITION BY s1.customer_id ORDER BY s1.order_date) as order_rank
    FROM Sales S1 JOIN Members M1
    ON S1.customer_id = M1.customer_id
    AND S1.order_date > M1.join_date
    )
SELECT O1.customer_id, M2.product_name
FROM ord_rank O1 JOIN menu M2
ON O1.product_id = M2.product_id
WHERE order_rank = 1
ORDER BY O1.customer_id;

+-------------+--------------+
| customer_id | product_name |
+-------------+--------------+
| A           | ramen        |
| B           | sushi        |
+-------------+--------------+


 
-- 7. Which item was purchased just before the customer became a member?


WITH last_ord_rank AS(
    SELECT S1.customer_id, S1.product_id,
    ROW_NUMBER() OVER(PARTITION BY s1.customer_id ORDER BY s1.order_date DESC) as order_rank
    FROM Sales S1 JOIN Members M1
    ON S1.customer_id = M1.customer_id
    AND S1.order_date < M1.join_date
    )
SELECT LOR.customer_id, M2.product_name
FROM last_ord_rank LOR JOIN menu M2
ON LOR.product_id = M2.product_id
WHERE order_rank = 1;

+-------------+--------------+
| customer_id | product_name |
+-------------+--------------+
| A           | sushi        |
| B           | sushi        |
+-------------+--------------+



-- 8. What is the total items and amount spent for each member before they became a member?


-- visit before becoming a member

SELECT S1.customer_id, S1.order_date,S1.product_id 
FROM SALES S1 JOIN MEMBERS M1
ON S1.customer_id = M1.customer_id
WHERE S1.order_date < M1.join_date;

+-------------+------------+------------+
| customer_id | order_date | product_id |
+-------------+------------+------------+
| A           | 2021-01-01 |          1 |
| A           | 2021-01-01 |          2 |
| B           | 2021-01-01 |          2 |
| B           | 2021-01-02 |          2 |
| B           | 2021-01-04 |          1 |
+-------------+------------+------------+

-- main code

WITH total_order AS(
     SELECT S1.customer_id, S1.order_date,S1.product_id 
     FROM SALES S1 JOIN MEMBERS M1
     ON S1.customer_id = M1.customer_id
     WHERE S1.order_date < M1.join_date
     )
SELECT T1.customer_id ,COUNT(T1.product_id) as item_count , SUM(M2.price) as total_sale_before_membership
FROM total_order T1 JOIN MENU M2
ON T1.product_id = M2.product_id
GROUP BY 1
ORDER BY T1.customer_id;

+-------------+------------+------------------------------+
| customer_id | item_count | total_sale_before_membership |
+-------------+------------+------------------------------+
| A           |          2 |                           25 |
| B           |          3 |                           40 |
+-------------+------------+------------------------------+



-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


-- finding out points for each menu item

select *,
    CASE 
        WHEN product_id =1 THEN  price*20
        ELSE price*10
    END as points
FROM MENU;

+------------+--------------+-------+--------+
| product_id | product_name | price | points |
+------------+--------------+-------+--------+
|          1 | sushi        |    10 |    200 |
|          2 | curry        |    15 |    150 |
|          3 | ramen        |    12 |    120 |
+------------+--------------+-------+--------+

--final join with sales table to find the total sum

WITH menu_points as(
    select *,
    CASE 
        WHEN product_id =1 THEN  price*20
        ELSE price*10
    END as points
    FROM MENU
    )
SELECT S1.customer_id, SUM(M1.points) as total_points
FROM sales S1 JOIN menu_points M1
ON S1.product_id = M1.product_id
GROUP BY S1.customer_id;

+-------------+--------------+
| customer_id | total_points |
+-------------+--------------+
| A           |          860 |
| B           |          940 |
| C           |          360 |
+-------------+--------------+



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- finding out points for each item

SELECT s.*, m.product_name, m.price, m.price*20 as points from sales s JOIN menu m
ON s.product_id = m.product_id;
+-------------+------------+------------+--------------+-------+--------+
| customer_id | order_date | product_id | product_name | price | points |
+-------------+------------+------------+--------------+-------+--------+
| A           | 2021-01-01 |          1 | sushi        |    10 |    200 |
| A           | 2021-01-01 |          2 | curry        |    15 |    300 |
| A           | 2021-01-07 |          2 | curry        |    15 |    300 |
| A           | 2021-01-10 |          3 | ramen        |    12 |    240 |
| A           | 2021-01-11 |          3 | ramen        |    12 |    240 |
| A           | 2021-01-11 |          3 | ramen        |    12 |    240 |
| B           | 2021-01-01 |          2 | curry        |    15 |    300 |
| B           | 2021-01-02 |          2 | curry        |    15 |    300 |
| B           | 2021-01-04 |          1 | sushi        |    10 |    200 |
| B           | 2021-01-11 |          1 | sushi        |    10 |    200 |
| B           | 2021-01-16 |          3 | ramen        |    12 |    240 |
| B           | 2021-02-01 |          3 | ramen        |    12 |    240 |
| C           | 2021-01-01 |          3 | ramen        |    12 |    240 |
| C           | 2021-01-01 |          3 | ramen        |    12 |    240 |
| C           | 2021-01-07 |          3 | ramen        |    12 |    240 |
+-------------+------------+------------+--------------+-------+--------+

--finding out visits till the next week of joining after becoming a member

SELECT S1.customer_id, S1.order_date, S1.product_id, M1.join_date
FROM SALES S1 JOIN MEMBERS M1
ON S1.customer_id = M1.customer_id
WHERE S1.order_date BETWEEN M1.join_date AND DATE_ADD(M1.join_date, INTERVAL 7 DAY)
ORDER BY 1,2;

+-------------+------------+------------+------------+
| customer_id | order_date | product_id | join_date  |
+-------------+------------+------------+------------+
| A           | 2021-01-07 |          2 | 2021-01-07 |
| A           | 2021-01-10 |          3 | 2021-01-07 |
| A           | 2021-01-11 |          3 | 2021-01-07 |
| A           | 2021-01-11 |          3 | 2021-01-07 |
| B           | 2021-01-11 |          1 | 2021-01-09 |
| B           | 2021-01-16 |          3 | 2021-01-09 |
+-------------+------------+------------+------------+

-- main solution

WITH saleIn_Jan AS(
    SELECT S1.customer_id, S1.order_date, S1.product_id, M1.join_date
    FROM SALES S1 JOIN MEMBERS M1
    ON S1.customer_id = M1.customer_id
    WHERE S1.order_date BETWEEN M1.join_date AND DATE_ADD(M1.join_date, INTERVAL 7 DAY)
    ORDER BY 1,2
    )
SELECT S2.customer_id, SUM(price*20) as points
FROM saleIn_Jan S2 JOIN menu M2
ON S2.product_id = M2.product_id
GROUP BY 1
ORDER BY 1;

+-------------+--------+
| customer_id | points |
+-------------+--------+
| A           |   1020 |
| B           |    440 |
+-------------+--------+
