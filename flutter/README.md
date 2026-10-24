# Élite Prestations

Application Flutter d’administration des services et des réalisations, avec Supabase Storage et Riverpod.

## Configuration

Renseignez l’URL et la clé anon de votre projet Supabase au lancement :

```sh
cd flutter
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Exécutez [`supabase/schema.sql`](supabase/schema.sql) dans l’éditeur SQL Supabase. Le rôle d’administration doit être défini dans `app_metadata.role` avec la valeur `ADMIN`. Les buckets `services` et `gallery` sont publics pour l’affichage des images ; les écritures et suppressions restent réservées aux administrateurs par les politiques SQL.

Le schéma requiert les colonnes utilisées par l’application : `services(name, description, price, unit, image_url, image_path, created_at)` et `gallery(category, caption, image_url, image_path, created_at)`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
