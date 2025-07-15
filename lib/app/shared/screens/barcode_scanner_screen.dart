// lib/app/shared/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código de barras'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          final code = barcodeCapture.barcodes.first.rawValue;
          if (code != null) {
            // Usar GetX navigation para consistencia
            Get.back(result: code);
          }
        },
      ),
    );
  }
}
