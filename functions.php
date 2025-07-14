<?php
// =====================================================
// FUNCIONES PRINCIPALES - SISTEMA METRU
// =====================================================

// Detectar la ruta correcta al archivo de base de datos


// Tu código continúa aquí...
$config_path = '';
if (file_exists('config/database.php')) {
    $config_path = 'config/database.php';
} elseif (file_exists('../config/database.php')) {
    $config_path = '../config/database.php';
} elseif (file_exists('../../config/database.php')) {
    $config_path = '../../config/database.php';
}
// Incluir configuración si no está incluida
if (!defined('APP_NAME')) {
    include_once __DIR__ . '/../config/config.php';
}

include_once __DIR__ . '/../config/db.php';

// Incluir configuración
if (!defined('APP_NAME')) {
    $config_file = dirname(__DIR__) . '/config/config.php';
    if (file_exists($config_file)) {
        include_once $config_file;
    }
}

// Incluir base de datos
$db_file = dirname(__DIR__) . '/config/database.php';
if (file_exists($db_file)) {
    include_once $db_file;
} else {
    die('Error: No se pudo encontrar el archivo de base de datos');
}

// Hacer $pdo global para que esté disponible en todas las funciones
global $pdo;

// Iniciar sesión si no está iniciada
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// =====================================================
// FUNCIONES DE AUTENTICACIÓN
// =====================================================

function autenticarUsuario($codigo_usuario, $password) {
    $sql = "SELECT * FROM usuarios WHERE codigo_usuario = ? AND password = MD5(?) AND activo = 1";
    $usuario = obtenerRegistro($sql, [$codigo_usuario, $password]);
    
    if ($usuario) {
        $_SESSION['usuario_id'] = $usuario['id'];
        $_SESSION['usuario_codigo'] = $usuario['codigo_usuario'];
        $_SESSION['usuario_nombre'] = $usuario['nombre'];
        $_SESSION['usuario_tipo'] = $usuario['tipo'];
        return true;
    }
    return false;
}

function verificarSesion($tipo_requerido = null) {
    if (!isset($_SESSION['usuario_id'])) {
        // Detectar la ruta correcta al index.php
        $index_path = '';
        if (file_exists('index.php')) {
            $index_path = 'index.php';
        } elseif (file_exists('../index.php')) {
            $index_path = '../index.php';
        } else {
            $index_path = '/Metru/index.php';
        }
        header('Location: ' . $index_path);
        exit();
    }
    
    if ($tipo_requerido && $_SESSION['usuario_tipo'] != $tipo_requerido) {
        // Si no es el tipo correcto, redirigir al index
        $index_path = '';
        if (file_exists('index.php')) {
            $index_path = 'index.php';
        } elseif (file_exists('../index.php')) {
            $index_path = '../index.php';
        } else {
            $index_path = '/Metru/index.php';
        }
        header('Location: ' . $index_path);
        exit();
    }
}

function cerrarSesion() {
    session_destroy();
    // Detectar la ruta correcta al index.php
    $index_path = '';
    if (file_exists('index.php')) {
        $index_path = 'index.php';
    } elseif (file_exists('../index.php')) {
        $index_path = '../index.php';
    } else {
        $index_path = '/Metru/index.php';
    }
    header('Location: ' . $index_path);
    exit();
}

// =====================================================
// FUNCIONES DE PRODUCTOS
// =====================================================

function obtenerTodosLosProductos() {
    $sql = "SELECT * FROM productos WHERE activo = 1 ORDER BY descripcion";
    return obtenerRegistros($sql);
}

function obtenerProductosPorGrupo($grupo_id) {
    $sql = "SELECT * FROM productos WHERE grupo_id = ? AND activo = 1 ORDER BY descripcion";
    return obtenerRegistros($sql, [$grupo_id]);
}

function buscarProductos($termino) {
    $sql = "SELECT * FROM productos WHERE descripcion LIKE ? AND activo = 1 ORDER BY descripcion LIMIT 20";
    return obtenerRegistros($sql, ["%$termino%"]);
}

function obtenerProductoPorId($id) {
    $sql = "SELECT * FROM productos WHERE id = ?";
    return obtenerRegistro($sql, [$id]);
}

// =====================================================
// FUNCIONES DE RUTAS
// =====================================================

