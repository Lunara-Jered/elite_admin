import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/admin_providers.dart';

class GalleryFormScreen extends ConsumerStatefulWidget {
  const GalleryFormScreen({super.key});

  @override
  ConsumerState<GalleryFormScreen> createState() => _GalleryFormScreenState();
}

class _GalleryFormScreenState extends ConsumerState<GalleryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _captionController = TextEditingController();
  File? _image;
  bool _saving = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une réalisation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Photo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            InkWell(
              onTap: _saving ? null : _chooseImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? const ColoredBox(
                        color: Color(0xFFF1F1F1),
                        child: Center(
                          child: Icon(Icons.add_photo_alternate_outlined, size: 42),
                        ),
                      )
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saving ? null : _chooseImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choisir une image'),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                hintText: 'Mariage, entreprise...',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Saisissez une catégorie.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _captionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Légende',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _image = File(picked.path));
    } catch (error) {
      if (mounted) _showError('Impossible de choisir cette image : $error');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      _showError('Choisissez une image pour la galerie.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(adminGalleryProvider.notifier).addPhoto(
            image: _image!,
            category: _categoryController.text,
            caption: _captionController.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showError('Enregistrement impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}