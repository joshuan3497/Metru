-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 08-07-2025 a las 22:46:47
-- Versión del servidor: 10.4.25-MariaDB
-- Versión de PHP: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `metru_sistema`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `cerrar_ruta` (IN `p_salida_id` INT)   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_producto_id INT;
    DECLARE v_cantidad_salida INT;
    DECLARE v_cantidad_vendida INT;
    DECLARE v_cantidad_devuelta INT;
    
    DECLARE cursor_productos CURSOR FOR
        SELECT ds.producto_id, ds.cantidad
        FROM detalle_salidas ds
        WHERE ds.salida_id = p_salida_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Limpiar devoluciones existentes
    DELETE FROM devoluciones WHERE salida_id = p_salida_id;
    
    OPEN cursor_productos;
    
    productos_loop: LOOP
        FETCH cursor_productos INTO v_producto_id, v_cantidad_salida;
        IF done THEN
            LEAVE productos_loop;
        END IF;
        
        -- Calcular cantidad vendida
        SELECT COALESCE(SUM(df.cantidad), 0) INTO v_cantidad_vendida
        FROM detalle_facturas df
        JOIN facturas f ON df.factura_id = f.id
        WHERE f.salida_id = p_salida_id AND df.producto_id = v_producto_id;
        
        -- Calcular cantidad que debe regresar
        SET v_cantidad_devuelta = v_cantidad_salida - v_cantidad_vendida;
        
        -- Insertar devolución si hay productos que deben regresar
        IF v_cantidad_devuelta > 0 THEN
            INSERT INTO devoluciones (salida_id, producto_id, cantidad_devuelta)
            VALUES (p_salida_id, v_producto_id, v_cantidad_devuelta);
        END IF;
        
    END LOOP;
    
    CLOSE cursor_productos;
    
    -- Actualizar estado de la salida
    UPDATE salidas_mercancia SET estado = 'finalizada' WHERE id = p_salida_id;
    
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `generar_numero_factura` (`ruta_id` INT, `fecha` DATE) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci DETERMINISTIC READS SQL DATA BEGIN
    DECLARE numero_secuencial INT;
    DECLARE numero_factura VARCHAR(20);
    
    SELECT COUNT(*) + 1 INTO numero_secuencial
    FROM facturas f
    JOIN clientes c ON f.cliente_id = c.id
    WHERE c.ruta_id = ruta_id AND DATE(f.fecha_venta) = fecha;
    
    SET numero_factura = CONCAT('R', ruta_id, '-', DATE_FORMAT(fecha, '%Y%m%d'), '-', LPAD(numero_secuencial, 3, '0'));
    
    RETURN numero_factura;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria_facturas`
--

CREATE TABLE `auditoria_facturas` (
  `id` int(11) NOT NULL,
  `factura_id` int(11) DEFAULT NULL,
  `accion` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `usuario` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `datos_anteriores` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ruta_id` int(11) NOT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id`, `nombre`, `ruta_id`, `activo`, `fecha_creacion`) VALUES
(1, 'Tienda El Paraíso', 1, 1, '2025-06-17 20:39:32'),
(2, 'Minimarket San José', 1, 1, '2025-06-17 20:39:32'),
(3, 'Supermercado Central', 1, 1, '2025-06-17 20:39:32'),
(4, 'Tienda La Esquina', 1, 1, '2025-06-17 20:39:32'),
(5, 'Minimercado El Ahorro', 1, 1, '2025-06-17 20:39:32'),
(6, 'Tienda Los Andes', 2, 1, '2025-06-17 20:39:32'),
(7, 'Supermarket El Progreso', 2, 1, '2025-06-17 20:39:32'),
(8, 'Tienda Familiar', 2, 1, '2025-06-17 20:39:32'),
(9, 'Minimarket La Plaza', 2, 1, '2025-06-17 20:39:32'),
(10, 'Tienda El Buen Precio', 2, 1, '2025-06-17 20:39:32'),
(11, 'Supermercado La Rebaja', 3, 1, '2025-06-17 20:39:32'),
(12, 'Tienda El Triunfo', 3, 1, '2025-06-17 20:39:32'),
(13, 'Minimarket Villa Nueva', 3, 1, '2025-06-17 20:39:32'),
(14, 'Tienda Los Alpes', 3, 1, '2025-06-17 20:39:32'),
(15, 'Supermercado Popular', 3, 1, '2025-06-17 20:39:32'),
(16, 'Tienda La Esperanza', 4, 1, '2025-06-17 20:39:32'),
(17, 'Minimarket El Centro', 4, 1, '2025-06-17 20:39:32'),
(18, 'Supermercado Los Pinos', 4, 1, '2025-06-17 20:39:32'),
(19, 'Tienda El Mirador', 4, 1, '2025-06-17 20:39:32'),
(20, 'Minimercado La Unión', 4, 1, '2025-06-17 20:39:32'),
(21, 'Tienda Santa Fe', 5, 1, '2025-06-17 20:39:32'),
(22, 'Supermarket La Colina', 5, 1, '2025-06-17 20:39:32'),
(23, 'Minimarket El Valle', 5, 1, '2025-06-17 20:39:32'),
(24, 'Tienda Los Nogales', 5, 1, '2025-06-17 20:39:32'),
(25, 'Supermercado El Portal', 5, 1, '2025-06-17 20:39:32'),
(26, 'Tienda La Montaña', 6, 1, '2025-06-17 20:39:32'),
(27, 'Minimarket El Bosque', 6, 1, '2025-06-17 20:39:32'),
(28, 'Supermercado Los Cerezos', 6, 1, '2025-06-17 20:39:32'),
(29, 'Tienda El Jardín', 6, 1, '2025-06-17 20:39:32'),
(30, 'Minimercado La Aurora', 6, 1, '2025-06-17 20:39:32');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_facturas`
--

