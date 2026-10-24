import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<String> uploadImage(
    File file,
    String bucketName,
    String fileName,
  ) async {
    final storage = _supabase.storage.from(bucketName);
    await storage.upload(
      fileName,
      file,
      fileOptions: FileOptions(
        contentType: _contentType(fileName),
        upsert: false,
      ),
    );
    return storage.getPublicUrl(fileName);
  }

  Future<void> deleteImage(String bucketName, String filePath) async {
    if (filePath.isEmpty) return;
    await _supabase.storage.from(bucketName).remove([filePath]);
  }

  String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }
}