function obtenerTodasLasRutas() {
    $sql = "SELECT * FROM rutas WHERE activa = 1 ORDER BY nombre";
    return obtenerRegistros($sql);
}

function obtenerRutaPorId($id) {
    $sql = "SELECT * FROM rutas WHERE id = ?";
    return obtenerRegistro($sql, [$id]);
}

// =====================================================
// FUNCIONES DE CLIENTES
// =====================================================

function obtenerClientesPorRuta($ruta_id) {
    $sql = "SELECT * FROM clientes WHERE ruta_id = ? AND activo = 1 ORDER BY nombre";
    return obtenerRegistros($sql, [$ruta_id]);
}

function obtenerClientePorId($id) {
    $sql = "SELECT c.*, r.nombre as ruta_nombre 
            FROM clientes c 
            JOIN rutas r ON c.ruta_id = r.id 
            WHERE c.id = ?";
    return obtenerRegistro($sql, [$id]);
}

// =====================================================
// FUNCIONES DE SALIDAS DE MERCANCÍA
// =====================================================

function crearSalidaMercancia($ruta_id, $usuario_id, $fecha_salida, $observaciones = '') {
    $sql = "INSERT INTO salidas_mercancia (ruta_id, usuario_id, fecha_salida, observaciones, estado) 
            VALUES (?, ?, ?, ?, 'preparando')";
    return insertarYObtenerID($sql, [$ruta_id, $usuario_id, $fecha_salida, $observaciones]);
}

function agregarProductoASalida($salida_id, $producto_id, $cantidad) {
    $sql = "INSERT INTO detalle_salidas (salida_id, producto_id, cantidad) 
            VALUES (?, ?, ?) 
            ON DUPLICATE KEY UPDATE cantidad = cantidad + ?";
    ejecutarConsulta($sql, [$salida_id, $producto_id, $cantidad, $cantidad]);
}

function obtenerSalidasDelDia($fecha = null) {
    if (!$fecha) $fecha = date('Y-m-d');
    
    $sql = "SELECT s.*, r.nombre as ruta_nombre, u.nombre as usuario_nombre 
            FROM salidas_mercancia s 
            JOIN rutas r ON s.ruta_id = r.id 
            JOIN usuarios u ON s.usuario_id = u.id 
            WHERE DATE(s.fecha_salida) = ? 
            ORDER BY s.fecha_creacion DESC";
    return obtenerRegistros($sql, [$fecha]);
}

function obtenerDetalleSalida($salida_id) {
    $sql = "SELECT ds.*, p.descripcion, p.unidad_medida, p.precio_publico 
            FROM detalle_salidas ds 
            JOIN productos p ON ds.producto_id = p.id 
            WHERE ds.salida_id = ? 
            ORDER BY p.descripcion";
    return obtenerRegistros($sql, [$salida_id]);
}

function actualizarEstadoSalida($salida_id, $estado) {
    $sql = "UPDATE salidas_mercancia SET estado = ? WHERE id = ?";
    ejecutarConsulta($sql, [$estado, $salida_id]);
}

// =====================================================
// FUNCIONES DE FACTURAS
// =====================================================

function crearFactura($salida_id, $cliente_id, $vendedor_id, $forma_pago, $total, $observaciones = '', $cliente_nombre = null, $cliente_ciudad = null) {
    // Generar número de factura automático
    $fecha = date('Y-m-d');
    
    // Si hay cliente_id, obtener su ruta
    if ($cliente_id) {
        $cliente = obtenerClientePorId($cliente_id);
        $ruta_id = $cliente['ruta_id'];
    } else {
        // Si no hay cliente_id, obtener la ruta de la salida
        $sql_ruta = "SELECT ruta_id FROM salidas_mercancia WHERE id = ?";
        $ruta_id = obtenerRegistro($sql_ruta, [$salida_id])['ruta_id'];
    }
    
    $numero_factura = generarNumeroFactura($ruta_id, $fecha);
    
    $sql = "INSERT INTO facturas (numero_factura, salida_id, cliente_id, vendedor_id, forma_pago, total, observaciones, cliente_nombre, cliente_ciudad) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    return insertarYObtenerID($sql, [$numero_factura, $salida_id, $cliente_id, $vendedor_id, $forma_pago, $total, $observaciones, $cliente_nombre, $cliente_ciudad]);
}

