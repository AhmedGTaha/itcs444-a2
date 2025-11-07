Here’s a clean **README.md** you can include with your Flutter assignment 👇

---

# 🎓 ITCS444 – Campus Events Manager (Assignment #2)

A Flutter app that lets users **add, edit, delete, and manage campus events** with filters, attendance tracking, local storage, and both **URL and device-image** support.

---

## 🧩 Features

* 📅 Add / Edit / Delete events
* 🎚️ Change event status (Not Started | Postponed | Completed)
* ❤️ Mark favorites
* 👥 Adjust attendance count
* 🔍 Filter by status or favorites
* 💾 Persistent local storage using `shared_preferences`
* 🖼️ Add image from:

  * a **web URL** (HTTPS link)
  * or **local device file** (via `file_picker`)
* ✅ Works on **Windows**, **Android**, **iOS**, **macOS**, **Linux**

---

## ⚙️ Requirements

* **Flutter 3.22+**
* **Dart 3+**
* OS with symlink support (enable Developer Mode on Windows)

---

## 📦 Dependencies

Add these in your `pubspec.yaml` under `dependencies:` 👇

```yaml
shared_preferences: ^2.3.2
http: ^1.2.2
file_picker: ^8.0.3
```

Then run:

```bash
flutter pub get
```

---

## 🏗️ Setup

1. **Create a new project**

   ```bash
   flutter create campus_events
   cd campus_events
   ```

2. **Replace** `lib/main.dart` with the provided file from this assignment.

3. **Android permission (if targeting Android):**
   Edit `android/app/src/main/AndroidManifest.xml`
   Add this line **above** `<application>`:

   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

4. **Windows build note:**
   If you see *“Building with plugins requires symlink support”*,
   enable Developer Mode:
   Press **Win + R**, type

   ```
   start ms-settings:developers
   ```

   → Enable Developer Mode.

---

## ▶️ Running the App

### 🖥️ On Windows / macOS / Linux

```bash
flutter run -d windows
# or -d macos / -d linux
```

### 📱 On Android / iOS

Connect a device or emulator and run:

```bash
flutter run
```

---

## 💡 Usage

1. Tap **“Add Event”** to create a new entry.
2. Enter event details — title, description, date & time, etc.
3. Add an image:

   * Paste a **URL** (must end with .jpg/.png etc.), or
   * Tap **Pick from device** to select a local image.
4. Press **Add Event** to save.
5. Long-press an event card to edit.
6. Use the top-right filter icon to view by status or favorites.

---

## 🧰 Troubleshooting

| Issue                               | Solution                                                                                      |
| ----------------------------------- | --------------------------------------------------------------------------------------------- |
| **“Image failed to load”**          | Use a valid HTTPS image URL or a local file.                                                  |
| **Build fails on Windows**          | Enable Developer Mode (symlinks).                                                             |
| **No internet images on Android**   | Add `<uses-permission android:name="android.permission.INTERNET"/>` to `AndroidManifest.xml`. |
| **HTTP (not HTTPS) images blocked** | Use HTTPS or set `android:usesCleartextTraffic=\"true\"` inside `<application>`.              |

---

## 👨‍💻 Author

**Ahmed Taha**
Course: ITCS 444 – Mobile App Development
Assignment #2  |  Campus Events Manager

