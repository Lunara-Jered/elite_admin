import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/service_item.dart';
import '../providers/admin_providers.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({super.key, this.service});

  final ServiceItem? service;

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late String _unit;
  File? _image;
  bool _saving = false;

  static const _units = <String, String>{
    'par_jour': 'Par jour',
    'par_nuit': 'Par nuit',
    'forfait': 'Forfait',
    'sur_devis': 'Sur devis',
  };

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name ?? '');
    _descriptionController =
        TextEditingController(text: service?.description ?? '');
    _priceController = TextEditingController(
      text: service == null || service.unit == 'sur_devis'
          ? ''
          : service.price.toStringAsFixed(0),
    );
    _unit = _units.containsKey(service?.unit) ? service!.unit : 'forfait';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Modifier le service' : 'Nouveau service')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _imagePicker(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom du service',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Saisissez un nom.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Saisissez une description.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _unit,
              decoration: const InputDecoration(
                labelText: 'Unité de facturation',
                border: OutlineInputBorder(),
              ),
              items: _units.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _unit = value);
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              enabled: !_saving && _unit != 'sur_devis',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _unit == 'sur_devis' ? 'Prix défini sur devis' : 'Prix (FCFA)',
                border: const OutlineInputBorder(),
                suffixText: _unit == 'sur_devis' ? null : 'FCFA',
              ),
              validator: (value) {
                if (_unit == 'sur_devis') return null;
                final price = double.tryParse((value ?? '').replaceAll(',', '.'));
                if (price == null || price < 0) return 'Saisissez un prix valide.';
                return null;
              },
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

  Widget _imagePicker() {
    final currentImage = widget.service?.imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Image du service', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        InkWell(
          onTap: _saving ? null : _chooseImage,
          child: Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover)
                : currentImage != null && currentImage.isNotEmpty
                    ? Image.network(
                        currentImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _ChooseImagePlaceholder(),
                      )
                    : const _ChooseImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _chooseImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choisir une image'),
        ),
      ],
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
    if (_image == null && widget.service?.imageUrl == null) {
      _showError('Choisissez une image pour ce service.');
      return;
    }

    setState(() => _saving = true);
    try {
      final parsedPrice = _unit == 'sur_devis'
          ? 0.0
          : double.parse(_priceController.text.replaceAll(',', '.'));
      await ref.read(adminServicesProvider.notifier).saveService(
            existing: widget.service,
            name: _nameController.text,
            description: _descriptionController.text,
            price: parsedPrice,
            unit: _unit,
            image: _image,
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

class _ChooseImagePlaceholder extends StatelessWidget {
  const _ChooseImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1F1F1),
      child: Center(child: Icon(Icons.add_photo_alternate_outlined, size: 42)),
    );
  }
}