function agregarProductoAFactura($factura_id, $producto_id, $cantidad, $precio_unitario) {
    $subtotal = $cantidad * $precio_unitario;
    $sql = "INSERT INTO detalle_facturas (factura_id, producto_id, cantidad, precio_unitario, subtotal) 
            VALUES (?, ?, ?, ?, ?)";
    ejecutarConsulta($sql, [$factura_id, $producto_id, $cantidad, $precio_unitario, $subtotal]);
}

function obtenerFacturasPorSalida($salida_id) {
    $sql = "SELECT f.*, 
            COALESCE(c.nombre, f.cliente_nombre, 'Cliente General') as cliente_nombre, 
            u.nombre as vendedor_nombre 
            FROM facturas f 
            LEFT JOIN clientes c ON f.cliente_id = c.id 
            JOIN usuarios u ON f.vendedor_id = u.id 
            WHERE f.salida_id = ? 
            ORDER BY f.fecha_venta DESC";
    return obtenerRegistros($sql, [$salida_id]);
}

function obtenerFacturasPorVendedor($vendedor_id, $fecha = null) {
    if (!$fecha) $fecha = date('Y-m-d');
    
    $sql = "SELECT f.*, 
            COALESCE(c.nombre, f.cliente_nombre, 'Cliente General') as cliente_nombre 
            FROM facturas f 
            LEFT JOIN clientes c ON f.cliente_id = c.id 
            WHERE f.vendedor_id = ? AND DATE(f.fecha_venta) = ? 
            ORDER BY f.fecha_venta DESC";
    return obtenerRegistros($sql, [$vendedor_id, $fecha]);
}

function obtenerDetalleFactura($factura_id) {
    $sql = "SELECT df.*, p.descripcion, p.unidad_medida 
            FROM detalle_facturas df 
            JOIN productos p ON df.producto_id = p.id 
            WHERE df.factura_id = ? 
            ORDER BY p.descripcion";
    return obtenerRegistros($sql, [$factura_id]);
}

// =====================================================
// FUNCIONES DE REPORTES
// =====================================================

function obtenerResumenVentasPorRuta($ruta_id, $fecha = null) {
    if (!$fecha) $fecha = date('Y-m-d');
    
    $sql = "SELECT 
                COUNT(f.id) as total_facturas,
                SUM(f.total) as total_ventas,
                SUM(CASE WHEN f.forma_pago = 'efectivo' THEN f.total ELSE 0 END) as total_efectivo,
                SUM(CASE WHEN f.forma_pago = 'transferencia' THEN f.total ELSE 0 END) as total_transferencia,
                SUM(CASE WHEN f.forma_pago = 'pendiente' THEN f.total ELSE 0 END) as total_pendiente
            FROM facturas f 
            JOIN clientes c ON f.cliente_id = c.id 
            WHERE c.ruta_id = ? AND DATE(f.fecha_venta) = ?";
    return obtenerRegistro($sql, [$ruta_id, $fecha]);
}

function obtenerProductosVendidosPorSalida($salida_id) {
    $sql = "SELECT 
                p.id,
                p.descripcion,
                SUM(df.cantidad) as cantidad_vendida,
                SUM(df.subtotal) as total_vendido
            FROM detalle_facturas df 
            JOIN facturas f ON df.factura_id = f.id 
            JOIN productos p ON df.producto_id = p.id 
            WHERE f.salida_id = ? 
            GROUP BY p.id, p.descripcion 
            ORDER BY p.descripcion";
    return obtenerRegistros($sql, [$salida_id]);
}

function calcularDevolucionesEsperadas($salida_id) {
    $sql = "SELECT 
                p.id,
                p.descripcion,
                ds.cantidad as cantidad_salida,
                COALESCE(SUM(df.cantidad), 0) as cantidad_vendida,
                (ds.cantidad - COALESCE(SUM(df.cantidad), 0)) as cantidad_esperada
            FROM detalle_salidas ds 
            JOIN productos p ON ds.producto_id = p.id 
            LEFT JOIN detalle_facturas df ON p.id = df.producto_id 
                AND df.factura_id IN (SELECT id FROM facturas WHERE salida_id = ?)
            WHERE ds.salida_id = ? 
            GROUP BY p.id, p.descripcion, ds.cantidad 
            HAVING cantidad_esperada > 0
            ORDER BY p.descripcion";
    return obtenerRegistros($sql, [$salida_id, $salida_id]);
}

