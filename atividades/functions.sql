-- 1. Calcular o valor de um item do pedido

DELIMITER $$

CREATE FUNCTION calculate_item_total(
    p_product_price DECIMAL(10, 2),
    p_quantity BIGINT UNSIGNED
)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    RETURN p_product_price * p_quantity;
END$$

DELIMITER ;

SELECT
    oi.id,
    oi.product_name,
    oi.product_price,
    oi.quantity,
    calculate_item_total(oi.product_price, oi.quantity) AS item_total
FROM order_items AS oi;


-- 2. Classificar um cliente pelo total de compras

DELIMITER $$

CREATE FUNCTION customer_level(
    p_total_spent DECIMAL(10, 2)
)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    RETURN CASE
        WHEN p_total_spent < 500.00 THEN 'Bronze'
        WHEN p_total_spent <= 2000.00 THEN 'Prata'
        ELSE 'Ouro'
    END;
END$$

DELIMITER ;

SELECT
    c.id,
    c.name,
    COALESCE(SUM(o.total), 0.00) AS total_spent,
    customer_level(COALESCE(SUM(o.total), 0.00)) AS classification
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.id
   AND o.status = 'paid'
GROUP BY
    c.id,
    c.name;


-- 3. Calcular o desconto de um pedido

DELIMITER $$

CREATE FUNCTION calculate_order_discount(
    p_order_total DECIMAL(10, 2)
)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE v_rate DECIMAL(4, 2);

    SET v_rate = CASE
        WHEN p_order_total < 200.00 THEN 0.00
        WHEN p_order_total < 500.00 THEN 0.05
        WHEN p_order_total < 1000.00 THEN 0.10
        ELSE 0.15
    END;

    RETURN ROUND(p_order_total * v_rate, 2);
END$$

DELIMITER ;

SELECT
    o.id,
    o.total,
    calculate_order_discount(o.total) AS discount
FROM orders AS o
WHERE o.status = 'paid';


-- 4. Calcular a quantidade de itens de um pedido

DELIMITER $$

CREATE FUNCTION order_items_quantity(
    p_order_id BIGINT UNSIGNED
)
RETURNS BIGINT UNSIGNED
READS SQL DATA
BEGIN
    DECLARE v_quantity BIGINT UNSIGNED;

    SELECT COALESCE(SUM(quantity), 0)
      INTO v_quantity
      FROM order_items
     WHERE order_id = p_order_id;

    RETURN v_quantity;
END$$

DELIMITER ;

SELECT
    o.id,
    o.total,
    order_items_quantity(o.id) AS items_quantity
FROM orders AS o;


-- 5. Calcular o total gasto por um cliente

DELIMITER $$

CREATE FUNCTION customer_total_spent(
    p_customer_id BIGINT UNSIGNED
)
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10, 2);

    SELECT COALESCE(SUM(total), 0.00)
      INTO v_total
      FROM orders
     WHERE customer_id = p_customer_id
       AND status = 'paid';

    RETURN v_total;
END$$

DELIMITER ;

SELECT
    c.id,
    c.name,
    customer_total_spent(c.id) AS total_spent
FROM customers AS c;