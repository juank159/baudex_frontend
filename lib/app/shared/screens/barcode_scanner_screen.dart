// lib/app/shared/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import '../../core/theme/elegant_light_theme.dart';
import '../../core/utils/responsive_helper.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return; // Prevenir múltiples escaneados

    final code = barcodeCapture.barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      setState(() {
        _isScanning = false; // Detener escaneado
      });

      // Feedback visual de éxito
      _showSuccessAnimation(code);

      // Pequeño delay para mostrar animación antes de cerrar
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          // Intentar ambos métodos de navegación para compatibilidad
          try {
            Navigator.of(context).pop(code);
          } catch (e) {
            Get.back(result: code);
          }
        }
      });
    }
  }

  void _showSuccessAnimation(String code) {
    // Mostrar feedback de éxito
    Get.snackbar(
      '¡Código detectado!',
      code,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(milliseconds: 600),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context, isMobile),
      body: Stack(
        children: [
          // Escáner de código de barras
          MobileScanner(onDetect: _onBarcodeDetect),

          // Overlay con marco de escaneo
          _buildScannerOverlay(context, isMobile),

          // Instrucciones en la parte inferior
          _buildInstructions(context, isMobile),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isMobile) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () {
          try {
            Navigator.of(context).pop();
          } catch (e) {
            Get.back();
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: isMobile ? 18 : 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Escanear Código',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 16 : 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context, bool isMobile) {
    return Center(
      child: Container(
        width: isMobile ? 280 : 320,
        height: isMobile ? 280 : 320,
        decoration: BoxDecoration(
          border: Border.all(color: ElegantLightTheme.primaryBlue, width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Esquinas decorativas
            _buildCorner(Alignment.topLeft, isMobile),
            _buildCorner(Alignment.topRight, isMobile),
            _buildCorner(Alignment.bottomLeft, isMobile),
            _buildCorner(Alignment.bottomRight, isMobile),

            // Línea de escaneo animada
            if (_isScanning)
              AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _scanLineAnimation.value * (isMobile ? 260 : 300),
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            ElegantLightTheme.primaryBlue.withValues(
                              alpha: 0.8,
                            ),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment, bool isMobile) {
    final size = isMobile ? 40.0 : 50.0;
    final thickness = 4.0;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            top:
                alignment == Alignment.topLeft ||
                        alignment == Alignment.topRight
                    ? BorderSide(color: Colors.white, width: thickness)
                    : BorderSide.none,
            left:
                alignment == Alignment.topLeft ||
                        alignment == Alignment.bottomLeft
                    ? BorderSide(color: Colors.white, width: thickness)
                    : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                        alignment == Alignment.bottomRight
                    ? BorderSide(color: Colors.white, width: thickness)
                    : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                        alignment == Alignment.bottomRight
                    ? BorderSide(color: Colors.white, width: thickness)
                    : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft:
                alignment == Alignment.topLeft
                    ? const Radius.circular(20)
                    : Radius.zero,
            topRight:
                alignment == Alignment.topRight
                    ? const Radius.circular(20)
                    : Radius.zero,
            bottomLeft:
                alignment == Alignment.bottomLeft
                    ? const Radius.circular(20)
                    : Radius.zero,
            bottomRight:
                alignment == Alignment.bottomRight
                    ? const Radius.circular(20)
                    : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context, bool isMobile) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono principal
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: isMobile ? 32 : 40,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Texto de instrucciones
              Text(
                'Apunta la cámara hacia el código de barras',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El escaneo se realizará automáticamente',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),

              // Estado de escaneo
              if (!_isScanning) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¡Código detectado!',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
