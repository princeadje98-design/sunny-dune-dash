# Sunny Dune Dash — jeu Android (Flutter) + AdMob

Jeu de course de buggy 100 % original : pilote en glissant le doigt, évite les rochers,
ramasse pièces et turbos.

## Pubs intégrées
- **Bannière** : menu + écran de crash
- **Interstitielle** : toutes les 3 parties
- **Vidéo récompensée** : « Continuer » après un crash (1 fois par partie)

## Installation
```bash
flutter create --org com.tonnom --project-name sunny_dune_dash sunny_dune_dash
# copie lib/ et pubspec.yaml de ce dossier dans le projet créé (remplace les existants)
cd sunny_dune_dash
flutter pub get
```

### Android : `android/app/src/main/AndroidManifest.xml`
Dans la balise `<application ...>`, ajoute :
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```
(ID de TEST. Remplace par l'ID de ton application AdMob à la publication.)

Dans `android/app/build.gradle(.kts)`, vérifie `minSdk = 23` (ou plus).

### Lancer
```bash
flutter run
```

## Passer en production
1. Crée un compte sur https://admob.google.com puis ajoute ton app → tu obtiens l'App ID et 3 Ad Unit IDs.
2. Mets l'App ID dans AndroidManifest.xml.
3. Dans `lib/ad_manager.dart` : remplis les `_real...` et passe `kUseTestAds = false`.
4. Ajoute une **politique de confidentialité** (obligatoire sur Google Play).
5. Si tu cibles l'Europe : ajoute le formulaire de consentement UMP (package `google_mobile_ads` → `ConsentInformation`).
6. Ne clique JAMAIS sur tes propres pubs réelles (risque de bannissement).
7. Génère le bundle : `flutter build appbundle --release`.
