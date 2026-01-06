// lib/features/credit_notes/data/datasources/credit_note_local_datasource.dart

import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/credit_note_model.dart';
import '../models/isar/isar_credit_note.dart';

/// Contrato para el datasource local de notas de crédito
abstract class CreditNoteLocalDataSource {
  Future<void> cacheCreditNotes(List<CreditNoteModel> creditNotes);
  Future<List<CreditNoteModel>> getCachedCreditNotes();
  Future<void> cacheCreditNote(CreditNoteModel creditNote);
  Future<CreditNoteModel?> getCachedCreditNote(String id);
  Future<void> removeCachedCreditNote(String id);
  Future<void> clearCreditNoteCache();
  Future<bool> isCacheValid();
}

/// Implementación del datasource local usando SecureStorage
class CreditNoteLocalDataSourceImpl implements CreditNoteLocalDataSource {
  final SecureStorageService storageService;

  // Keys para el almacenamiento
  static const String _creditNotesKey = 'cached_credit_notes';
  static const String _creditNoteKeyPrefix = 'cached_credit_note_';
  static const String _cacheTimestampKey = 'credit_notes_cache_timestamp';

  // Cache válido por 30 minutos
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  const CreditNoteLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> cacheCreditNotes(List<CreditNoteModel> creditNotes) async {
    try {
      final creditNotesJson = creditNotes.map((cn) => cn.toJson()).toList();
      await storageService.write(_creditNotesKey, json.encode(creditNotesJson));
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar notas de crédito en cache: $e');
    }
  }

  @override
  Future<List<CreditNoteModel>> getCachedCreditNotes() async {
    try {
      final creditNotesData = await storageService.read(_creditNotesKey);
      if (creditNotesData == null) {
        throw CacheException.notFound;
      }

      final creditNotesJson = json.decode(creditNotesData) as List;
      return creditNotesJson
          .map((json) => CreditNoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener notas de crédito del cache: $e');
    }
  }

  @override
  Future<void> cacheCreditNote(CreditNoteModel creditNote) async {
    try {
      // ✅ GUARDAR EN ISAR PRIMERO (persistencia offline real)
      try {
        final isar = IsarDatabase.instance.database;
        await isar.writeTxn(() async {
          // Buscar si existe
          var isarCreditNote = await isar.isarCreditNotes
              .filter()
              .serverIdEqualTo(creditNote.id)
              .findFirst();

          if (isarCreditNote != null) {
            // Actualizar existente
            isarCreditNote.updateFromModel(creditNote);
          } else {
            // Crear nuevo
            isarCreditNote = IsarCreditNote.fromModel(creditNote);
          }

          // Guardar nota de crédito con items embebidos
          await isar.isarCreditNotes.put(isarCreditNote);
        });
        print('✅ CreditNote guardada en ISAR con ${creditNote.items.length} items: ${creditNote.id}');
      } catch (e) {
        print('⚠️ Error guardando en ISAR (continuando...): $e');
      }

      // Guardar en SecureStorage (fallback legacy)
      final creditNoteKey = '$_creditNoteKeyPrefix${creditNote.id}';
      await storageService.write(creditNoteKey, json.encode(creditNote.toJson()));

      // También actualizar la lista principal
      try {
        final creditNotesData = await storageService.read(_creditNotesKey);
        List<CreditNoteModel> creditNotes = [];

        if (creditNotesData != null) {
          final creditNotesJson = json.decode(creditNotesData) as List;
          creditNotes = creditNotesJson
              .map((json) => CreditNoteModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Buscar si la nota ya existe y actualizarla, o agregarla si es nueva
        final existingIndex = creditNotes.indexWhere((cn) => cn.id == creditNote.id);
        if (existingIndex >= 0) {
          creditNotes[existingIndex] = creditNote;
          print('📝 Nota de crédito actualizada en lista principal: ${creditNote.id}');
        } else {
          creditNotes.add(creditNote);
          print('➕ Nota de crédito agregada a lista principal: ${creditNote.id}');
        }

        // Guardar lista actualizada
        final creditNotesJson = creditNotes.map((cn) => cn.toJson()).toList();
        await storageService.write(_creditNotesKey, json.encode(creditNotesJson));
      } catch (e) {
        print('⚠️ Error actualizando lista principal (solo cache individual guardado): $e');
      }

      await _updateCacheTimestamp();
    } catch (e) {
      // Fallar silenciosamente en lugar de lanzar excepción
      // Esto permite que la app funcione aunque el cache no esté disponible
      print('⚠️ Cache no disponible (continuando sin cache): $e');
    }
  }

  @override
  Future<CreditNoteModel?> getCachedCreditNote(String id) async {
    try {
      final creditNoteKey = '$_creditNoteKeyPrefix$id';
      final creditNoteData = await storageService.read(creditNoteKey);

      if (creditNoteData == null) {
        return null;
      }

      final creditNoteJson = json.decode(creditNoteData) as Map<String, dynamic>;
      return CreditNoteModel.fromJson(creditNoteJson);
    } catch (e) {
      throw CacheException('Error al obtener nota de crédito del cache: $e');
    }
  }

  @override
  Future<void> removeCachedCreditNote(String id) async {
    try {
      // Eliminar nota de crédito individual
      final creditNoteKey = '$_creditNoteKeyPrefix$id';
      await storageService.delete(creditNoteKey);

      // También eliminar de la lista principal
      try {
        final creditNotesData = await storageService.read(_creditNotesKey);
        if (creditNotesData != null) {
          final creditNotesJson = json.decode(creditNotesData) as List;
          final creditNotes = creditNotesJson
              .map((json) => CreditNoteModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Remover nota de crédito de la lista
          creditNotes.removeWhere((cn) => cn.id == id);

          // Guardar lista actualizada
          final updatedCreditNotesJson = creditNotes.map((cn) => cn.toJson()).toList();
          await storageService.write(_creditNotesKey, json.encode(updatedCreditNotesJson));
          print('🗑️ Nota de crédito eliminada de lista principal: $id');
        }
      } catch (e) {
        print('⚠️ Error eliminando de lista principal (solo cache individual eliminado): $e');
      }
    } catch (e) {
      throw CacheException('Error al eliminar nota de crédito del cache: $e');
    }
  }

  @override
  Future<void> clearCreditNoteCache() async {
    try {
      // Limpiar cache general
      await storageService.delete(_creditNotesKey);
      await storageService.delete(_cacheTimestampKey);

      // Limpiar notas de crédito individuales
      final allData = await storageService.readAll();
      for (final key in allData.keys) {
        if (key.startsWith(_creditNoteKeyPrefix)) {
          await storageService.delete(key);
        }
      }
    } catch (e) {
      throw CacheException('Error al limpiar cache de notas de crédito: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final timestampData = await storageService.read(_cacheTimestampKey);
      if (timestampData == null) {
        return false;
      }

      final timestamp = DateTime.parse(timestampData);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      return difference <= _cacheValidDuration;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar timestamp del cache
  Future<void> _updateCacheTimestamp() async {
    try {
      final now = DateTime.now().toIso8601String();
      await storageService.write(_cacheTimestampKey, now);
    } catch (e) {
      print('Error al actualizar timestamp del cache: $e');
    }
  }
}
