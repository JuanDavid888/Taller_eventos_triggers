-- Active: 1750359843386@@127.0.0.1@3307@pizzeria

SHOW EVENTS;

-- 1
DELIMITER $$

DROP EVENT IF EXISTS ev_resumen_diario_unico;

CREATE EVENT ev_resumen_diario_unico 
ON SCHEDULE AT CURDATE() + INTERVAL 1 DAY
ON COMPLETION NOT PRESERVE
ENABLE
DO
BEGIN
    DECLARE p_pedidos INT;
    DECLARE p_ingresos INT;

    SET p_pedidos = (
        SELECT COUNT(*) AS pedidos FROM pedido
        WHERE fecha_recogida BETWEEN CONCAT(CURDATE(), ' 00:00:00')AND CONCAT(CURDATE(), ' 23:59:59')
        );

    SET p_pedidos = (
        SELECT SUM(total) AS total FROM pedido
        WHERE fecha_recogida BETWEEN CONCAT(CURDATE(), ' 00:00:00')AND CONCAT(CURDATE(), ' 23:59:59')
        );

    INSERT INTO resumen_ventas (fecha, total_pedidos, total_ingresos)
    VALUES(NOW(), p_pedidos, p_ingresos);

END $$

DELIMITER ;

-- 2
DELIMITER $$

DROP EVENT IF EXISTS ev_resumen_semanal $$

CREATE EVENT ev_resumen_semanal
ON SCHEDULE EVERY 1 WEEK
STARTS DATE_ADD(CURRENT_DATE, INTERVAL (7 - WEEKDAY(CURRENT_DATE)) DAY)
ON COMPLETION PRESERVE
ENABLE
DO
BEGIN
    DECLARE p_pedidos INT;
    DECLARE p_ingresos INT;

    SET p_pedidos = (
        SELECT COUNT(*) AS pedidos FROM pedido
        WHERE fecha_recogida BETWEEN CONCAT(CURDATE(), ' 00:00:00')AND CONCAT(CURDATE(), ' 23:59:59')
        );

    SET p_pedidos = (
        SELECT SUM(total) AS total FROM pedido
        WHERE fecha_recogida BETWEEN CONCAT(CURDATE(), ' 00:00:00')AND CONCAT(CURDATE(), ' 23:59:59')
        );

    INSERT INTO resumen_ventas (fecha, total_pedidos, total_ingresos)
    VALUES(NOW(), p_pedidos, p_ingresos);

END $$

DELIMITER ;

-- 3
DELIMITER $$

DROP EVENT IF EXISTS ev_alerta_stock_unica $$

CREATE EVENT ev_alerta_stock_unica
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 5 MINUTE
ON COMPLETION NOT PRESERVE
ENABLE
DO
BEGIN

    INSERT INTO alerta_stock (ingrediente_id, nombre, stock_actual, fecha_alerta)
    SELECT id, nombre, stock, NOW()
    FROM ingrediente
    WHERE stock < 5;
    
END $$

DELIMITER ;

-- 4
DELIMITER $$

DROP EVENT IF EXISTS ev_monitor_stock_bajo $$

CREATE EVENT ev_monitor_stock_bajo
ON SCHEDULE EVERY 30 MINUTE
ON COMPLETION PRESERVE
ENABLE
DO
BEGIN

    INSERT INTO alerta_stock (ingrediente_id, nombre, stock_actual, fecha_alerta)
    SELECT id, nombre, stock, NOW()
    FROM ingrediente
    WHERE stock < 10;
    
END $$

DELIMITER ;

-- 5
DELIMITER $$

DROP EVENT IF EXISTS ev_purgar_resumen_antiguo $$

CREATE EVENT ev_purgar_resumen_antiguo
ON SCHEDULE AT CURRENT_TIMESTAMP
ON COMPLETION NOT PRESERVE
ENABLE
DO
BEGIN

    DELETE FROM resumen_ventas
    WHERE fecha < CURDATE() - INTERVAL 365 DAY;
    
END $$

DELIMITER ;