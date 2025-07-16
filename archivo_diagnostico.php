<?php
// =====================================================
// DIAGNÓSTICO COMPLETO - SISTEMA METRU
// =====================================================

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Evitar caché
header("Cache-Control: no-cache, must-revalidate");
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Diagnóstico del Sistema - Metru</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .check-ok { color: green; font-weight: bold; }
        .check-error { color: red; font-weight: bold; }
        .check-warning { color: orange; font-weight: bold; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
<div class="container mt-4">
    <h1>🔍 Diagnóstico del Sistema Metru</h1>
    <hr>
    
    <?php
    $errores = 0;
    $advertencias = 0;
    
    // 1. VERIFICAR ARCHIVOS CRÍTICOS
    echo '<h3>📁 Archivos del Sistema</h3>';
    echo '<table class="table table-bordered">';
    echo '<thead><tr><th>Archivo</th><th>Estado</th><th>Ubicación</th></tr></thead><tbody>';
    
    $archivos_verificar = [
        'includes/modal_detalle_factura.php' => 'Modal de detalle factura',
        'includes/seccion_gastos_ruta.php' => 'Sección gastos de ruta',
        'includes/ajax_detalle_factura.php' => 'AJAX detalle factura',
        'includes/validar_trabajadores.php' => 'Validar trabajadores',
        'includes/functions.php' => 'Funciones principales',
        'config/database.php' => 'Configuración BD',
        'admin/index.php' => 'Dashboard admin',
        'admin/salidas.php' => 'Gestión salidas',
        'admin/cierres.php' => 'Cierres de ruta',
        'trabajador/index.php' => 'Panel trabajador',
        'sw.js' => 'Service Worker (debe estar renombrado)',
        'js/offline-handler.js' => 'Manejador offline'
    ];
    
    foreach ($archivos_verificar as $archivo => $descripcion) {
        $existe = file_exists($archivo);
        $clase = $existe ? 'check-ok' : 'check-error';
        $texto = $existe ? 'OK' : 'NO EXISTE';
        if (!$existe && $archivo != 'sw.js') $errores++;
        
        // Caso especial para sw.js
        if ($archivo == 'sw.js') {
            if ($existe) {
                $clase = 'check-warning';
                $texto = 'ADVERTENCIA: Debe renombrarse para desarrollo';
                $advertencias++;
            } else if (file_exists('sw.js.bak')) {
                $clase = 'check-ok';
                $texto = 'OK (renombrado a .bak)';
            }
        }
        
        echo "<tr>";
        echo "<td>$descripcion</td>";
        echo "<td class='$clase'>$texto</td>";
        echo "<td><small>$archivo</small></td>";
        echo "</tr>";
    }
    echo '</tbody></table>';
    
    // 2. VERIFICAR BASE DE DATOS
    echo '<h3>🗄️ Base de Datos</h3>';
    
    try {
        include_once 'config/database.php';
        echo '<p class="check-ok">✓ Conexión exitosa</p>';
        
        // Verificar tablas críticas
        $tablas_requeridas = [
            'usuarios' => 'Usuarios del sistema',
            'salidas_mercancia' => 'Salidas de mercancía',
            'salida_trabajadores' => 'Asignación múltiples trabajadores',
            'facturas' => 'Facturas',
            'productos' => 'Productos',
            'gastos_ruta' => 'Gastos de ruta'
        ];
        
        echo '<table class="table table-bordered">';
        echo '<thead><tr><th>Tabla</th><th>Estado</th><th>Registros</th></tr></thead><tbody>';
        
        foreach ($tablas_requeridas as $tabla => $descripcion) {
            try {
                $stmt = $pdo->query("SELECT COUNT(*) as total FROM $tabla");
                $resultado = $stmt->fetch();
                echo "<tr>";
                echo "<td>$descripcion</td>";
                echo "<td class='check-ok'>EXISTE</td>";
                echo "<td>{$resultado['total']} registros</td>";
                echo "</tr>";
            } catch (Exception $e) {
                echo "<tr>";
                echo "<td>$descripcion</td>";
                echo "<td class='check-error'>NO EXISTE</td>";
                echo "<td>-</td>";
                echo "</tr>";
                $errores++;
            }
        }
        echo '</tbody></table>';
        
        // Verificar columnas críticas
        echo '<h4>Columnas Críticas</h4>';
        $verificaciones = [
            "SHOW COLUMNS FROM facturas LIKE 'cliente_nombre'" => 'facturas.cliente_nombre',
            "SHOW COLUMNS FROM facturas LIKE 'cliente_ciudad'" => 'facturas.cliente_ciudad',
            "SHOW COLUMNS FROM salida_trabajadores LIKE 'es_principal'" => 'salida_trabajadores.es_principal'
        ];
        
        foreach ($verificaciones as $query => $descripcion) {
            try {
                $stmt = $pdo->query($query);
                $existe = $stmt->rowCount() > 0;
                $clase = $existe ? 'check-ok' : 'check-error';
                $texto = $existe ? '✓ Existe' : '✗ No existe';
                if (!$existe) $errores++;
                echo "<p class='$clase'>$descripcion: $texto</p>";
            } catch (Exception $e) {
                echo "<p class='check-error'>$descripcion: Error verificando</p>";
                $errores++;
            }
        }
        
    } catch (Exception $e) {
        echo '<p class="check-error">✗ Error de conexión: ' . $e->getMessage() . '</p>';
        $errores++;
    }
    
    // 3. VERIFICAR CONFIGURACIONES
    echo '<h3>⚙️ Configuraciones</h3>';
    
    // Timezone
    $timezone = date_default_timezone_get();
    echo "<p>Zona horaria: <strong>$timezone</strong></p>";
    
    // PHP Version
    $php_version = phpversion();
    $php_ok = version_compare($php_version, '7.4.0', '>=');
    $clase = $php_ok ? 'check-ok' : 'check-error';
    echo "<p class='$clase'>PHP Version: $php_version " . ($php_ok ? '✓' : '✗ (Requiere 7.4+)') . "</p>";
    
    // Service Worker Status
    echo '<h4>Service Worker</h4>';
    if (file_exists('sw.js')) {
        echo '<p class="check-warning">⚠️ sw.js existe - Puede causar problemas de caché en desarrollo</p>';
        echo '<p>Recomendación: Renombrar a sw.js.bak durante desarrollo</p>';
        $advertencias++;
    } else {
        echo '<p class="check-ok">✓ Service Worker desactivado (correcto para desarrollo)</p>';
    }
    
    // 4. RESUMEN
    echo '<hr>';
    echo '<h3>📊 Resumen</h3>';
    
    if ($errores == 0 && $advertencias == 0) {
        echo '<div class="alert alert-success">';
        echo '<h4>✅ Sistema OK</h4>';
        echo '<p>No se detectaron errores. El sistema está listo para usar.</p>';
        echo '</div>';
    } else {
        echo '<div class="alert alert-' . ($errores > 0 ? 'danger' : 'warning') . '">';
        echo '<h4>' . ($errores > 0 ? '❌ Errores detectados' : '⚠️ Advertencias') . '</h4>';
        echo "<p>Errores: $errores | Advertencias: $advertencias</p>";
        echo '</div>';
    }
    
    // 5. RECOMENDACIONES
    echo '<h3>💡 Recomendaciones</h3>';
    echo '<ol>';
    echo '<li>Limpiar caché del navegador (Ctrl + Shift + R)</li>';
    echo '<li>Verificar que todos los archivos includes estén en /Metru/includes/</li>';
    echo '<li>Ejecutar el script de optimización en la base de datos</li>';
    echo '<li>Desactivar Service Worker durante desarrollo</li>';
    echo '<li>Usar Chrome DevTools > Network > Disable cache durante desarrollo</li>';
    echo '</ol>';
    
    // 6. ACCIONES RÁPIDAS
    echo '<h3>🚀 Acciones Rápidas</h3>';
    echo '<div class="btn-group">';
    echo '<a href="admin/index.php" class="btn btn-primary">Dashboard Admin</a>';
    echo '<a href="trabajador/index.php" class="btn btn-info">Panel Trabajador</a>';
    echo '<a href="index.php" class="btn btn-secondary">Login</a>';
    echo '</div>';
    ?>
    
    <hr>
    <p class="text-muted">
        Diagnóstico generado: <?php echo date('Y-m-d H:i:s'); ?><br>
        <small>Sistema Metru - Diagnóstico v1.0</small>
    </p>
</div>

<script>
// Verificar Service Worker en el navegador
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
        if (registrations.length > 0) {
            console.warn('Service Workers activos:', registrations.length);
            alert('⚠️ Hay Service Workers activos. Esto puede causar problemas de caché.\n\nVe a DevTools > Application > Service Workers y desregístralos.');
        }
    });
}
</script>
</body>
</html>