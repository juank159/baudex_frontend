// lib/app/shared/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanning = true;

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return; // Prevenir múltiples escaneados
    
    final code = barcodeCapture.barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      setState(() {
        _isScanning = false; // Detener escaneado
      });
      
      // Pequeño delay para evitar conflictos de navegación
      Future.delayed(const Duration(milliseconds: 100), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código de barras'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              Navigator.of(context).pop();
            } catch (e) {
              Get.back();
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onBarcodeDetect,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Apunta la cámara hacia el código de barras',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
