-- Active: 1750417399612@@127.0.0.1@3307@pizzeria

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

-- 2
DELIMITER $$

DROP TRIGGER IF EXISTS tg_descontar_stock_ingrediente_extra $$

CREATE TRIGGER tg_descontar_stock_ingrediente_extra
AFTER INSERT ON ingrediente_extra
FOR EACH ROW
BEGIN

    UPDATE ingrediente SET stock = stock - NEW.cantidad
    WHERE id = NEW.ingrediente_id;

END $$

DELIMITER ;

INSERT INTO ingrediente_extra(cantidad, detalle_pedido_id, ingrediente_id)
VALUES(10, 1, 1);

SELECT * FROM ingrediente;

-- 3
DELIMITER $$

DROP TRIGGER IF EXISTS tg_registro_actualizacion_precios $$

CREATE TRIGGER tg_registro_actualizacion_precios
AFTER UPDATE ON producto_presentacion
FOR EACH ROW
BEGIN
    DECLARE p_precio_anterior DECIMAL(10,2);

    INSERT INTO auditoria_precios(producto_id, presentacion_id, precio_anterior, precio_nuevo, fecha_cambio)
    VALUES(NEW.producto_id, NEW.presentacion_id, OLD.precio, NEW.precio, NOW());

END $$

DELIMITER ;

UPDATE producto_presentacion SET precio = 25000 WHERE id = 4;

SELECT * FROM auditoria_precios;

-- 4
DELIMITER $$

DROP TRIGGER IF EXISTS tg_impedir_ciertos_precios $$

CREATE TRIGGER tg_impedir_ciertos_precios
BEFORE UPDATE ON producto_presentacion
FOR EACH ROW
BEGIN

    IF NEW.precio < 1 THEN
        SIGNAL SQLSTATE '40001'
            SET MESSAGE_TEXT = 'El precio debe ser mayor a 0';
    END IF;

END $$

DELIMITER ;

UPDATE producto_presentacion SET precio = 0 WHERE id = 1;

-- 5
DELIMITER $$

DROP TRIGGER IF EXISTS tg_generar_factura $$

CREATE TRIGGER tg_generar_factura
AFTER INSERT ON pedido
FOR EACH ROW
BEGIN
    DECLARE p_estado VARCHAR(150);

    IF NEW.estado IN ('Cancelado', 'Enviado') THEN
        SIGNAL SQLSTATE '40001'
            SET MESSAGE_TEXT = 'El pedido debe de estar en pendiente';
    END IF;

    INSERT INTO factura(total, fecha, pedido_id, cliente_id)
    VALUES(NEW.total, NOW(), NEW.id, NEW.cliente_id);

END $$

DELIMITER ;

INSERT INTO pedido (fecha_recogida, total, cliente_id, metodo_pago_id, estado)
VALUES('2025-03-11 06:00:00', 50000, 2, 1, 'Pendiente');

SELECT * FROM factura;

-- 6
DELIMITER $$

DROP TRIGGER IF EXISTS tg_actualizar_estado_pedido $$

CREATE TRIGGER tg_actualizar_estado_pedido
AFTER INSERT ON factura
FOR EACH ROW
BEGIN

    UPDATE pedido SET estado = 'enviado' WHERE id = NEW.pedido_id;

END $$

DELIMITER ;

SELECT * FROM pedido;

INSERT INTO factura (total, fecha, pedido_id, cliente_id)
VALUES(35000, '2025-06-10 12:05:00', 1, 1);

-- 7
DELIMITER $$

DROP TRIGGER IF EXISTS tg_evitar_eliminacion_combos_usados $$

CREATE TRIGGER tg_evitar_eliminacion_combos_usados
BEFORE DELETE ON combo
FOR EACH ROW
BEGIN
    DECLARE p_combo_id INT;
    DECLARE relacion_combo INT;

    SELECT id INTO p_combo_id FROM combo
    WHERE id = OLD.id;

    SELECT COUNT(*) INTO relacion_combo FROM producto_combo
    WHERE combo_id IN (SELECT id FROM combo WHERE id = p_combo_id);

    IF relacion_combo > 0 THEN
        SIGNAL SQLSTATE '40001'
            SET MESSAGE_TEXT = 'El combo esta relacionado';
    END IF;
    
END $$

DELIMITER ;

INSERT INTO combo(nombre, precio)
VALUES('Pa Adrian', 2000);

DELETE FROM combo WHERE id = 1;

SELECT COUNT(*) AS relaciones_combo FROM producto_combo
WHERE combo_id IN (SELECT id FROM combo WHERE id = 2);