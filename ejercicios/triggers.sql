-- Active: 1750359843386@@127.0.0.1@3307@pizzeria

SHOW TRIGGERS;

-- 1
DELIMITER $$

DROP TRIGGER IF EXISTS tg_validar_stock

CREATE TRIGGER tg_validar_stock
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
BEGIN
    DECLARE p_producto_id INT;
    DECLARE p_tipo_producto_id INT;
    DECLARE p_stock INT;

    SELECT pro.id, pro.tipo_producto_id
    INTO p_producto_id, p_tipo_producto_id
    FROM producto_presentacion pro_pre
    JOIN producto pro ON pro_pre.producto_id = pro.id
    WHERE pro_pre.id = NEW.producto_presentacion_id;

    IF p_tipo_producto_id = 2 THEN

        SELECT MIN(stock) INTO p_stock FROM ingrediente ing
        JOIN ingrediente_producto ing_pro ON ing.id = ing_pro.ingrediente_id
        WHERE ing_pro.producto_id = p_producto_id;

        IF p_stock < NEW.cantidad THEN
            SIGNAL SQLSTATE '40001'
                SET MESSAGE_TEXT = 'No hay suficiente stock para el producto seleccionado';
        END IF;

    END IF;


END $$

DELIMITER ;

INSERT INTO detalle_pedido (cantidad, pedido_id, producto_presentacion_id, tipo_combo)
VALUES(20, 1, 4, 'Producto individual');

SELECT pro.id AS Producto, pro.tipo_producto_id AS Tipo_Producto
    FROM producto_presentacion pro_pre
    JOIN producto pro ON pro_pre.producto_id = pro.id
    WHERE pro_pre.id = 4;