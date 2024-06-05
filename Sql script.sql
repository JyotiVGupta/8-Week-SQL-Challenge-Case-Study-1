-- What is the total amount each customer spent at the restaurant?

SELECT CUSTOMER_ID, SUM(PRICE)
    FROM SALES
        INNER JOIN MENU
                    ON SALES.PRODUCT_ID = MENU.PRODUCT_ID
                        GROUP BY CUSTOMER_ID


-- How many days has each customer visited the restaurant?

SELECT CUSTOMER_ID, COUNT(DISTINCT(ORDER_DATE))
    FROM SALES
        GROUP BY CUSTOMER_ID

        

-- What was the first item from the menu purchased by each customer?

SELECT DISTINCT CUSTOMER_ID, 
                FIRST_VALUE(PRODUCT_NAME) OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE )
        FROM SALES
                INNER JOIN MENU
                        ON SALES.PRODUCT_ID = MENU. PRODUCT_ID


-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT COUNT(SALES.PRODUCT_ID), PRODUCT_NAME
        FROM SALES
            INNER JOIN MENU
                    ON SALES.PRODUCT_ID = MENU. PRODUCT_ID
                        GROUP BY PRODUCT_NAME
                        ORDER BY COUNT(SALES.PRODUCT_ID) DESC
                            LIMIT 1
        

-- Which item was the most popular for each customer?

WITH C AS
(SELECT CUSTOMER_ID, Product_ID, COUNT(SALES.PRODUCT_ID) as count_number,
    DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(SALES.PRODUCT_ID) DESC) as RN
        FROM SALES
           GROUP BY CUSTOMER_ID, PRODUCT_ID)

           SELECT CUSTOMER_ID, PRODUCT_NAME, count_number 
                FROM C
                    INNER JOIN MENU
                             ON C.PRODUCT_ID = MENU. PRODUCT_ID
                                WHERE rn = 1


-- Which item was purchased first by the customer after they became a member?


WITH C AS (
            SELECT SALES.CUSTOMER_ID, PRODUCT_ID, ORDER_DATE, JOIN_DATE,
                CASE 
                    WHEN JOIN_DATE > ORDER_DATE 
                        THEN  0
                    WHEN JOIN_DATE <= ORDER_DATE 
                        THEN 1
                                    END as when_order,
                    DENSE_RANK () OVER (PARTITION BY SALES.CUSTOMER_ID ORDER BY ORDER_DATE ASC) as rn
                                        FROM SALES 
                                            INNER JOIN MEMBERS
                                                    ON SALES.CUSTOMER_ID = MEMBERS.CUSTOMER_ID
                                                            WHERE when_order = 1

)
            SELECT C.CUSTOMER_ID, C.PRODUCT_ID, PRODUCT_NAME
                         FROM C 
                                     INNER JOIN MENU
                                              ON C.PRODUCT_ID= MENU.PRODUCT_ID
                                                   WHERE rn=1

-- Which item was purchased just before the customer became a member?

WITH C AS (
            SELECT SALES.CUSTOMER_ID, PRODUCT_ID, ORDER_DATE, JOIN_DATE,
                 CASE 
                    WHEN JOIN_DATE > ORDER_DATE 
                        THEN  0
                    WHEN JOIN_DATE <= ORDER_DATE 
                        THEN 1
                            END as when_order,
                    DENSE_RANK () OVER (PARTITION BY SALES.CUSTOMER_ID ORDER BY ORDER_DATE DESC) as rn
                                FROM SALES 
                                     INNER JOIN MEMBERS
                                                ON SALES.CUSTOMER_ID = MEMBERS.CUSTOMER_ID
                                                        WHERE when_order = 0

)
    SELECT C.CUSTOMER_ID, C.PRODUCT_ID, PRODUCT_NAME
                    FROM C 
                        INNER JOIN MENU
                                 ON C.PRODUCT_ID= MENU.PRODUCT_ID
                                     WHERE rn=1


-- What is the total items and amount spent for each member before they became a member?

