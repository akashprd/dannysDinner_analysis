-- Active: 1728903546545@@127.0.0.1@3306@8WSQLC


SHOW TABLES;

SELECT * FROM SALES;

SELECT * FROM members;

SELECT * FROM menu;


-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) as total_amount_spent
FROM SALES s JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) as total_visit
FROM SALES
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

select *,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as order_rank 
    FROM sales;

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

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- most purchased product

SELECT product_id /**, count(product_id) as most_purchased_product **/
FROM SALES
GROUP BY product_id
ORDER BY COUNT(product_id) DESC
LIMIT 1;

-- finding out no of purchase based on most purchased product
SELECT customer_id, product_id, count(product_id)
FROM SALES
WHERE product_id = (SELECT product_id FROM SALES GROUP BY 1 ORDER BY COUNT(product_id) DESC LIMIT 1)
GROUP BY 1,2;



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


-- 8. What is the total items and amount spent for each member before they became a member?


-- visit before becoming a member
SELECT S1.customer_id, S1.order_date,S1.product_id 
    FROM SALES S1 JOIN MEMBERS M1
    ON S1.customer_id = M1.customer_id
    WHERE S1.order_date < M1.join_date;

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



-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- finding out points for each menu item
select *,
    CASE 
        WHEN product_id =1 THEN  price*20
        ELSE price*10
    END as points
FROM MENU;

-- final join with sales table to find the total sum
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




-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


select s.*, m.product_name, m.price, m.price*20 as points from sales s JOIN menu m
ON s.product_id = m.product_id;

SELECT S1.customer_id, S1.order_date, S1.product_id, M1.join_date
    FROM SALES S1 JOIN MEMBERS M1
    ON S1.customer_id = M1.customer_id
    WHERE S1.order_date BETWEEN M1.join_date AND DATE_ADD(M1.join_date, INTERVAL 7 DAY)
    ORDER BY 1,2

-- main solution

WITH saleIn_Jan AS(
    SELECT S1.customer_id, S1.order_date, S1.product_id, M1.join_date
    FROM SALES S1 JOIN MEMBERS M1
    ON S1.customer_id = M1.customer_id
    WHERE S1.order_date BETWEEN M1.join_date AND DATE_ADD(M1.join_date, INTERVAL 7 DAY)
    ORDER BY 1,2)
SELECT S2.customer_id, SUM(price*20) as points
FROM saleIn_Jan S2 JOIN menu M2
ON S2.product_id = M2.product_id
GROUP BY 1
ORDER BY 1;



-- SELECT customer_id,order_date, DATE_ADD(order_date, INTERVAL 7 DAY) FROM SALES;
