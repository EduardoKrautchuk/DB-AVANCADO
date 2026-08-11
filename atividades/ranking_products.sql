DELIMITER $$

CREATE PROCEDURE ranking_products(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_limit INT,
    IN p_category_id BIGINT
)
BEGIN
    SELECT
        p.name AS produto,
        SUM(oi.quantity) AS qtde_vendida,
        SUM(oi.quantity * oi.unit_price) AS faturamento
    FROM order_items oi
    INNER JOIN orders o
        ON o.id = oi.order_id
    INNER JOIN products p
        ON p.id = oi.product_id
    WHERE
        o.created_at >= p_start_date
        AND o.created_at < DATE_ADD(p_end_date, INTERVAL 1 DAY)
        AND (
            p_category_id IS NULL
            OR p.category_id = p_category_id
        )
    GROUP BY
        p.id,
        p.name
    ORDER BY
        qtde_vendida DESC,
        faturamento DESC
    LIMIT p_limit;
END$$

DELIMITER ;