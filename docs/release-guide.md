# Release build guide — JerzyUczy

Krok po kroku jak zbudować podpisany **Android App Bundle (AAB)** do uploadu na
Google Play Console.

---

## 1. Utworzenie keystore (jeden raz)

Keystore to plik z kluczem prywatnym którym podpisujesz wszystkie release
buildy. **Jeśli zgubisz lub stracisz hasło — nigdy więcej nie wypuścisz
aktualizacji aplikacji** (Google traktuje nowy keystore jak nową aplikację).
Zadbaj:
- **Backup** keystore w **3 miejscach** (dysk lokalny + chmura prywatna +
  np. USB trzymany offline)
- **Hasła zapisz w menedżerze haseł** (1Password, Bitwarden, KeePass)
- **Nigdy** nie commituj keystore do git

### Komenda (PowerShell/Bash, z katalogu głównego projektu)

```bash
keytool -genkey -v -keystore ~/jerzyuczy-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias jerzyuczy
```

**Parametry:**
- `-keystore` — ścieżka do pliku keystore (**poza** repo, np.
  `C:\Users\soswa\keystores\jerzyuczy-release.jks`)
- `-validity 10000` — ważność 27 lat (Google wymaga min. do roku 2033)
- `-alias` — nazwa klucza (bierze się z niej nazwa w pliku properties)

Keytool zapyta:
1. **Password for keystore** — zapisz w password managerze
2. **First/last name** — Twoje imię (publicznie nie widoczne)
3. **Organizational unit/organization** — puste Enter
4. **City/State/Country** — np. Warszawa / mazowieckie / PL
5. **Password for key** — może być to samo co keystore password

Po komendzie masz plik `jerzyuczy-release.jks`. **Skopiuj w 3 bezpieczne
miejsca.**

---

## 2. Konfiguracja w projekcie Flutter

### 2a. Plik `android/key.properties` (NIE COMMITUJ)

Utwórz plik `D:\myApps\teachMe\android\key.properties`:

```properties
storePassword=TWOJE_HASLO_DO_KEYSTORE
keyPassword=TWOJE_HASLO_DO_KLUCZA
keyAlias=jerzyuczy
storeFile=C:/Users/soswa/keystores/jerzyuczy-release.jks
```

**Uwaga:** `storeFile` używa forward-slashy nawet na Windows.

### 2b. Dodaj `key.properties` do `.gitignore`

Sprawdź czy w `D:\myApps\teachMe\.gitignore` jest:

```
# Android signing (NIGDY nie commituj keystore ani haseł)
/android/key.properties
**/*.jks
**/*.keystore
```

Jeśli nie ma — dopisz (Claude dopisze przy następnej edycji).

### 2c. Modyfikacja `android/app/build.gradle.kts`

Do sekcji `android { ... }` dodaj:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... (istniejące namespace, compileSdk itd.) ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

**Zamiast** starego `signingConfig = signingConfigs.getByName("debug")`.

Claude zrobi tę modyfikację razem z update `.gitignore` gdy powiesz „jedź z
keystorem".

---

## 3. Build AAB (Android App Bundle)

Po skonfigurowaniu keystore, w terminalu:

```bash
cd D:/myApps/teachMe
flutter build appbundle --release
```

Wynik: **`build/app/outputs/bundle/release/app-release.aab`**

AAB to format który Google wymaga od 2021. Google Play Console sam generuje
z AAB konkretne APK-i per urządzenie (mniejszy download).

### Opcjonalnie: build APK (do testowania poza Play)

```bash
flutter build apk --release
```

Wynik: `build/app/outputs/flutter-apk/app-release.apk` — możesz przesłać
komuś na telefon i zainstalować przez „Nieznane źródła".

---

## 4. Upload do Play Console

1. Play Console → **Twoja aplikacja** → **Testing → Internal testing**
2. **Create new release**
3. **Upload app bundle** → przeciągnij `app-release.aab`
4. **Release name** — automatycznie `0.5.0 (1)` z `pubspec.yaml` (versionName+versionCode)
5. **Release notes** — opisz co nowego (pl-PL):
   ```
   Pierwszy beta release JerzyUczy. Ortografia dla klas 3-4 z 384 słowami
   w 5 kategoriach: ó/u, rz/ż, ch/h, ą/ę, ś/ć/ń/ź. 5 typów ćwiczeń,
   statystyki dla rodzica, inteligentny algorytm powtórek.
   ```
6. **Save → Review release → Start rollout**

Po paru minutach link do testerów gotowy. Wyślij znajomym:
```
https://play.google.com/apps/internaltest?hl=pl&id=pl.soswa.jerzyuczy
```

---

## 5. Podnoszenie wersji przy kolejnych buildach

Każdy nowy release musi mieć **wyższy `versionCode`** niż poprzedni. Edytuj
`pubspec.yaml`:

```yaml
version: 0.6.0+2    # versionName: 0.6.0, versionCode: 2
```

Format: `X.Y.Z+N`. `N` to `versionCode` (integer rosnący), reszta to
`versionName` (dowolna dla wyświetlania).

---

## Checklist przed pierwszym releasem

- [ ] Keystore wygenerowany i backup w 3 miejscach
- [ ] Hasła w password managerze
- [ ] `key.properties` utworzone, w gitignore
- [ ] `build.gradle.kts` zmodyfikowane (signingConfigs)
- [ ] `flutter build appbundle --release` → zbudowane bez błędów
- [ ] AAB ma rozsądny rozmiar (~15-25 MB po optymalizacji WebP)
- [ ] Play Console — wypełniony Tax profile
- [ ] Play Console — wypełniony Data safety form
- [ ] Play Console — IARC questionnaire (klasyfikacja wiekowa)
- [ ] Play Console — Designed for Families program
- [ ] Privacy policy URL (GitHub Pages) podany w Play Console

---

## Debugging

**Problem:** `flutter build appbundle` wyrzuca błąd o podpisie.
**Rozwiązanie:** Sprawdź `android/key.properties` — czy ścieżka do `.jks`
jest poprawna (forward slashes na Windows). Czy hasła nie mają ukrytych
białych znaków.

**Problem:** Build wychodzi ogromny (>50 MB).
**Rozwiązanie:** Po optymalizacji WebP powinien być ~15-25 MB. Jeśli więcej
— sprawdź czy niepotrzebne assety są w `pubspec.yaml` (np. `assets/content/`
powinno być zawarte, reszta kontrolowana).

**Problem:** Play Console odrzuca AAB z błędem „Use of unsupported API".
**Rozwiązanie:** Flutter używa `target_sdk` z `flutter.targetSdkVersion` —
sprawdź `flutter --version` i update Flutter jeśli stary (target musi być
34+ w 2026).
