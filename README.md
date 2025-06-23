
## Build Flutter App (Built with Zapp.run + GitHub Actions)

This project demonstrates how to develop a Flutter app using [Zapp.run](https://zapp.run), then build and export the Android APK using GitHub Actions.

---

### 🚀 Workflow Overview

#### 1. Develop Your App on [https://zapp.run](https://zapp.run)

#### 2. Export ZIP Code from Zapp

#### 3. Clone This GitHub Repository

#### 4. Extract Zapp Code into This Repo folder

#### 5. Create a Valid Flutter Project Structure

```bash
flutter create -t app <app_name>
```

#### 6. Migrate Zapp Code into New Flutter Project

Now, copy over your app code:

##### 1. Copy `lib` folder to new project
##### 2. Edit `pubspec.yaml` and make sure dependencies are compatible with your current Flutter SDK version.  

> You can check your version by running: `flutter --version`


#### ⚙️ 7. Setup GitHub Actions to Export APK

Already have a workflow file in:

```
.github/workflows/flutter-android.yml
```

Do some modifications:

```yaml
name: Build Flutter APK

on:
  push:
    paths:
      - 'notes/**'            <---------------- change path
      - '.github/workflows/**'
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: notes  <------------- change working dir

    steps:
      - name: Checkout repo
        uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.4'  <---------- check flutter version

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: notes-app-release.apk
          path: notes/build/app/outputs/notes/app-release.apk  <----------------- change folder name
```

#### 8. Push Your Code to GitHub

#### Result

- Click the **Actions** tab
- Select the latest workflow run
- Download your generated `APK` from the **Artifacts** section

