import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_item.dart';
import '../providers/admin_providers.dart';
import 'service_form_screen.dart';

class AdminServicesScreen extends ConsumerWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(adminServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: services.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          message: 'Impossible de charger les services.',
          onRetry: () => ref.invalidate(adminServicesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState(
              icon: Icons.design_services_outlined,
              message: 'Aucun service pour le moment.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(adminServicesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ServiceTile(service: items[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un service'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {ServiceItem? service}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ServiceFormScreen(service: service),
      ),
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  const _ServiceTile({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ServiceImage(url: service.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: theme.textTheme.titleMedium),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _priceLabel(service),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Actions du service',
              onSelected: (action) {
                if (action == 'edit') {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => ServiceFormScreen(service: service),
                    ),
                  );
                } else if (action == 'delete') {
                  _confirmDelete(context, ref);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le service ?'),
        content: Text('« ${service.name} » sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(adminServicesProvider.notifier).deleteService(service);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression incomplète : $error')),
        );
      }
    }
  }

  String _priceLabel(ServiceItem item) {
    if (item.unit == 'sur_devis') return 'Sur devis';
    final amount = item.price.toStringAsFixed(0);
    final unit = switch (item.unit) {
      'par_jour' => ' / jour',
      'par_nuit' => ' / nuit',
      _ => '',
    };
    return '$amount FCFA$unit';
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 84,
        height: 84,
        child: url == null || url!.isEmpty
            ? const _ImagePlaceholder()
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ImagePlaceholder(),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black12,
      child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}