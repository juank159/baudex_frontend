# Guía de Shortcuts - Gestión de Productos en Facturas

Este documento explica todos los shortcuts de teclado disponibles en el widget `EnhancedInvoiceItemsWidget` para la gestión rápida de productos en facturas.

## Shortcuts Implementados

### 🔢 Gestión de Cantidades

| Shortcut | Acción | Descripción |
|----------|--------|-------------|
| `Shift + 1-9` | Incrementar cantidad específica | Incrementa la cantidad del producto seleccionado por el número presionado |
| `Shift + +` | Incrementar +1 | Incrementa la cantidad en 1 unidad |
| `Shift + -` | Decrementar -1 | Decrementa la cantidad en 1 unidad |

### 🧭 Navegación

| Shortcut | Acción | Descripción |
|----------|--------|-------------|
| `↑` | Navegar arriba | Selecciona el producto anterior en la lista |
| `↓` | Navegar abajo | Selecciona el siguiente producto en la lista |
| `Home` | Primer producto | Selecciona el primer producto de la lista |
| `End` | Último producto | Selecciona el último producto de la lista |
| `Page Up` | Scroll arriba | Desplaza la vista hacia arriba |
| `Page Down` | Scroll abajo | Desplaza la vista hacia abajo |

### ⚙️ Acciones Especiales

| Shortcut | Acción | Descripción |
|----------|--------|-------------|
| `Shift + Enter` | Procesar venta | Procesa la factura actual y la finaliza |
| `Shift + Delete` | Eliminar producto | Elimina el producto seleccionado de la factura |
| `Ctrl + D` | Duplicar producto | Duplica el producto seleccionado con la misma cantidad |
| `Ctrl + Shift + C` | Limpiar todo | Elimina todos los productos de la factura (con confirmación) |

## Características Avanzadas

### 🎯 Selección Visual
- El producto seleccionado se resalta con borde azul
- Indicador visual "ACTIVO" con ícono de teclado
- Los controles de cantidad y precio cambian de color para indicar actividad

### 🛡️ Validaciones de Stock
- Los shortcuts respetan las limitaciones de stock de productos reales
- Productos temporales (sin ID fijo) no tienen restricciones de stock
- Mensajes de error claros cuando se excede el stock disponible

### 📱 Feedback Visual
- Snackbars informativos para cada acción realizada
- Confirmaciones para acciones destructivas (eliminar, limpiar)
- Indicadores de cantidad actualizada en tiempo real

## Uso Práctico

### Flujo Típico de Trabajo
1. **Agregar productos**: Usar el widget de búsqueda de productos
2. **Seleccionar producto**: Click o navegación con flechas
3. **Ajustar cantidad**: Usar números (1-9) para incrementar rápidamente
4. **Cantidades exactas**: Usar Ctrl + número para establecer cantidad específica
5. **Duplicar si necesario**: Ctrl + D para productos similares
6. **Eliminar errores**: Delete o Backspace para productos incorrectos

### Casos de Uso Avanzados

#### Incrementos Rápidos
```
Producto seleccionado: "Camisa"
- Presionar "Shift + 5" → Cantidad aumenta en 5 unidades
- Presionar "Shift + +" → Cantidad aumenta en 1 unidad
- Presionar "Shift + -" → Cantidad disminuye en 1 unidad
```

#### Navegación Eficiente
```
Lista de 20 productos:
- "Home" → Selecciona producto #1
- "↓↓↓" → Navega a producto #4
- "End" → Salta al producto #20
- "Page Up" → Scroll rápido hacia arriba
```

#### Gestión de Errores
```
Producto incorrecto agregado:
- Navegar hasta el producto → "↑" o "↓"
- Eliminarlo → "Shift + Delete"
- O duplicar el correcto → Seleccionar correcto + "Ctrl + D"
- Procesar venta → "Shift + Enter"
```

## Implementación Técnica

### Componentes Principales
- `_handleKeyEvent()`: Maneja todos los eventos de teclado
- `_selectedIndex`: Mantiene el índice del producto actualmente seleccionado
- `_focusNode`: Gestiona el foco para capturar eventos de teclado

### Estados de Teclas Modificadoras
- `_isShiftPressed`: Detecta cuando Shift está presionado
- `_isCtrlPressed`: Detecta cuando Ctrl está presionado

### Métodos de Acción
- `_incrementQuantity()`: Incrementa cantidad con validaciones
- `_decrementQuantity()`: Decrementa cantidad con límites
- `_setExactQuantity()`: Establece cantidad exacta
- `_duplicateSelectedItem()`: Duplica producto seleccionado
- `_clearAllItems()`: Limpia toda la lista con confirmación

## Tips de Productividad

1. **Mantén el foco**: Siempre asegúrate de que el widget tenga foco para usar shortcuts
2. **Combinaciones rápidas**: Usa Shift + números para incrementos grandes
3. **Navegación fluida**: Combina Home/End con flechas para moverte rápidamente
4. **Duplicación inteligente**: Usa Ctrl + D para productos similares en lugar de buscarlos nuevamente
5. **Limpieza rápida**: Ctrl + Shift + C para empezar de cero cuando sea necesario

## Compatibilidad

### Plataformas Soportadas
- ✅ Windows (todas las teclas)
- ✅ macOS (Cmd tratado como Ctrl)
- ✅ Linux (todas las teclas)
- ⚠️ Web (algunos shortcuts pueden tener conflictos con el navegador)

### Consideraciones Móviles
- Los shortcuts están diseñados principalmente para desktop
- En móvil se mantiene la funcionalidad táctil normal
- La selección visual funciona tanto en desktop como móvil