// =====================================================
// FUNCIONES AUXILIARES
// =====================================================

function generarNumeroFactura($ruta_id, $fecha) {
    // Para facturas sin cliente_id, contar todas las facturas de la ruta
    $sql = "SELECT COUNT(*) + 1 as siguiente 
            FROM facturas f 
            JOIN salidas_mercancia s ON f.salida_id = s.id
            WHERE s.ruta_id = ? AND DATE(f.fecha_venta) = ?";
    
    $resultado = obtenerRegistro($sql, [$ruta_id, $fecha]);
    
    return 'R' . $ruta_id . '-' . date('Ymd', strtotime($fecha)) . '-' . str_pad($resultado['siguiente'], 3, '0', STR_PAD_LEFT);
}

function formatearPrecio($precio) {
    // Validar que el precio no sea null o vacío
    if ($precio === null || $precio === '') {
        $precio = 0;
    }
    return '$' . number_format((float)$precio, 0, ',', '.');
}

function formatearFecha($fecha) {
    return date('d/m/Y', strtotime($fecha));
}

function formatearFechaHora($fecha) {
    return date('d/m/Y H:i', strtotime($fecha));
}

// =====================================================
// FUNCIONES DE VALIDACIÓN
// =====================================================

function validarRutaActiva($salida_id) {
    $sql = "SELECT estado FROM salidas_mercancia WHERE id = ?";
    $salida = obtenerRegistro($sql, [$salida_id]);
    return $salida && $salida['estado'] == 'en_ruta';

    
    // Los trabajadores solo pueden acceder a sus rutas asignadas
    $sql = "SELECT COUNT(*) as tiene_acceso 
            FROM salidas_mercancia s 
            WHERE s.id = ? AND s.usuario_id = ?";
    $resultado = obtenerRegistro($sql, [$salida_id, $usuario_id]);
    return $resultado['tiene_acceso'] > 0;
}

// =====================================================
// FUNCIONES DE MÚLTIPLES TRABAJADORES
// =====================================================

function asignarTrabajadorASalida($salida_id, $trabajador_id, $es_principal = false) {
    $sql = "INSERT INTO salida_trabajadores (salida_id, trabajador_id, es_principal) 
            VALUES (?, ?, ?) 
            ON DUPLICATE KEY UPDATE es_principal = ?";
    ejecutarConsulta($sql, [$salida_id, $trabajador_id, $es_principal ? 1 : 0, $es_principal ? 1 : 0]);
}

function obtenerTrabajadoresDeSalida($salida_id) {
    $sql = "SELECT u.*, st.es_principal 
            FROM salida_trabajadores st
            JOIN usuarios u ON st.trabajador_id = u.id
            WHERE st.salida_id = ?
            ORDER BY st.es_principal DESC, u.nombre";
    return obtenerRegistros($sql, [$salida_id]);
}

function validarAccesoRuta($usuario_id, $salida_id) {
    // Verificar en tabla de múltiples trabajadores primero
    $sql = "SELECT COUNT(*) as tiene_acceso 
            FROM salida_trabajadores 
            WHERE salida_id = ? AND trabajador_id = ?";
    $resultado = obtenerRegistro($sql, [$salida_id, $usuario_id]);
    
    if ($resultado && $resultado['tiene_acceso'] > 0) {
        return true;
    }
    
    // Si no está en salida_trabajadores, verificar método antiguo
    $sql = "SELECT COUNT(*) as tiene_acceso 
            FROM salidas_mercancia 
            WHERE id = ? AND usuario_id = ?";
    $resultado = obtenerRegistro($sql, [$salida_id, $usuario_id]);
    
    return $resultado && $resultado['tiene_acceso'] > 0;
}
// =====================================================
// FUNCIÓN PARA OBTENER USUARIO POR ID
// =====================================================
function obtenerUsuarioPorId($usuario_id) {
    $sql = "SELECT * FROM usuarios WHERE id = ?";
    return obtenerRegistro($sql, [$usuario_id]);
}

?>