WITH C AS (
    SELECT SALES.CUSTOMER_ID, PRODUCT_ID, ORDER_DATE, JOIN_DATE,
        CASE 
            WHEN JOIN_DATE > ORDER_DATE 
                THEN  0
            WHEN JOIN_DATE <= ORDER_DATE 
                THEN 1
                    END as when_order,
        DENSE_RANK () OVER (PARTITION BY SALES.CUSTOMER_ID ORDER BY ORDER_DATE DESC) as rn
             FROM SALES 
                     INNER JOIN MEMBERS
                             ON SALES.CUSTOMER_ID = MEMBERS.CUSTOMER_ID
                                 WHERE when_order = 0

)
SELECT C.CUSTOMER_ID, COUNT((C.PRODUCT_ID)), SUM(PRICE)
    FROM C 
    INNER JOIN MENU
            ON C.PRODUCT_ID= MENU.PRODUCT_ID
            GROUP BY C.CUSTOMER_ID


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?           

SELECT SALES.CUSTOMER_ID, 
        SUM(CASE 
             WHEN PRODUCT_NAME = 'sushi' 
                THEN  PRICE * 20
            WHEN PRODUCT_NAME != 'sushi' 
                THEN  PRICE * 10
                    END ) as Points,
         FROM SALES
                INNER JOIN MENU
                        ON SALES.PRODUCT_ID = MENU.PRODUCT_ID
                            GROUP BY CUSTOMER_ID




-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH C AS
    (SELECT SALES.CUSTOMER_ID, PRODUCT_ID, ORDER_DATE, JOIN_DATE,
                CASE 
                    WHEN DATEDIFF('days', JOIN_DATE:: DATE, ORDER_DATE ) <=7 
                        AND DATEDIFF('days', JOIN_DATE:: DATE, ORDER_DATE ) >= 0 
                            THEN 1
                    WHEN DATEDIFF('days', JOIN_DATE:: DATE, ORDER_DATE ) > 7 
                        OR  DATEDIFF('days', JOIN_DATE:: DATE, ORDER_DATE ) < 0 
                            THEN 0 
                                 END as when_order,
                 
                                        FROM SALES 
                                            INNER JOIN MEMBERS
                                                    ON SALES.CUSTOMER_ID = MEMBERS.CUSTOMER_ID)

                              SELECT C.CUSTOMER_ID,  SUM(PRICE),
                                    SUM(CASE 
                                             WHEN when_order = 1 
                                                    THEN PRICE * 20
                                             WHEN when_order = 0  and PRODUCT_NAME = 'sushi' 
                                            
                                                    THEN  PRICE * 20
                                            WHEN when_order = 0  and  PRODUCT_NAME != 'sushi' 
                                                    THEN  PRICE * 10
                                                            END ) as Points,
                                                    FROM C
                                                            INNER JOIN MENU
                                                                    ON C.PRODUCT_ID = MENU.PRODUCT_ID
                                                                         WHERE ORDER_DATE < DATE('2021-02-01' )
                                                                               GROUP BY C.CUSTOMER_ID


-- Bonus Question 1. Join all things

SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, M.PRICE, 
         CASE 
                    WHEN JOIN_DATE > ORDER_DATE 
                        OR JOIN_DATE IS NULL
                        THEN  'N'
                    WHEN JOIN_DATE <= ORDER_DATE 
                        THEN 'Y'
                            END as member,

                            FROM MENU as M
                             INNER JOIN SALES as S
                                ON S.PRODUCT_ID = M.PRODUCT_ID
                                    LEFT JOIN  MEMBERS as M2
                                            ON S. CUSTOMER_ID = M2.CUSTOMER_ID


-- Bonus Question 2. Rank all things

WITH C AS (SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, M.PRICE, 
         CASE 
                    WHEN JOIN_DATE > ORDER_DATE 
                        OR JOIN_DATE IS NULL
                        THEN  'N'
                    WHEN JOIN_DATE <= ORDER_DATE 
                        THEN 'Y'
                            END as member,
                                    FROM MENU as M
                             INNER JOIN SALES as S
                                ON S.PRODUCT_ID = M.PRODUCT_ID
                                    LEFT JOIN  MEMBERS as M2
                                            ON S. CUSTOMER_ID = M2.CUSTOMER_ID)

                                            SELECT *,
                                                    CASE WHEN member = 'N'
                                                                THEN NULL
                                                            ELSE DENSE_RANK() OVER(PARTITION BY C.CUSTOMER_ID, member ORDER BY ORDER_DATE)
                                                            END as ranking

                                                            FROM C
                                