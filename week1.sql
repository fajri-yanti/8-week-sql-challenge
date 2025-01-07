-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    s.customer_id,
    m.product_id,
    SUM(m.price) AS total_amount
FROM dannys_diner.sales s
JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_id;


-- 2. How many days has each customer visited the restaurant?
SELECT 
    s.customer_id,
    COUNT (DISTINCT s.order_date) AS total_visited
FROM dannys_diner.sales s
GROUP BY s.customer_id

-- 3. What was the first item from the menu purchased by each customer?
WITH rank_sales AS(
	SELECT 
		customer_id,
		product_id,
		DENSE_RANK() OVER(PARTITION BY product_id ORDER BY order_date) AS menu_rank
	FROM dannys_diner.sales s
)

SELECT customer_id, product_id, menu_rank
FROM rank_sales
WHERE menu_rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	m.product_name,
	s.product_id,
	COUNT (s.customer_id) AS total_purchase
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY total_purchase DESC

--  5. Which item was the most popular for each customer?
WITH fav_menu AS (
	SELECT 
		DISTINCT s.customer_id,
		m.product_name,
		DENSE_RANK() OVER(PARTITION BY m.product_id) AS rank_menu
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
)

SELECT customer_id, product_name, rank_menu
FROM fav_menu
WHERE rank_menu = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_menu_member AS (
SELECT 
	mb.customer_id, 
	s.product_id,
	s.order_date,
	RANK() OVER(PARTITION BY mb.customer_id ORDER BY order_date) AS menu
FROM dannys_diner.members mb
LEFT JOIN dannys_diner.sales s ON mb.customer_id = s.customer_id
WHERE s.order_date >= mb.join_date
)
SELECT * FROM first_menu_member WHERE menu = 1

-- 7. Which item was purchased just before the customer became a member?
WITH last_menu_before_member AS (
SELECT 
	mb.customer_id, 
	s.product_id,
	s.order_date,
	RANK() OVER(PARTITION BY mb.customer_id ORDER BY order_date DESC) AS menu_rank
FROM dannys_diner.members mb
LEFT JOIN dannys_diner.sales s ON mb.customer_id = s.customer_id
WHERE s.order_date < mb.join_date
)

SELECT * 
FROM last_menu_before_member lp
WHERE lp.menu_rank = 1

--8. What is the total items and amount spent for each member before they became a member?
WITH total_before_member AS (
SELECT 
	mb.customer_id, 
	COUNT(DISTINCT s.product_id) AS total_item,
	SUM(m.price) AS total_amount
FROM dannys_diner.members mb
LEFT JOIN dannys_diner.sales s ON mb.customer_id = s.customer_id
LEFT JOIN dannys_diner.menu m ON m.product_id = s.product_id
WHERE s.order_date < mb.join_date
GROUP BY mb.customer_id
)

SELECT * 
FROM total_before_member

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
	s.customer_id,
	SUM (
		CASE 
			WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
			ELSE m.price * 10
		END
	) AS total_points
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON m.product_id = s.product_id
GROUP BY s.customer_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH customer_points AS (
    SELECT 
        mb.customer_id,
        s.order_date,
        m.product_name,
        m.price,
        CASE
            -- Transaksi dalam minggu pertama mendapatkan 2x poin
            WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 6 DAY) THEN
                CASE
                    WHEN m.product_name = 'sushi' THEN m.price * 10 * 4
                    ELSE m.price * 10 * 2
                END
            ELSE
                CASE
                    WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
                    ELSE m.price * 10
                END
        END AS points
    FROM dannys_diner.members mb
    LEFT JOIN dannys_diner.sales s 
        ON mb.customer_id = s.customer_id
    LEFT JOIN dannys_diner.menu m
        ON s.product_id = m.product_id
    WHERE s.order_date <= '2024-01-31' 
)
SELECT 
    customer_id,
    SUM(points) AS total_points
FROM customer_points
GROUP BY customer_id;