CREATE TABLE `detalle_facturas` (
  `id` int(11) NOT NULL,
  `factura_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `detalle_facturas`
--

INSERT INTO `detalle_facturas` (`id`, `factura_id`, `producto_id`, `cantidad`, `precio_unitario`, `subtotal`) VALUES
(1, 1, 5, 3, '350000.00', '1050000.00'),
(2, 2, 6, 4, '35000.00', '140000.00'),
(3, 2, 46, 1, '36000.00', '36000.00'),
(4, 3, 6, 5, '5000.00', '25000.00'),
(5, 4, 46, 10, '36700.00', '367000.00'),
(6, 5, 46, 10, '36700.00', '367000.00'),
(7, 6, 108, 50, '32000.00', '1600000.00'),
(8, 7, 108, 10, '32000.00', '320000.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_salidas`
--

CREATE TABLE `detalle_salidas` (
  `id` int(11) NOT NULL,
  `salida_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `tipo_carga` enum('normal','pedido') COLLATE utf8mb4_unicode_ci DEFAULT 'normal',
  `cargado` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `detalle_salidas`
--

INSERT INTO `detalle_salidas` (`id`, `salida_id`, `producto_id`, `cantidad`, `tipo_carga`, `cargado`) VALUES
(1, 1, 28, 10, 'normal', 0),
(2, 1, 1, 50, 'normal', 0),
(3, 2, 34, 1, 'normal', 0),
(4, 2, 86, 1, 'normal', 0),
(5, 2, 36, 1, 'normal', 0),
(6, 2, 32, 1, 'normal', 0),
(7, 2, 35, 1, 'normal', 0),
(8, 2, 33, 1, 'normal', 0),
(9, 2, 95, 1, 'normal', 0),
(10, 2, 87, 1, 'normal', 0),
(11, 2, 1, 1, 'normal', 0),
(12, 2, 2, 1, 'normal', 0),
(13, 2, 6, 1, 'normal', 0),
(14, 2, 46, 1, 'normal', 0),
(15, 2, 7, 1, 'normal', 0),
(16, 2, 68, 1, 'normal', 0),
(17, 2, 30, 1, 'normal', 0),
(18, 2, 5, 1, 'normal', 0),
(19, 2, 55, 1, 'normal', 0),
(20, 2, 38, 1, 'normal', 0),
(21, 2, 3, 1, 'normal', 0),
(22, 3, 1, 10, 'normal', 0),
(23, 3, 2, 10, 'normal', 0),
(24, 3, 6, 10, 'normal', 0),
(25, 3, 46, 10, 'normal', 0),
(26, 3, 7, 10, 'normal', 0),
(27, 3, 68, 10, 'normal', 0),
(28, 3, 30, 10, 'normal', 0),
(29, 3, 5, 10, 'normal', 0),
(30, 3, 55, 10, 'normal', 0),
(31, 3, 38, 10, 'normal', 0),
(32, 3, 108, 10, 'normal', 0),
(33, 3, 58, 10, 'normal', 0),
(34, 3, 4, 10, 'normal', 0),
(35, 4, 6, 1, 'normal', 0),
(36, 4, 46, 1, 'normal', 0),
(37, 4, 7, 1, 'normal', 0),
(38, 4, 68, 1, 'normal', 0),
(39, 4, 30, 1, 'normal', 0),
(40, 4, 5, 1, 'normal', 0),
(41, 5, 46, 1, 'normal', 0),
(42, 5, 6, 1, 'normal', 0),
(43, 5, 7, 1, 'normal', 0),
(44, 5, 68, 1, 'normal', 0),
(45, 5, 30, 1, 'normal', 0),
(46, 5, 5, 1, 'normal', 0),
(47, 5, 55, 1, 'normal', 0),
(48, 5, 38, 1, 'normal', 0),
(49, 5, 3, 1, 'normal', 0),
(50, 5, 108, 1, 'normal', 0),
(51, 5, 58, 1, 'normal', 0),
(52, 5, 4, 1, 'normal', 0),
(53, 5, 1, 1, 'normal', 0),
(54, 6, 6, 1, 'normal', 0),
(55, 6, 46, 1, 'normal', 0),
(56, 6, 7, 1, 'normal', 0),
(57, 6, 68, 1, 'normal', 0),
(58, 6, 30, 1, 'normal', 0),
(59, 6, 5, 1, 'normal', 0),
(60, 6, 55, 1, 'normal', 0),
(61, 7, 6, 1, 'normal', 1),
(62, 7, 46, 1, 'normal', 1),
(63, 7, 7, 1, 'normal', 1),
(64, 7, 68, 1, 'normal', 1),
(65, 7, 58, 1, 'normal', 1),
(66, 7, 108, 1, 'normal', 1),
(67, 7, 3, 1, 'normal', 1),
(68, 8, 6, 10, 'normal', 0),
(69, 8, 46, 10, 'normal', 0),
(70, 8, 7, 10, 'normal', 0),
(71, 8, 68, 10, 'normal', 0),
(72, 8, 30, 10, 'normal', 0),
(73, 8, 5, 10, 'normal', 0),
(74, 8, 3, 1, 'normal', 0),
(75, 8, 108, 1, 'normal', 0),
(76, 8, 4, 1, 'normal', 0),
(77, 8, 1, 1, 'normal', 0),
(78, 9, 6, 10, 'normal', 1),
(79, 10, 46, 50, 'normal', 1),
(80, 10, 108, 90, 'normal', 1),
(81, 11, 34, 10, 'normal', 1),
(82, 11, 86, 10, 'normal', 1),
(83, 11, 32, 10, 'normal', 1),
(84, 11, 35, 10, 'normal', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `devoluciones`
--

CREATE TABLE `devoluciones` (
  `id` int(11) NOT NULL,
  `salida_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad_devuelta` int(11) NOT NULL,
  `fecha_devolucion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `devoluciones`
--

INSERT INTO `devoluciones` (`id`, `salida_id`, `producto_id`, `cantidad_devuelta`, `fecha_devolucion`) VALUES
(1, 1, 1, 9, '2025-06-20 20:31:22'),
(2, 5, 53, 2, '2025-06-26 19:30:01');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `facturas`
--

CREATE TABLE `facturas` (
  `id` int(11) NOT NULL,
  `numero_factura` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salida_id` int(11) NOT NULL,
  `cliente_id` int(11) DEFAULT NULL,
  `cliente_nombre` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cliente_ciudad` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vendedor_id` int(11) NOT NULL,
  `forma_pago` enum('efectivo','transferencia','pendiente') COLLATE utf8mb4_unicode_ci NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `fecha_venta` datetime DEFAULT current_timestamp(),
  `observaciones` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `facturas`
--

INSERT INTO `facturas` (`id`, `numero_factura`, `salida_id`, `cliente_id`, `cliente_nombre`, `cliente_ciudad`, `vendedor_id`, `forma_pago`, `total`, `fecha_venta`, `observaciones`) VALUES
(1, 'R1-20250621-001', 2, 2, 'jose', 'popayan', 2, 'transferencia', '1050000.00', '2025-06-20 17:16:32', ''),
(2, 'R1-20250627-001', 7, 2, 'jose', 'popayan', 2, 'pendiente', '176000.00', '2025-06-27 15:31:33', ''),
(3, 'R1-20250627-002', 7, 2, 'jose', 'popayan', 2, 'efectivo', '25000.00', '2025-06-27 15:49:51', ''),
(4, 'R2-20250707-001', 10, 9, NULL, NULL, 2, 'efectivo', '367000.00', '2025-07-07 13:32:43', ''),
(5, 'R2-20250707-002', 10, 9, NULL, NULL, 2, 'efectivo', '367000.00', '2025-07-07 16:02:47', ''),
(6, 'R2-20250707-003', 10, 9, NULL, NULL, 2, 'transferencia', '1600000.00', '2025-07-07 16:03:12', ''),
(7, 'R2-20250707-004', 10, 7, NULL, NULL, 2, 'efectivo', '320000.00', '2025-07-07 16:18:59', '');

--
-- Disparadores `facturas`
--
DELIMITER $$
CREATE TRIGGER `before_delete_factura` BEFORE DELETE ON `facturas` FOR EACH ROW BEGIN
    INSERT INTO auditoria_facturas (factura_id, accion, usuario, datos_anteriores)
    VALUES (
        OLD.id, 
        'DELETE_ATTEMPT', 
        USER(), 
        CONCAT('Factura:', OLD.numero_factura, ', Total:', OLD.total, ', Cliente:', OLD.cliente_id)
    );
    
    -- Evitar borrado si la factura tiene más de 24 horas
    IF TIMESTAMPDIFF(HOUR, OLD.fecha_venta, NOW()) > 24 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No se pueden borrar facturas con más de 24 horas';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `gastos_ruta`
--

CREATE TABLE `gastos_ruta` (
  `id` int(11) NOT NULL,
  `salida_id` int(11) NOT NULL,
  `concepto` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `fecha_gasto` date NOT NULL,
  `observaciones` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `grupo_id` int(11) NOT NULL,
  `unidad_medida` enum('CAJA','SIX PAK','UNIDAD','PAQ') COLLATE utf8mb4_unicode_ci NOT NULL,
  `precio_publico` decimal(10,2) NOT NULL,
  `costo` decimal(10,2) DEFAULT 0.00,
  `ganancia` decimal(10,2) DEFAULT 0.00,
  `porcentaje_ganancia` decimal(5,2) DEFAULT 0.00,
  `stock_actual` int(11) DEFAULT 0,
  `stock_minimo` int(11) DEFAULT 0,
  `iva` decimal(5,2) DEFAULT 19.00,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id`, `codigo`, `descripcion`, `grupo_id`, `unidad_medida`, `precio_publico`, `costo`, `ganancia`, `porcentaje_ganancia`, `stock_actual`, `stock_minimo`, `iva`, `activo`, `fecha_creacion`) VALUES
(1, '1', 'GASEOSA POSTOBON 250 X 30', 1, 'CAJA', '25000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(2, '2', 'GASEOSA POSTOBON 350X30', 1, 'CAJA', '45000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(3, '3', 'POSTOBON PET 250 CERO X 12', 1, 'CAJA', '10000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(4, '4', 'POSTOBON PET 500 X15', 1, 'CAJA', '31250.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(5, '5', 'POSTOBON ECONOLITRO X 12', 1, 'CAJA', '35000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(6, '6', 'POSTOBON 1.5X12', 1, 'CAJA', '45000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(7, '7', 'POSTOBON 3LX6', 1, 'CAJA', '35000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(8, '8', 'HIT 250X30', 3, 'CAJA', '37500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(9, '9', 'HIT 200 X 24', 3, 'CAJA', '28000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(10, '10', 'HIT 500 X12', 3, 'CAJA', '28000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(11, '11', 'TETRAPAK X 12', 3, 'CAJA', '45800.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(12, '12', 'HIT 1.5X6', 3, 'CAJA', '25000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(13, '13', 'TECATE 330 X 30', 2, 'CAJA', '39000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(14, '14', 'TECATE 750 X 16', 2, 'CAJA', '42000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(15, '15', 'PONY MINI X30', 11, 'CAJA', '42000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(16, '16', 'PONY 330 X 24', 11, 'CAJA', '52000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(17, '17', 'PONY LITRO X 15', 11, 'CAJA', '52000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(18, '18', 'PONY 1.5X6', 11, 'CAJA', '31500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(19, '19', 'POKER LATA X 24', 2, 'SIX PAK', '16000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(20, '20', 'SPORADE 500 X 12', 5, 'CAJA', '24000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(21, '21', 'BIG COLA 400 X12', 1, 'CAJA', '16000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(22, '22', 'BIG COLA 1.7 X 8', 1, 'CAJA', '25700.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(23, '23', 'CANADA DRY 1.5X12', 1, 'CAJA', '50000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(24, '24', 'AGUA CIELO 620 X 24', 4, 'CAJA', '19700.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(25, '25', 'AGUA CIELO LITRO X 12', 4, 'CAJA', '20000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(26, '26', 'BRETAÑA FRIOPAK X 24', 4, 'CAJA', '50900.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(27, '27', 'AGUA CRISTAL 600 X 24', 4, 'CAJA', '27700.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(28, '28', 'AGUA CRISTAL 300', 4, 'CAJA', '12000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(29, '29', 'AGUA CRISTAL SPORT', 4, 'CAJA', '23000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(30, '30', 'POSTOBON AQUA 500 X 15', 1, 'CAJA', '18800.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(31, '31', 'RED BULL 269 X 24', 7, 'CAJA', '23100.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(32, '32', 'COCACOLA 400 X12', 1, 'CAJA', '30000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(33, '33', 'SABORES COCACOLA 400 X 12', 1, 'CAJA', '25100.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(34, '34', 'COCACOLA 1.5 X12', 1, 'CAJA', '65000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(35, '35', 'COCACOLA SABORES 1.5X12', 1, 'CAJA', '45000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(36, '36', 'COCACOLA 3L X 6', 1, 'CAJA', '55000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(37, '37', 'JUGO DEL VALLE 1.5 X12', 3, 'CAJA', '45000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(38, '38', 'POSTOBON H2O 600 X 15', 1, 'CAJA', '32500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(39, '39', 'AGUA CRISTAL BOLSA 6L', 4, 'CAJA', '4000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(40, '40', 'BOTELLON AGUA CRISTAL 20 L', 4, 'CAJA', '14500.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(41, '41', 'GATORADE', 5, 'CAJA', '37000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(42, '42', 'GATORADE 500 X 12', 5, 'CAJA', '37000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(43, '43', 'BRETAÑA FRIOPAK X 18', 4, 'CAJA', '38000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(44, '44', 'SPEED 250 X 12', 1, 'CAJA', '15000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(45, '45', 'BRETAÑA 1.5 X12', 4, 'CAJA', '40000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(46, '46', 'POSTOBON 2.5 X8', 1, 'CAJA', '36700.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(47, '47', 'JUGO TUTI 250 X12', 3, 'CAJA', '10000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(48, '48', 'ANDINA LIGHT', 2, 'CAJA', '11750.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(49, '49', 'TW HATSU', 6, 'CAJA', '24000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(50, '50', 'AMPER 473 SIX PAK', 7, 'CAJA', '15000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(51, '51', 'SQUASH X 12', 5, 'CAJA', '25000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(52, '52', 'JUGO DEL VALLE 400 X12', 3, 'CAJA', '21000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(53, '53', 'AVENA / LECHE ACHOCOLATADA BILAC X 12', 8, 'PAQ', '15200.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(54, '54', 'CERVEZA COSTEÑA 750', 2, 'CAJA', '38400.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(55, '55', 'POSTOBON GASEOSA LATA 269 X 24', 1, 'CAJA', '40900.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(56, '56', 'AGUA CRISTAL GARRAFA', 4, 'CAJA', '7000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(57, '57', 'CERVEZA HEINEKEN 310', 2, 'CAJA', '14250.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(58, '58', 'POSTOBON PET 400 X12', 1, 'CAJA', '25000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(59, '59', 'GASEOSA BIG COLA 3L X6', 1, 'CAJA', '28000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(60, '60', 'JUGO CIFRUT 1.7 X8', 3, 'CAJA', '25500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(61, '61', 'GASEOSA BIG COLA LITRO X15', 1, 'CAJA', '32500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(62, '62', 'NATU MALTA 299', 1, 'CAJA', '6000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(63, '63', 'CERVEZA BUDWEISER', 2, 'CAJA', '50000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(64, '64', 'BOLT 473 SIX PAK', 7, 'CAJA', '18400.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(65, '65', 'JUGO ZUMO 500 X 12', 3, 'CAJA', '18000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(66, '66', 'JUGO ZUMO 200 X 24', 3, 'CAJA', '18000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(67, '67', 'JUGO ZUMO 250 X 15', 3, 'CAJA', '12300.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(68, '68', 'POSTOBON AQUA 250 X 12', 1, 'CAJA', '15700.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(69, '69', 'DUO 3L + 1.5', 1, 'CAJA', '14000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(70, '70', 'MR TEA 500 X 12', 6, 'CAJA', '25000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(71, '71', 'AGUA CRISTAL ALOE 330 X12', 4, 'CAJA', '20000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(72, '72', 'SAVILOE 420 ML', 1, 'CAJA', '12500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(73, '73', 'SPARTA 269ML', 7, 'CAJA', '7500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(74, '74', 'AGUA GAS CRISTAL 600 X 24', 4, 'CAJA', '30100.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(75, '75', 'AGUA SIP 600 X 20', 4, 'CAJA', '15000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(76, '76', 'CERVEZA SOL 250X24', 2, 'CAJA', '55000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(77, '77', 'CERVEZA SOL 330 X 24', 2, 'CAJA', '72000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(78, '78', 'CERVEZA CORONA 330', 2, 'CAJA', '80000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(79, '79', 'POWER X 6', 5, 'CAJA', '18000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(80, '80', 'AGUA BRISA 600', 4, 'CAJA', '27000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(81, '81', 'AGUA SABORIZADA ZEN', 4, 'CAJA', '12500.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(82, '82', 'HIT 300 X 12', 3, 'CAJA', '20000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(83, '83', 'VIVE 100 380 X 6', 7, 'CAJA', '12500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(84, '84', 'POPNY MINI GO X 6', 1, 'CAJA', '5500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(85, '85', 'VIVE 100 240ML X 6', 7, 'CAJA', '10000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(86, '86', 'COCACOLA 250ML X 12', 1, 'CAJA', '19200.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(87, '87', 'UNIDAD DE 1.5 COCACOLA SABORES', 1, 'CAJA', '3750.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(88, '88', 'UNIDAD DE BRETAÑA FRIOPAK', 4, 'UNIDAD', '1950.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(89, '89', 'UNIDAD BRETAÑA 1.5', 4, 'UNIDAD', '3333.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(90, '90', 'CERVEZA AGUILA LIGHT', 2, 'SIX PAK', '16250.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(91, '91', 'ZUMO VASO 180 ML X 28', 3, 'CAJA', '16000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(92, '92', 'SALCHICHON', 9, 'UNIDAD', '7000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(93, '93', 'DISPENSADOR DE AGUA', 10, 'UNIDAD', '15000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(94, '94', 'UNIDAD SPEED LATA 269', 7, 'UNIDAD', '1250.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(95, '95', 'UNIDAD COCACOLA 1.5', 1, 'UNIDAD', '5000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(96, '96', 'SODA HATSU', 1, 'CAJA', '15000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(97, '97', 'UNIDAD PONY MINI', 1, 'UNIDAD', '1383.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(98, '98', 'UNIDAD PONY 330', 1, 'UNIDAD', '2167.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(99, '99', 'CERVEZA CORONITA 210', 2, 'CAJA', '64000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(100, '100', 'AGUA POOL X 20', 4, 'CAJA', '13000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(101, '101', 'SODA SCHWEPPE 400', 4, 'CAJA', '25100.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(102, '102', 'HIT 237 ML X 24', 3, 'CAJA', '33400.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(103, '103', 'POKER BOTELLA 330 X 30', 2, 'CAJA', '64000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(104, '104', 'TECATE LATA 330', 2, 'SIX PAK', '13750.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(105, '105', 'LIKE', 2, 'UNIDAD', '2900.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(106, '106', 'CANADA DRY 1.5 X 12', 1, 'CAJA', '50000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(107, '107', 'DUO 3L + PET 400', 1, 'CAJA', '11000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(108, '108', 'POSTOBON PET 400 X 15', 1, 'CAJA', '32000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(109, '109', 'TARRO BOTELLON 20L', 10, 'CAJA', '16000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(110, '110', 'SAVILOE 320 ML', 1, 'SIX PAK', '12500.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(111, '111', 'CANASTA 350 X 30 TAMARINDO', 1, 'CAJA', '50000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(112, '112', 'POKERON 750', 2, 'CAJA', '52000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(113, '113', 'SPEED LATA 310 X 24', 7, 'CAJA', '40000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(114, '114', 'UNIDAD DE AGUA 600', 4, 'UNIDAD', '1154.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(115, '115', 'AGUA POOL LITRO', 4, 'CAJA', '20000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(116, '116', 'ANDINA 250 X 30', 2, 'CAJA', '45000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(117, '117', 'POKER LATA 473', 2, 'CAJA', '16000.00', '0.00', '0.00', '0.00', 0, 0, '19.00', 1, '2025-06-17 20:39:32'),
(118, '118', 'BRETAÑA 250 X 30', 4, 'CAJA', '25000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(119, '119', 'AGUILA LIGHT BOTELLA 330 X 30', 2, 'CAJA', '64000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32'),
(120, '120', 'AGUILA ORIGINAL BOTELLA 330X 30', 2, 'CAJA', '63000.00', '0.00', '0.00', '0.00', 0, 0, '0.00', 1, '2025-06-17 20:39:32');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rutas`
--

CREATE TABLE `rutas` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `activa` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `rutas`
--

INSERT INTO `rutas` (`id`, `nombre`, `descripcion`, `activa`, `fecha_creacion`) VALUES
(1, 'Ruta 1', 'Primera ruta de distribución', 1, '2025-06-17 20:39:32'),
(2, 'Ruta 2', 'Segunda ruta de distribución', 1, '2025-06-17 20:39:32'),
(3, 'Ruta 3', 'Tercera ruta de distribución', 1, '2025-06-17 20:39:32'),
(4, 'Ruta 4', 'Cuarta ruta de distribución', 1, '2025-06-17 20:39:32'),
(5, 'Ruta 5', 'Quinta ruta de distribución', 1, '2025-06-17 20:39:32'),
(6, 'Ruta 6', 'Sexta ruta de distribución', 1, '2025-06-17 20:39:32');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `salidas_mercancia`
--

CREATE TABLE `salidas_mercancia` (
  `id` int(11) NOT NULL,
  `ruta_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `fecha_salida` date NOT NULL,
  `observaciones` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado` enum('preparando','en_ruta','finalizada') COLLATE utf8mb4_unicode_ci DEFAULT 'preparando',
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `salidas_mercancia`
--

INSERT INTO `salidas_mercancia` (`id`, `ruta_id`, `usuario_id`, `fecha_salida`, `observaciones`, `estado`, `fecha_creacion`) VALUES
(1, 1, 2, '2025-06-20', '', 'finalizada', '2025-06-20 17:23:10'),
(2, 1, 2, '2025-06-20', '', 'en_ruta', '2025-06-20 20:05:12'),
(3, 2, 3, '2025-06-21', '', 'en_ruta', '2025-06-21 13:09:55'),
(4, 1, 2, '2025-06-25', '', 'finalizada', '2025-06-25 17:38:17'),
(5, 2, 2, '2025-06-26', '', 'finalizada', '2025-06-26 19:14:15'),
(6, 4, 2, '2025-06-26', '', 'en_ruta', '2025-06-26 19:27:39'),
(7, 1, 2, '2025-06-27', '', 'finalizada', '2025-06-27 20:29:39'),
(8, 1, 2, '2025-06-28', '', 'en_ruta', '2025-06-28 16:44:57'),
(9, 1, 2, '2025-07-05', '', 'finalizada', '2025-07-05 22:02:03'),
(10, 2, 2, '2025-07-05', '', 'finalizada', '2025-07-05 22:15:35'),
(11, 1, 2, '2025-07-08', '', 'en_ruta', '2025-07-08 20:01:18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `salida_trabajadores`
--

CREATE TABLE `salida_trabajadores` (
  `id` int(11) NOT NULL,
  `salida_id` int(11) NOT NULL,
  `trabajador_id` int(11) NOT NULL,
  `es_principal` tinyint(1) DEFAULT 0,
  `fecha_asignacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `salida_trabajadores`
--

INSERT INTO `salida_trabajadores` (`id`, `salida_id`, `trabajador_id`, `es_principal`, `fecha_asignacion`) VALUES
(7, 9, 2, 1, '2025-07-05 22:07:56'),
(8, 9, 3, 0, '2025-07-05 22:07:56'),
(9, 9, 4, 0, '2025-07-05 22:07:56');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `codigo_usuario` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo` enum('admin','trabajador') COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `codigo_usuario`, `nombre`, `tipo`, `password`, `activo`, `fecha_creacion`) VALUES
(1, 'ADMIN001', 'Administrador Principal', 'admin', '0192023a7bbd73250516f069df18b500', 1, '2025-06-17 20:39:32'),
(2, 'VEND001', 'Vendedor 1', 'trabajador', 'f73b855f931a2b2fd2ef1d0b88f58977', 1, '2025-06-17 20:39:32'),
(3, 'VEND002', 'Vendedor 2', 'trabajador', 'f73b855f931a2b2fd2ef1d0b88f58977', 1, '2025-06-17 20:39:32'),
(4, 'VEND003', 'Vendedor 3', 'trabajador', 'f73b855f931a2b2fd2ef1d0b88f58977', 1, '2025-06-17 20:39:32');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_ventas_detalle`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_ventas_detalle` (
`factura_id` int(11)
,`numero_factura` varchar(20)
,`fecha_venta` datetime
,`ruta` varchar(50)
,`cliente` varchar(100)
,`vendedor` varchar(100)
,`producto` varchar(150)
,`cantidad` int(11)
,`precio_unitario` decimal(10,2)
,`subtotal` decimal(10,2)
,`forma_pago` enum('efectivo','transferencia','pendiente')
,`total_factura` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_ventas_detalle`
--
DROP TABLE IF EXISTS `vista_ventas_detalle`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_ventas_detalle`  AS SELECT `f`.`id` AS `factura_id`, `f`.`numero_factura` AS `numero_factura`, `f`.`fecha_venta` AS `fecha_venta`, `r`.`nombre` AS `ruta`, `c`.`nombre` AS `cliente`, `u`.`nombre` AS `vendedor`, `p`.`descripcion` AS `producto`, `df`.`cantidad` AS `cantidad`, `df`.`precio_unitario` AS `precio_unitario`, `df`.`subtotal` AS `subtotal`, `f`.`forma_pago` AS `forma_pago`, `f`.`total` AS `total_factura` FROM (((((`facturas` `f` join `clientes` `c` on(`f`.`cliente_id` = `c`.`id`)) join `rutas` `r` on(`c`.`ruta_id` = `r`.`id`)) join `usuarios` `u` on(`f`.`vendedor_id` = `u`.`id`)) join `detalle_facturas` `df` on(`f`.`id` = `df`.`factura_id`)) join `productos` `p` on(`df`.`producto_id` = `p`.`id`))  ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auditoria_facturas`
--
ALTER TABLE `auditoria_facturas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_auditoria_factura` (`factura_id`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_clientes_ruta` (`ruta_id`);

--
-- Indices de la tabla `detalle_facturas`
--
ALTER TABLE `detalle_facturas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `producto_id` (`producto_id`),
  ADD KEY `idx_detalle_factura` (`factura_id`);

--
-- Indices de la tabla `detalle_salidas`
--
ALTER TABLE `detalle_salidas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `producto_id` (`producto_id`),
  ADD KEY `idx_cargado` (`salida_id`,`cargado`);

--
-- Indices de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `salida_id` (`salida_id`),
  ADD KEY `producto_id` (`producto_id`);

--
-- Indices de la tabla `facturas`
--
ALTER TABLE `facturas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `numero_factura` (`numero_factura`),
  ADD KEY `vendedor_id` (`vendedor_id`),
  ADD KEY `idx_facturas_fecha` (`fecha_venta`),
  ADD KEY `idx_factura_salida` (`salida_id`),
  ADD KEY `fk_facturas_cliente` (`cliente_id`);

--
-- Indices de la tabla `gastos_ruta`
--
ALTER TABLE `gastos_ruta`
  ADD PRIMARY KEY (`id`),
  ADD KEY `salida_id` (`salida_id`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo` (`codigo`),
  ADD KEY `idx_productos_grupo` (`grupo_id`),
  ADD KEY `idx_productos_costo` (`costo`);

--
-- Indices de la tabla `rutas`
--
ALTER TABLE `rutas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `salidas_mercancia`
--
ALTER TABLE `salidas_mercancia`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ruta_id` (`ruta_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `idx_salidas_fecha` (`fecha_salida`);

--
-- Indices de la tabla `salida_trabajadores`
--
ALTER TABLE `salida_trabajadores`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_salida_trabajador` (`salida_id`,`trabajador_id`),
  ADD KEY `trabajador_id` (`trabajador_id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo_usuario` (`codigo_usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditoria_facturas`
--
ALTER TABLE `auditoria_facturas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT de la tabla `detalle_facturas`
--
ALTER TABLE `detalle_facturas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `detalle_salidas`
--
ALTER TABLE `detalle_salidas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `facturas`
--
ALTER TABLE `facturas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `gastos_ruta`
--
ALTER TABLE `gastos_ruta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=121;

--
-- AUTO_INCREMENT de la tabla `rutas`
--
ALTER TABLE `rutas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `salidas_mercancia`
--
ALTER TABLE `salidas_mercancia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `salida_trabajadores`
--
ALTER TABLE `salida_trabajadores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD CONSTRAINT `clientes_ibfk_1` FOREIGN KEY (`ruta_id`) REFERENCES `rutas` (`id`);

--
-- Filtros para la tabla `detalle_facturas`
--
ALTER TABLE `detalle_facturas`
  ADD CONSTRAINT `detalle_facturas_ibfk_1` FOREIGN KEY (`factura_id`) REFERENCES `facturas` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_facturas_ibfk_2` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`);

--
-- Filtros para la tabla `detalle_salidas`
--
ALTER TABLE `detalle_salidas`
  ADD CONSTRAINT `detalle_salidas_ibfk_1` FOREIGN KEY (`salida_id`) REFERENCES `salidas_mercancia` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `detalle_salidas_ibfk_2` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`);

--
-- Filtros para la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  ADD CONSTRAINT `devoluciones_ibfk_1` FOREIGN KEY (`salida_id`) REFERENCES `salidas_mercancia` (`id`),
  ADD CONSTRAINT `devoluciones_ibfk_2` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`);

--
-- Filtros para la tabla `facturas`
--
ALTER TABLE `facturas`
  ADD CONSTRAINT `facturas_ibfk_1` FOREIGN KEY (`salida_id`) REFERENCES `salidas_mercancia` (`id`),
  ADD CONSTRAINT `facturas_ibfk_3` FOREIGN KEY (`vendedor_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `fk_facturas_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_facturas_salida` FOREIGN KEY (`salida_id`) REFERENCES `salidas_mercancia` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `gastos_ruta`
--
ALTER TABLE `gastos_ruta`
  ADD CONSTRAINT `gastos_ruta_ibfk_1` FOREIGN KEY (`salida_id`) REFERENCES `salidas_mercancia` (`id`);

--
-- Filtros para la tabla `salidas_mercancia`
--
ALTER TABLE `salidas_mercancia`
  ADD CONSTRAINT `salidas_mercancia_ibfk_1` FOREIGN KEY (`ruta_id`) REFERENCES `rutas` (`id`),
  ADD CONSTRAINT `salidas_mercancia_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `salida_trabajadores`
--
ALTER TABLE `salida_trabajadores`
  ADD CONSTRAINT `salida_trabajadores_ibfk_1` FOREIGN KEY (`salida_id`) REFERENCES `salidas_mercancia` (`id`),
  ADD CONSTRAINT `salida_trabajadores_ibfk_2` FOREIGN KEY (`trabajador_id`) REFERENCES `usuarios` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
