<?php
// =====================================================
// VERIFICACIÓN DEL SISTEMA - METRU
// =====================================================
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verificación del Sistema - Metru</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .check-item { 
            padding: 10px; 
            margin: 5px 0; 
            border-radius: 5px; 
            background: #f8f9fa; 
        }
        .success { background-color: #d4edda !important; color: #155724; }
        .error { background-color: #f8d7da !important; color: #721c24; }
        .warning { background-color: #fff3cd !important; color: #856404; }
    </style>
</head>
<body>
    <div class="container mt-4">
        <h1 class="mb-4">🔧 Verificación del Sistema Metru</h1>
        
        <?php
        $errores = 0;
        $advertencias = 0;
        
        // 1. Verificar estructura de carpetas
        echo '<div class="card mb-3">';
        echo '<div class="card-header"><h5>📁 Estructura de Carpetas</h5></div>';
        echo '<div class="card-body">';
        
        $carpetas = [
            'admin',
            'trabajador',
            'config',
            'includes',
            'css',
            'js',
            'uploads',
            'logs'
        ];
        
        foreach ($carpetas as $carpeta) {
            if (is_dir($carpeta)) {
                echo '<div class="check-item success">✅ /' . $carpeta . '</div>';
            } else {
                echo '<div class="check-item error">❌ /' . $carpeta . ' - NO EXISTE</div>';
                $errores++;
            }
        }
        echo '</div></div>';
        
        // 2. Verificar archivos críticos
        echo '<div class="card mb-3">';
        echo '<div class="card-header"><h5>📄 Archivos Críticos</h5></div>';
        echo '<div class="card-body">';
        
        $archivos = [
            'config/config.php' => 'Configuración principal',
            'config/database.php' => 'Conexión a base de datos',
            'config/db.php' => 'Alias de base de datos',
            'includes/functions.php' => 'Funciones del sistema',
            'includes/buscar_productos.php' => 'Búsqueda de productos',
            'index.php' => 'Página de inicio'
        ];
        
        foreach ($archivos as $archivo => $descripcion) {
            if (file_exists($archivo)) {
                echo '<div class="check-item success">✅ ' . $archivo . ' - ' . $descripcion . '</div>';
            } else {
                echo '<div class="check-item error">❌ ' . $archivo . ' - ' . $descripcion . ' NO EXISTE</div>';
                if (in_array($archivo, ['config/config.php', 'config/database.php', 'includes/functions.php'])) {
                    $errores++;
                } else {
                    $advertencias++;
                }
            }
        }
        echo '</div></div>';
        
        // 3. Verificar conexión a base de datos
        echo '<div class="card mb-3">';
        echo '<div class="card-header"><h5>🗄️ Base de Datos</h5></div>';
        echo '<div class="card-body">';
        
        try {
            include_once 'config/database.php';
            echo '<div class="check-item success">✅ Conexión establecida</div>';
            
            // Verificar tablas
            $tablas_requeridas = [
                'usuarios',
                'productos',
                'rutas',
                'clientes',
                'salidas_mercancia',
                'detalle_salidas',
                'facturas',
                'detalle_facturas',
                'devoluciones'
            ];
            
            $stmt = $pdo->query("SHOW TABLES");
            $tablas_existentes = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            foreach ($tablas_requeridas as $tabla) {
                if (in_array($tabla, $tablas_existentes)) {
                    // Contar registros
                    $count = $pdo->query("SELECT COUNT(*) FROM $tabla")->fetchColumn();
                    echo '<div class="check-item success">✅ Tabla: ' . $tabla . ' (' . $count . ' registros)</div>';
                } else {
                    echo '<div class="check-item error">❌ Tabla: ' . $tabla . ' NO EXISTE</div>';
                    $errores++;
                }
            }
            
        } catch (Exception $e) {
            echo '<div class="check-item error">❌ Error de conexión: ' . $e->getMessage() . '</div>';
            $errores++;
        }
        echo '</div></div>';
        
        // 4. Verificar PHP y extensiones
        echo '<div class="card mb-3">';
        echo '<div class="card-header"><h5>🔧 Configuración PHP</h5></div>';
        echo '<div class="card-body">';
        
        echo '<div class="check-item success">✅ PHP Version: ' . phpversion() . '</div>';
        
        $extensiones = ['pdo', 'pdo_mysql', 'session', 'json', 'mbstring'];
        foreach ($extensiones as $ext) {
            if (extension_loaded($ext)) {
                echo '<div class="check-item success">✅ Extensión ' . $ext . ' cargada</div>';
            } else {
                echo '<div class="check-item error">❌ Extensión ' . $ext . ' NO disponible</div>';
                $errores++;
            }
        }
        echo '</div></div>';
        
        // 5. Verificar permisos de escritura
        echo '<div class="card mb-3">';
        echo '<div class="card-header"><h5>📝 Permisos de Escritura</h5></div>';
        echo '<div class="card-body">';
        
        $carpetas_escritura = ['uploads', 'logs'];
        foreach ($carpetas_escritura as $carpeta) {
            if (is_dir($carpeta) && is_writable($carpeta)) {
                echo '<div class="check-item success">✅ /' . $carpeta . ' - Escritura OK</div>';
            } elseif (is_dir($carpeta)) {
                echo '<div class="check-item warning">⚠️ /' . $carpeta . ' - Sin permisos de escritura</div>';
                $advertencias++;
            }
        }
        echo '</div></div>';
        
        // Resumen
        echo '<div class="card mb-3">';
        echo '<div class="card-header"><h5>📊 Resumen</h5></div>';
        echo '<div class="card-body">';
        
        if ($errores == 0 && $advertencias == 0) {
            echo '<div class="alert alert-success">';
            echo '<h4>✅ Sistema funcionando correctamente</h4>';
            echo '<p>Todos los componentes están configurados correctamente.</p>';
            echo '<a href="index.php" class="btn btn-primary">Ir al Sistema</a>';
            echo '</div>';
        } elseif ($errores > 0) {
            echo '<div class="alert alert-danger">';
            echo '<h4>❌ Se encontraron ' . $errores . ' errores críticos</h4>';
            echo '<p>Es necesario corregir estos errores antes de usar el sistema.</p>';
            echo '</div>';
        } else {
            echo '<div class="alert alert-warning">';
            echo '<h4>⚠️ Se encontraron ' . $advertencias . ' advertencias</h4>';
            echo '<p>El sistema puede funcionar pero se recomienda revisar las advertencias.</p>';
            echo '<a href="index.php" class="btn btn-primary">Ir al Sistema</a>';
            echo '</div>';
        }
        
        echo '</div></div>';
        ?>
        
        <div class="text-center mb-4">
            <button onclick="location.reload()" class="btn btn-secondary">
                <i class="bi bi-arrow-clockwise"></i> Verificar Nuevamente
            </button>
        </div>
    </div>
</body>
</html>