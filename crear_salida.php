<?php
// =====================================================
// CREAR NUEVA SALIDA DE MERCANCÍA - SISTEMA METRU
// =====================================================

include_once '../includes/functions.php';
verificarSesion('admin');

$titulo_pagina = 'Crear Nueva Salida de Mercancía';
$icono_pagina = 'fas fa-plus-circle';

// Obtener datos necesarios
$rutas = obtenerTodasLasRutas();
$trabajadores = obtenerRegistros("SELECT * FROM usuarios WHERE tipo = 'trabajador' AND activo = 1 ORDER BY nombre");

// Procesar formulario
if ($_POST && isset($_POST['accion']) && $_POST['accion'] == 'crear_salida') {
    $ruta_id = $_POST['ruta_id'] ?? 0;
    $responsable_id = $_POST['responsable_id'] ?? 0;
    $fecha_salida = $_POST['fecha_salida'] ?? date('Y-m-d');
    $observaciones = $_POST['observaciones'] ?? '';
    $productos = $_POST['productos'] ?? [];
    
    // Validaciones
    $errores = [];
    
    if (!$ruta_id) {
        $errores[] = "Debe seleccionar una ruta";
    }
    
    if (!$responsable_id) {
        $errores[] = "Debe seleccionar un responsable";
    }
    
    if (empty($productos)) {
        $errores[] = "Debe agregar al menos un producto";
    }
    
    // Validar que no exista una salida activa para la misma ruta en la misma fecha
    $salida_existente = obtenerRegistro(
        "SELECT id FROM salidas_mercancia WHERE ruta_id = ? AND DATE(fecha_salida) = ? AND estado != 'finalizada'",
        [$ruta_id, $fecha_salida]
    );
    
    if ($salida_existente) {
        $errores[] = "Ya existe una salida activa para esta ruta en la fecha seleccionada";
    }
    
    // Si no hay errores, crear la salida
    if (empty($errores)) {
        try {
            global $pdo;
            $pdo->beginTransaction();
            
            // Crear la salida
            $salida_id = crearSalidaMercancia($ruta_id, $responsable_id, $fecha_salida, $observaciones);
            
            // Agregar productos
            foreach ($productos as $producto_data) {
                $producto_id = $producto_data['producto_id'] ?? 0;
                $cantidad = $producto_data['cantidad'] ?? 0;
                
                if ($producto_id && $cantidad > 0) {
                    agregarProductoASalida($salida_id, $producto_id, $cantidad);
                }
            }
            
            $pdo->commit();
            
            $_SESSION['mensaje'] = 'Salida creada exitosamente';
            $_SESSION['tipo_mensaje'] = 'success';
            
            header('Location: detalle_salida.php?id=' . $salida_id);
            exit();
            
        } catch (Exception $e) {
            $pdo->rollback();
            $errores[] = "Error al crear la salida: " . $e->getMessage();
        }
    }
    
    if (!empty($errores)) {
        $_SESSION['mensaje'] = implode('<br>', $errores);
        $_SESSION['tipo_mensaje'] = 'danger';
    }
}

include '../includes/header.php';
?>

