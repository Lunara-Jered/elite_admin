import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/storage_service.dart';
import '../models/gallery_item.dart';
import '../models/service_item.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final adminServicesProvider =
    AsyncNotifierProvider<AdminServicesNotifier, List<ServiceItem>>(
  AdminServicesNotifier.new,
);

final adminGalleryProvider =
    AsyncNotifierProvider<AdminGalleryNotifier, List<GalleryItem>>(
  AdminGalleryNotifier.new,
);

class AdminServicesNotifier extends AsyncNotifier<List<ServiceItem>> {
  SupabaseClient get _client => Supabase.instance.client;
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<List<ServiceItem>> build() async => _load();

  Future<List<ServiceItem>> _load() async {
    final rows = await _client
        .from('services')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => ServiceItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveService({
    ServiceItem? existing,
    required String name,
    required String description,
    required num price,
    required String unit,
    File? image,
  }) async {
    String? uploadedPath;
    var persisted = false;
    try {
      var imageUrl = existing?.imageUrl;
      var imagePath = existing?.imagePath;
      if (image != null) {
        uploadedPath = _newImagePath(image);
        imageUrl = await _storage.uploadImage(image, 'services', uploadedPath);
        imagePath = uploadedPath;
      }

      final values = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'unit': unit,
        'image_url': imageUrl,
        'image_path': imagePath,
      };

      if (existing == null) {
        await _client.from('services').insert(values);
      } else {
        await _client.from('services').update(values).eq('id', existing.id);
      }
      persisted = true;

      final oldPath = existing?.imagePath;
      if (uploadedPath != null && oldPath != null && oldPath.isNotEmpty) {
        await _storage.deleteImage('services', oldPath);
      }
    } catch (_) {
      if (!persisted && uploadedPath != null) {
        try {
          await _storage.deleteImage('services', uploadedPath);
        } catch (_) {}
      }
      rethrow;
    } finally {
      await _refresh();
    }
  }

  Future<void> deleteService(ServiceItem service) async {
    try {
      await _client.from('services').delete().eq('id', service.id);
      final path = service.imagePath;
      if (path != null && path.isNotEmpty) {
        await _storage.deleteImage('services', path);
      }
    } finally {
      await _refresh();
    }
  }

  Future<void> _refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

class AdminGalleryNotifier extends AsyncNotifier<List<GalleryItem>> {
  SupabaseClient get _client => Supabase.instance.client;
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<List<GalleryItem>> build() async => _load();

  Future<List<GalleryItem>> _load() async {
    final rows = await _client
        .from('gallery')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => GalleryItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addPhoto({
    required File image,
    required String category,
    required String caption,
  }) async {
    final imagePath = _newImagePath(image);
    var persisted = false;
    try {
      final imageUrl = await _storage.uploadImage(image, 'gallery', imagePath);
      await _client.from('gallery').insert({
        'category': category.trim(),
        'caption': caption.trim(),
        'image_url': imageUrl,
        'image_path': imagePath,
      });
      persisted = true;
    } catch (_) {
      if (!persisted) {
        try {
          await _storage.deleteImage('gallery', imagePath);
        } catch (_) {}
      }
      rethrow;
    } finally {
      await _refresh();
    }
  }

  Future<void> deletePhoto(GalleryItem photo) async {
    try {
      await _client.from('gallery').delete().eq('id', photo.id);
      if (photo.imagePath.isNotEmpty) {
        await _storage.deleteImage('gallery', photo.imagePath);
      }
    } finally {
      await _refresh();
    }
  }

  Future<void> _refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

String _newImagePath(File image) {
  final extension = image.path.contains('.')
      ? image.path.split('.').last.toLowerCase()
      : 'jpg';
  return '${DateTime.now().microsecondsSinceEpoch}.$extension';
}