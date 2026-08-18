DELIMITER $$
CREATE TRIGGER listen_product_updates
after update on products
FOR EACH ROW
BEGIN
    INSERT into log_app (info) 
    VALUES (
        concat("o produto atualizado = ID: ", 
               new.id,
               " | stock (antes): ",
               old.stock,
               " | stock (depois): ",
               new.stock
        )
    );
END$$
DELIMITER ;