<!-- Mostrar mensajes -->
<?php if (isset($_SESSION['mensaje'])): ?>
    <div class="alert alert-<?php echo $_SESSION['tipo_mensaje'] ?? 'info'; ?> alert-dismissible fade show" role="alert">
        <?php 
        echo $_SESSION['mensaje'];
        unset($_SESSION['mensaje']);
        unset($_SESSION['tipo_mensaje']);
        ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<form method="POST" action="" id="form-crear-salida">
    <input type="hidden" name="accion" value="crear_salida">
    
    <div class="row">
        <!-- Información básica -->
        <div class="col-md-4">
            <div class="card mb-4">
                <div class="card-header">
                    <h6 class="m-0 font-weight-bold">
                        <i class="fas fa-info-circle"></i> Información de la Salida
                    </h6>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label for="ruta_id" class="form-label">Ruta <span class="text-danger">*</span></label>
                        <select class="form-select" id="ruta_id" name="ruta_id" required>
                            <option value="">Seleccione una ruta</option>
                            <?php foreach ($rutas as $ruta): ?>
                                <option value="<?php echo $ruta['id']; ?>">
                                    <?php echo htmlspecialchars($ruta['nombre']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label for="responsable_id" class="form-label">Responsable <span class="text-danger">*</span></label>
                        <select class="form-select" id="responsable_id" name="responsable_id" required>
                            <option value="">Seleccione un trabajador</option>
                            <?php foreach ($trabajadores as $trabajador): ?>
                                <option value="<?php echo $trabajador['id']; ?>">
                                    <?php echo htmlspecialchars($trabajador['nombre']); ?> 
                                    (<?php echo $trabajador['codigo_usuario']; ?>)
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label for="fecha_salida" class="form-label">Fecha de Salida <span class="text-danger">*</span></label>
                        <input type="date" class="form-control" id="fecha_salida" name="fecha_salida" 
                               value="<?php echo date('Y-m-d'); ?>" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="observaciones" class="form-label">Observaciones</label>
                        <textarea class="form-control" id="observaciones" name="observaciones" 
                                  rows="3" placeholder="Observaciones adicionales (opcional)"></textarea>
                    </div>
                </div>
            </div>
            
            <!-- Resumen -->
            <div class="card">
                <div class="card-header">
                    <h6 class="m-0 font-weight-bold">
                        <i class="fas fa-chart-bar"></i> Resumen
                    </h6>
                </div>
                <div class="card-body">
                    <div class="d-flex justify-content-between mb-2">
                        <span>Total Productos:</span>
                        <strong id="total-productos">0</strong>
                    </div>
                    <div class="d-flex justify-content-between">
                        <span>Total Unidades:</span>
                        <strong id="total-unidades">0</strong>
                    </div>
                </div>
                <div class="card-footer">
                    <button type="submit" class="btn btn-primary w-100">
                        <i class="fas fa-save"></i> Crear Salida
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Productos -->
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">
                    <h6 class="m-0 font-weight-bold">
                        <i class="fas fa-boxes"></i> Productos de la Salida
                    </h6>
                </div>
                <div class="card-body">
                    <!-- Buscador -->
                    <div class="mb-4">
                        <label for="buscar-producto" class="form-label">Buscar Producto</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-search"></i>
                            </span>
                            <input type="text" 
                                   class="form-control" 
                                   id="buscar-producto" 
                                   placeholder="Escriba el nombre o código del producto..."
                                   autocomplete="off">
                        </div>
                        <small class="text-muted">
                            Escriba al menos 2 caracteres para buscar
                        </small>
                    </div>
                    
                    <!-- Resultados de búsqueda -->
                    <div id="resultados-busqueda"></div>
                    
                    <!-- Productos seleccionados -->
                    <hr>
                    <h6 class="mb-3">
                        <i class="fas fa-clipboard-list"></i> Productos Seleccionados
                    </h6>
                    <div id="productos-seleccionados">
                        <div class="alert alert-info text-center">
                            <i class="fas fa-box-open fa-2x mb-2"></i>
                            <p class="mb-0">No hay productos agregados. Use el buscador para agregar productos.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- AGREGAR ESTE CÓDIGO JUSTO ANTES DEL CIERRE </body> EN crear_salida.php -->
    <style>
    /* Forzar visibilidad de resultados */
    #resultados-busqueda {
        display: block !important;
        visibility: visible !important;
        opacity: 1 !important;
        background-color: white !important;
        min-height: 50px;
        margin-top: 10px;
    }

    #resultados-busqueda:not(:empty) {
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 10px;
    }

    .list-group-item {
        display: block !important;
        padding: 12px !important;
        margin-bottom: 8px !important;
        background: white !important;
        border: 1px solid #ddd !important;
        border-radius: 8px !important;
        cursor: pointer !important;
    }

    .list-group-item:hover {
        background-color: #f8f9fa !important;
        border-color: #007bff !important;
    }
    </style>

    <script>
    // Parche para asegurar que la función funcione
    $(document).ready(function() {
        console.log('🔧 Aplicando parche de visualización...');
        
        // Sobrescribir la función mostrarResultadosProductos si existe problemas
        const mostrarResultadosProductosOriginal = window.mostrarResultadosProductos;
        
        window.mostrarResultadosProductos = function(productos) {
            console.log('📋 Mostrando productos (versión parcheada):', productos.length);
            
            // Limpiar primero
            $('#resultados-busqueda').empty();
            
            if (!productos || productos.length === 0) {
                $('#resultados-busqueda').html(`
                    <div class="alert alert-warning">
                        <i class="fas fa-search"></i> No se encontraron productos
                    </div>
                `);
                return;
            }
            
            // Crear lista
            let html = '<div class="list-group">';
            
            productos.forEach(function(producto) {
                const yaAgregado = $(`.producto-item[data-producto-id="${producto.id}"]`).length > 0;
                
                html += `
                    <div class="list-group-item ${yaAgregado ? 'disabled opacity-50' : ''}" 
                        onclick="${yaAgregado ? '' : 'agregarProductoDirecto(' + producto.id + ', \'' + producto.descripcion.replace(/'/g, "\\'") + '\', \'' + producto.unidad_medida + '\', ' + producto.precio_publico + ')'}"
                        style="cursor: ${yaAgregado ? 'not-allowed' : 'pointer'};">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <strong>${producto.descripcion}</strong><br>
                                <small class="text-muted">
                                    <i class="fas fa-barcode"></i> ${producto.codigo} • 
                                    <i class="fas fa-cube"></i> ${producto.unidad_medida}
                                </small>
                            </div>
                            <div class="text-end">
                                <div class="h6 mb-0 text-success">$${Number(producto.precio_publico).toLocaleString('es-CO')}</div>
                                <small class="${yaAgregado ? 'text-muted' : 'text-primary'}">
                                    ${yaAgregado ? '✓ Agregado' : '+ Agregar'}
                                </small>
                            </div>
                        </div>
                    </div>
                `;
            });
            
            html += '</div>';
            
            // Insertar y mostrar
            $('#resultados-busqueda').html(html);
            
            // Verificar que se insertó
            console.log('✅ Productos mostrados en el DOM');
        };
        
        // Función auxiliar para agregar productos
        window.agregarProductoDirecto = function(id, descripcion, unidad, precio) {
            const producto = {
                id: id,
                descripcion: descripcion,
                unidad_medida: unidad,
                precio_publico: precio
            };
            
            if (typeof agregarProductoASalida !== 'undefined') {
                agregarProductoASalida(producto);
            } else {
                alert('Producto seleccionado: ' + descripcion);
            }
        };
    });
    </script>
</form>

<!-- Cargar JavaScript específico -->
<script src="../js/crear_salida.js"></script>

<?php include '../includes/footer.php'; ?>