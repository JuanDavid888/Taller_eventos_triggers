-- Active: 1750359843386@@127.0.0.1@3307@pizzeria

SHOW EVENTS;

-- 1
DELIMITER $$

DROP EVENT IF EXISTS ev_resumen_diario_unico;

CREATE EVENT ev_resumen_diario_unico 
ON SCHEDULE AT CURDATE() + INTERVAL 1 DAY
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