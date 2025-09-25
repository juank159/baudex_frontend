// lib/features/purchase_orders/presentation/widgets/floating_action_menu.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/purchase_order.dart';

class FloatingActionMenu extends StatefulWidget {
  final PurchaseOrder order;
  final Function(String action)? onAction;

  const FloatingActionMenu({
    Key? key,
    required this.order,
    this.onAction,
  }) : super(key: key);

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _hoverScaleAnimation;
  late Animation<double> _hoverGlowAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isExpanded = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Animación principal del menú
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ElegantLightTheme.elasticCurve,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ElegantLightTheme.smoothCurve,
    ));

    // Animaciones de hover espectaculares
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hoverScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.elasticOut,
    ));
    _hoverGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    // Animación de respiración elegante
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animación de respiración
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop con blur
        if (_isExpanded)
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _scaleAnimation.value.clamp(0.0, 1.0),
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        
        // Menu items
        ..._buildMenuItems(),
        
        // Main button
        _buildMainButton(),
      ],
    );
  }

  List<Widget> _buildMenuItems() {
    final actions = _getAvailableActions();
    final List<Widget> items = [];
    
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      items.add(
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            final offset = (i + 1) * 70.0;
            return Transform.translate(
              offset: Offset(0, -offset * _scaleAnimation.value.clamp(0.0, 1.0)),
              child: Transform.scale(
                scale: _scaleAnimation.value.clamp(0.0, 1.0),
                child: _buildMenuItem(
                  action['title'],
                  action['icon'],
                  action['gradient'],
                  () => _executeAction(action['action']),
                ),
              ),
            );
          },
        ),
      );
    }
    
    return items;
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return _SpectacularMenuItem(
      title: title,
      icon: icon,
      gradient: gradient,
      onTap: onTap,
    );
  }

  Widget _buildMainButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationAnimation,
        _hoverScaleAnimation,
        _hoverGlowAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHoverStart(),
          onExit: (_) => _onHoverEnd(),
          child: GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Resplandor holográfico
                  _buildHolographicGlow(),
                  
                  // Botón principal con efectos elegantes
                  Transform.scale(
                    scale: _hoverScaleAnimation.value * _pulseAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ElegantLightTheme.primaryGradient.colors.first,
                            ElegantLightTheme.primaryGradient.colors.last,
                            Color.lerp(
                              ElegantLightTheme.primaryGradient.colors.last,
                              Colors.purple,
                              _hoverGlowAnimation.value * 0.3,
                            )!,
                          ],
                          stops: [0.0, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          // Sombra base elegante
                          ...ElegantLightTheme.glowShadow,
                          // Sombra de hover espectacular
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue.withOpacity(
                              0.4 + (_hoverGlowAnimation.value * 0.4)
                            ),
                            blurRadius: 15 + (_hoverGlowAnimation.value * 25),
                            spreadRadius: 2 + (_hoverGlowAnimation.value * 8),
                            offset: const Offset(0, 0),
                          ),
                          // Resplandor mágico
                          BoxShadow(
                            color: Colors.white.withOpacity(
                              _hoverGlowAnimation.value * 0.3
                            ),
                            blurRadius: 30 + (_hoverGlowAnimation.value * 20),
                            spreadRadius: -5,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Efectos de brillo interno
                          _buildInternalShimmer(),
                          
                          // Icono con rotación y efectos
                          Transform.rotate(
                            angle: _rotationAnimation.value * 3.14159,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _isExpanded ? Icons.close : Icons.add,
                                key: ValueKey(_isExpanded),
                                color: Colors.white,
                                size: 30 + (_hoverGlowAnimation.value * 5),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Métodos para los efectos espectaculares
  void _onHoverStart() {
    if (!_isHovered) {
      setState(() => _isHovered = true);
      _hoverController.forward();
    }
  }

  void _onHoverEnd() {
    if (_isHovered) {
      setState(() => _isHovered = false);
      _hoverController.reverse();
    }
  }



  Widget _buildHolographicGlow() {
    return Container(
      width: 80 + (_hoverGlowAnimation.value * 40),
      height: 80 + (_hoverGlowAnimation.value * 40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.transparent,
            ElegantLightTheme.primaryBlue.withOpacity(
              _hoverGlowAnimation.value * 0.1
            ),
            Colors.purple.withOpacity(_hoverGlowAnimation.value * 0.05),
            Colors.transparent,
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildInternalShimmer() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _pulseAnimation.value * 2, 0),
              end: Alignment(1.0 + _pulseAnimation.value * 2, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(_hoverGlowAnimation.value * 0.15),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }


  List<Map<String, dynamic>> _getAvailableActions() {
    final List<Map<String, dynamic>> actions = [];
    
    switch (widget.order.status) {
      case PurchaseOrderStatus.draft:
        actions.addAll([
          {
            'title': 'Enviar para Revisión',
            'icon': Icons.send,
            'gradient': ElegantLightTheme.infoGradient,
            'action': 'submit_for_review',
          },
          {
            'title': 'Editar',
            'icon': Icons.edit,
            'gradient': ElegantLightTheme.warningGradient,
            'action': 'edit',
          },
        ]);
        break;
        
      case PurchaseOrderStatus.pending:
        actions.addAll([
          {
            'title': 'Aprobar & Enviar',
            'icon': Icons.send,
            'gradient': ElegantLightTheme.successGradient,
            'action': 'approve_and_send',
          },
          {
            'title': 'Solo Aprobar',
            'icon': Icons.check,
            'gradient': ElegantLightTheme.infoGradient,
            'action': 'approve',
          },
        ]);
        break;
        
      case PurchaseOrderStatus.approved:
        actions.add({
          'title': 'Enviar al Proveedor',
          'icon': Icons.send,
          'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
          'action': 'send',
        });
        break;
        
      case PurchaseOrderStatus.sent:
        actions.addAll([
          {
            'title': 'Recepción Rápida',
            'icon': Icons.flash_on,
            'gradient': ElegantLightTheme.successGradient,
            'action': 'quick_receive',
          },
          {
            'title': 'Recepción Custom',
            'icon': Icons.tune,
            'gradient': ElegantLightTheme.warningGradient,
            'action': 'custom_receive',
          },
        ]);
        break;
        
      case PurchaseOrderStatus.partiallyReceived:
        // Verificar si realmente quedan productos por recibir
        final hasPendingItems = widget.order.items.any((item) => 
          item.receivedQuantity == null || item.receivedQuantity! < item.quantity
        );
        
        if (hasPendingItems && !widget.order.isFullyReceived) {
          // Aún quedan productos por recibir
          actions.addAll([
            {
              'title': 'Completar Recepción',
              'icon': Icons.flash_on,
              'gradient': ElegantLightTheme.successGradient,
              'action': 'quick_receive',
            },
            {
              'title': 'Recepción Custom',
              'icon': Icons.tune,
              'gradient': ElegantLightTheme.warningGradient,
              'action': 'custom_receive',
            },
          ]);
        } else {
          // Orden completamente recibida - mostrar opciones de orden recibida
          actions.addAll([
            {
              'title': 'Ver Lotes Generados',
              'icon': Icons.inventory,
              'gradient': ElegantLightTheme.infoGradient,
              'action': 'view_batches',
            },
            {
              'title': 'Actualizar Estado',
              'icon': Icons.refresh,
              'gradient': ElegantLightTheme.successGradient,
              'action': 'refresh_status',
            },
          ]);
        }
        break;
        
      case PurchaseOrderStatus.received:
        actions.addAll([
          {
            'title': 'Ver Lotes',
            'icon': Icons.inventory,
            'gradient': ElegantLightTheme.infoGradient,
            'action': 'view_batches',
          },
          {
            'title': 'Duplicar',
            'icon': Icons.copy,
            'gradient': ElegantLightTheme.warningGradient,
            'action': 'duplicate',
          },
        ]);
        break;
        
      default:
        break;
    }
    
    return actions;
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _executeAction(String action) {
    _toggleMenu(); // Cerrar el menu
    if (widget.onAction != null) {
      widget.onAction!(action);
    }
  }
}

// Widget separado para los elementos del menú con efectos espectaculares
class _SpectacularMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _SpectacularMenuItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_SpectacularMenuItem> createState() => _SpectacularMenuItemState();
}

class _SpectacularMenuItemState extends State<_SpectacularMenuItem>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _rippleController.forward(from: 0);
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _onHover(bool isHovered) {
    if (isHovered != _isHovered) {
      setState(() => _isHovered = isHovered);
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Tamaños responsive para el FloatingActionMenu
    double fontSize = screenWidth >= 1200 ? 14 : screenWidth >= 800 ? 12 : 10;
    double horizontalPadding = screenWidth >= 1200 ? 12 : screenWidth >= 800 ? 10 : 8;
    double verticalPadding = screenWidth >= 1200 ? 8 : screenWidth >= 800 ? 6 : 4;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 8),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _glowAnimation,
          _pulseAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label mejorado con efectos responsivos
              Transform.scale(
                scale: _scaleAnimation.value * 0.95 + 0.05,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ElegantLightTheme.cardGradient.colors.first,
                        ElegantLightTheme.cardGradient.colors.last,
                        Color.lerp(
                          ElegantLightTheme.cardGradient.colors.last,
                          widget.gradient.colors.first,
                          _glowAnimation.value * 0.1,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color.lerp(
                        ElegantLightTheme.textSecondary.withOpacity(0.1),
                        widget.gradient.colors.first.withOpacity(0.3),
                        _glowAnimation.value,
                      )!,
                      width: 1,
                    ),
                    boxShadow: [
                      ...ElegantLightTheme.elevatedShadow,
                      BoxShadow(
                        color: widget.gradient.colors.first.withOpacity(
                          _glowAnimation.value * 0.3
                        ),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: Color.lerp(
                        ElegantLightTheme.textPrimary,
                        widget.gradient.colors.first,
                        _glowAnimation.value * 0.3,
                      ),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      shadows: _glowAnimation.value > 0.5
                          ? [
                              Shadow(
                                color: widget.gradient.colors.first.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón espectacular con múltiples efectos
              MouseRegion(
                onEnter: (_) => _onHover(true),
                onExit: (_) => _onHover(false),
                child: GestureDetector(
                  onTapDown: (_) => _onTapDown(),
                  onTapUp: (_) => _onTapUp(),
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: Transform.scale(
                    scale: _scaleAnimation.value * _pulseAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Efecto ripple
                        if (_rippleAnimation.value > 0)
                          Container(
                            width: 50 + (_rippleAnimation.value * 30),
                            height: 50 + (_rippleAnimation.value * 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.gradient.colors.first.withOpacity(
                                  (1 - _rippleAnimation.value) * 0.6
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        
                        // Resplandor de fondo
                        Container(
                          width: 70 + (_glowAnimation.value * 20),
                          height: 70 + (_glowAnimation.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.transparent,
                                widget.gradient.colors.first.withOpacity(
                                  _glowAnimation.value * 0.1
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        
                        // Botón principal
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.gradient.colors.first,
                                widget.gradient.colors.last,
                                Color.lerp(
                                  widget.gradient.colors.last,
                                  Colors.white,
                                  _glowAnimation.value * 0.2,
                                )!,
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradient.colors.first.withOpacity(
                                  0.4 + (_glowAnimation.value * 0.3)
                                ),
                                offset: const Offset(0, 4),
                                blurRadius: 12 + (_glowAnimation.value * 15),
                                spreadRadius: 2 + (_glowAnimation.value * 4),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(
                                  _glowAnimation.value * 0.4
                                ),
                                offset: const Offset(0, 0),
                                blurRadius: 20,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Brillo interno animado
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      gradient: LinearGradient(
                                        begin: Alignment(-1.0 + _pulseAnimation.value * 2, 0),
                                        end: Alignment(1.0 + _pulseAnimation.value * 2, 0),
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(
                                            _glowAnimation.value * 0.3
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              // Icono con efectos
                              Transform.scale(
                                scale: _isPressed ? 0.9 : 1.0,
                                child: Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 24 + (_glowAnimation.value * 4),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: const Offset(2, 2),
                                    ),
                                    if (_glowAnimation.value > 0.3)
                                      Shadow(
                                        color: Colors.white.withOpacity(0.8),
                                        blurRadius: 15,
                                        offset: const Offset(0, 0),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Efectos de destello en hover
                        if (_isHovered && _glowAnimation.value > 0.5)
                          ...List.generate(4, (i) {
                            final angle = (i * math.pi * 0.5) + (_pulseAnimation.value * math.pi);
                            return Transform.translate(
                              offset: Offset(
                                25 * math.cos(angle),
                                25 * math.sin(angle),
                              ),
                              child: Transform.scale(
                                scale: _glowAnimation.value,
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white.withOpacity(
                                    _glowAnimation.value * 0.7
                                  ),
                                  size: 8,
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}