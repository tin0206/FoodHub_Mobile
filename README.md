# FoodHub Mobile

Flutter app for the FoodHub platform.

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Config file

Tạo file `config.json` ở root project (dev):

```json
{
  "API_BASE_URL": "https://api.foodhub.io.vn/api/v1",
  "GOOGLE_WEB_CLIENT_ID": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
}
```

Tạo file `config.prod.json` cho production (gitignored):

```json
{
  "API_BASE_URL": "https://api.foodhub.io.vn/api/v1",
  "GOOGLE_WEB_CLIENT_ID": "YOUR_PROD_WEB_CLIENT_ID.apps.googleusercontent.com"
}
```

### 3. Android — Google Sign-In

Tạo file `android/app/src/main/res/values/strings.xml` (gitignored) từ template:

```bash
cp android/app/src/main/res/values/strings.xml.example android/app/src/main/res/values/strings.xml
```

Điền Web Client ID vào `strings.xml`.

---

## Chạy ứng dụng

### Web (dev)

```bash
flutter run -d chrome --web-port=5000 --dart-define-from-file=config.json
```

### Web (prod)

```bash
flutter build web --dart-define-from-file=config.prod.json
```

### Android / iOS (dev)

```bash
flutter run --dart-define-from-file=config.json
```

### Android / iOS (prod)

```bash
flutter build apk --dart-define-from-file=config.prod.json
flutter build ios --dart-define-from-file=config.prod.json
```

---

## Google Cloud Console

Để Google Sign-In hoạt động trên web, cần thêm vào Web Client ID:

- **Authorized JavaScript origins:** `http://localhost`, `http://localhost:5000`

APIs cần enable:
- People API
