CREATE TABLE IF NOT EXISTS daily_sales_summary (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    summary_date DATE NOT NULL UNIQUE,
    total_orders INT UNSIGNED NOT NULL DEFAULT 0,
    total_sold DECIMAL(12, 2) NOT NULL DEFAULT 0,
    average_ticket DECIMAL(12, 2) NOT NULL DEFAULT 0,
    top_product_id BIGINT UNSIGNED NULL,
    top_customer_id BIGINT UNSIGNED NULL,
    new_customers INT UNSIGNED NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE PROCEDURE generate_daily_sales_summary(
    IN p_date DATE
)
BEGIN
    DECLARE v_total_orders INT UNSIGNED DEFAULT 0;
    DECLARE v_total_sold DECIMAL(12, 2) DEFAULT 0;
    DECLARE v_average_ticket DECIMAL(12, 2) DEFAULT 0;
    DECLARE v_top_product_id BIGINT UNSIGNED DEFAULT NULL;
    DECLARE v_top_customer_id BIGINT UNSIGNED DEFAULT NULL;
    DECLARE v_new_customers INT UNSIGNED DEFAULT 0;

    SELECT
        COUNT(*),
        COALESCE(SUM(o.total), 0),
        COALESCE(AVG(o.total), 0)
    INTO
        v_total_orders,
        v_total_sold,
        v_average_ticket
    FROM orders o
    WHERE DATE(o.created_at) = p_date
      AND o.status = 'completed';

    SELECT oi.product_id
    INTO v_top_product_id
    FROM order_items oi
    INNER JOIN orders o
        ON o.id = oi.order_id
    WHERE DATE(o.created_at) = p_date
      AND o.status = 'completed'
    GROUP BY oi.product_id
    ORDER BY SUM(oi.quantity) DESC
    LIMIT 1;

    SELECT o.customer_id
    INTO v_top_customer_id
    FROM orders o
    WHERE DATE(o.created_at) = p_date
      AND o.status = 'completed'
    GROUP BY o.customer_id
    ORDER BY SUM(o.total) DESC
    LIMIT 1;

    SELECT COUNT(*)
    INTO v_new_customers
    FROM customers c
    WHERE DATE(c.created_at) = p_date;

    INSERT INTO daily_sales_summary (
        summary_date,
        total_orders,
        total_sold,
        average_ticket,
        top_product_id,
        top_customer_id,
        new_customers
    )
    VALUES (
        p_date,
        v_total_orders,
        v_total_sold,
        v_average_ticket,
        v_top_product_id,
        v_top_customer_id,
        v_new_customers
    )
    ON DUPLICATE KEY UPDATE
        total_orders = v_total_orders,
        total_sold = v_total_sold,
        average_ticket = v_average_ticket,
        top_product_id = v_top_product_id,
        top_customer_id = v_top_customer_id,
        new_customers = v_new_customers;

END $$

DELIMITER ;