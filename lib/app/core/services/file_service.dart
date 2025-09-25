// lib/app/core/services/file_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;

class AttachmentFile {
  final String name;
  final int size;
  final String mimeType;
  final String path;
  final Uint8List? bytes;
  final bool isImage;

  AttachmentFile({
    required this.name,
    required this.size,
    required this.mimeType,
    required this.path,
    this.bytes,
    required this.isImage,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get extension {
    return name.split('.').last.toLowerCase();
  }

  bool get isPDF => mimeType == 'application/pdf';
  bool get isDocument => [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
  ].contains(mimeType);
}

abstract class FileService {
  Future<AttachmentFile?> pickImageFromCamera();
  Future<AttachmentFile?> pickImageFromGallery();
  Future<AttachmentFile?> pickFile();
  Future<List<AttachmentFile>> pickMultipleFiles({List<String>? allowedExtensions});
  Future<String> saveAttachment(AttachmentFile file);
  Future<void> deleteAttachment(String path);
  Future<AttachmentFile?> compressImage(AttachmentFile imageFile, {int quality = 85});
  String getAttachmentPath(String fileName);
}

class FileServiceImpl implements FileService {
  final ImagePicker _imagePicker = ImagePicker();
  
  // Límites de archivo
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB para imágenes
  
  @override
  Future<AttachmentFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

      if (bytes.length > maxImageSize) {
        // Comprimir imagen si es muy grande
        final compressedFile = await _compressImageFile(file);
        if (compressedFile != null) {
          final compressedBytes = await compressedFile.readAsBytes();
          return AttachmentFile(
            name: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
            size: compressedBytes.length,
            mimeType: 'image/jpeg',
            path: compressedFile.path,
            bytes: compressedBytes,
            isImage: true,
          );
        }
      }

      return AttachmentFile(
        name: 'camera_${DateTime.now().millisecondsSinceEpoch}.${_getExtensionFromMimeType(mimeType)}',
        size: bytes.length,
        mimeType: mimeType,
        path: file.path,
        bytes: bytes,
        isImage: true,
      );
    } catch (e) {
      throw FileServiceException('Error al tomar foto: $e');
    }
  }

  @override
  Future<AttachmentFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

      if (bytes.length > maxImageSize) {
        // Comprimir imagen si es muy grande
        final compressedFile = await _compressImageFile(file);
        if (compressedFile != null) {
          final compressedBytes = await compressedFile.readAsBytes();
          return AttachmentFile(
            name: image.name,
            size: compressedBytes.length,
            mimeType: 'image/jpeg',
            path: compressedFile.path,
            bytes: compressedBytes,
            isImage: true,
          );
        }
      }

      return AttachmentFile(
        name: image.name,
        size: bytes.length,
        mimeType: mimeType,
        path: file.path,
        bytes: bytes,
        isImage: true,
      );
    } catch (e) {
      throw FileServiceException('Error al seleccionar imagen: $e');
    }
  }

  @override
  Future<AttachmentFile?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final platformFile = result.files.first;
      final bytes = platformFile.bytes;
      
      if (bytes == null) {
        throw FileServiceException('No se pudo leer el archivo');
      }

      if (bytes.length > maxFileSize) {
        throw FileServiceException('El archivo es demasiado grande (máximo ${(maxFileSize / (1024 * 1024)).toInt()}MB)');
      }

      final mimeType = lookupMimeType(platformFile.name) ?? 'application/octet-stream';
      final isImage = mimeType.startsWith('image/');

      return AttachmentFile(
        name: platformFile.name,
        size: bytes.length,
        mimeType: mimeType,
        path: platformFile.path ?? '',
        bytes: bytes,
        isImage: isImage,
      );
    } catch (e) {
      if (e is FileServiceException) rethrow;
      throw FileServiceException('Error al seleccionar archivo: $e');
    }
  }

  @override
  Future<List<AttachmentFile>> pickMultipleFiles({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final attachments = <AttachmentFile>[];

      for (final platformFile in result.files) {
        final bytes = platformFile.bytes;
        
        if (bytes == null) continue;

        if (bytes.length > maxFileSize) {
          // Saltar archivos muy grandes pero continuar con los demás
          continue;
        }

        final mimeType = lookupMimeType(platformFile.name) ?? 'application/octet-stream';
        final isImage = mimeType.startsWith('image/');

        attachments.add(AttachmentFile(
          name: platformFile.name,
          size: bytes.length,
          mimeType: mimeType,
          path: platformFile.path ?? '',
          bytes: bytes,
          isImage: isImage,
        ));
      }

      return attachments;
    } catch (e) {
      throw FileServiceException('Error al seleccionar archivos: $e');
    }
  }

  @override
  Future<String> saveAttachment(AttachmentFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${directory.path}/attachments');
      
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '${attachmentsDir.path}/$fileName';
      
      final savedFile = File(filePath);
      await savedFile.writeAsBytes(file.bytes!);
      
      return filePath;
    } catch (e) {
      throw FileServiceException('Error al guardar archivo: $e');
    }
  }

  @override
  Future<void> deleteAttachment(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileServiceException('Error al eliminar archivo: $e');
    }
  }

  @override
  Future<AttachmentFile?> compressImage(AttachmentFile imageFile, {int quality = 85}) async {
    try {
      if (!imageFile.isImage || imageFile.bytes == null) return imageFile;

      final compressedFile = await _compressImageBytes(imageFile.bytes!, quality);
      if (compressedFile == null) return imageFile;

      return AttachmentFile(
        name: imageFile.name,
        size: compressedFile.length,
        mimeType: 'image/jpeg',
        path: imageFile.path,
        bytes: compressedFile,
        isImage: true,
      );
    } catch (e) {
      throw FileServiceException('Error al comprimir imagen: $e');
    }
  }

  @override
  String getAttachmentPath(String fileName) {
    return 'attachments/$fileName';
  }

  // Métodos privados auxiliares
  Future<File?> _compressImageFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final compressedBytes = await _compressImageBytes(bytes, 75);
      
      if (compressedBytes == null) return null;

      final directory = await getTemporaryDirectory();
      final compressedFile = File('${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _compressImageBytes(Uint8List bytes, int quality) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Redimensionar si es muy grande
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1080) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1080 : null,
        );
      }

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      return null;
    }
  }

  String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'application/pdf':
        return 'pdf';
      default:
        return 'file';
    }
  }
}

class FileServiceException implements Exception {
  final String message;
  
  FileServiceException(this.message);
  
  @override
  String toString() => message;
}