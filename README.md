# Flutter Events App — CRUD + Filters + SharedPreferences

## 📘 Description

A simple yet complete **Flutter Event Management App** that demonstrates how to:

* Add, Edit, and Delete events with various fields (title, description, status, date/time, location, organizer, attendees, image, etc.)
* Filter events by **status** (e.g., Not Started, Postponed, Completed)
* Track **attendance** dynamically with +/− buttons
* Persist data **locally** using `shared_preferences` (stored as JSON)
* Use multiple Flutter widgets such as `ListView`, `Form`, `DropdownButtonFormField`, `DatePicker`, and `Dismissible`

This app is lightweight, works offline, and is perfect for learning **state management, local storage**, and **form validation** in Flutter.

---

## 🧱 Features

✅ Add / Edit / Delete events
✅ Filter events by Status
✅ Track number of attendees
✅ Local data persistence using SharedPreferences
✅ Clean, responsive UI with Material 3
✅ Works fully offline

---

## 🛠️ Tech Stack

* **Flutter SDK 3.0+**
* **Dart** language
* **SharedPreferences** for local storage
* **Material 3 Widgets**

---

## 📂 Project Structure

```
lib/
├── main.dart          # Main app code
└── ...                # Add other files as needed
```

---

## 🚀 Getting Started

### 1️⃣ Clone the repository

```bash
git clone https://github.com/<your-username>/flutter-events-app.git
cd flutter-events-app
```

### 2️⃣ Install dependencies

```bash
flutter pub get
```

### 3️⃣ Run the app

```bash
flutter run
```

---

## 🧩 How It Works

* When you add or edit events, data is stored in `SharedPreferences` as a JSON list.
* On app launch, events are loaded from storage and displayed in a scrollable list.
* You can swipe an event to delete it, or tap to edit.
* The dropdown filter at the top allows viewing events by their status.

---

## 🖼️ Screenshots (Optional)

*(Add your screenshots here once the app runs)*

---

## 📚 Widgets Used

* **ListView** – Displays all events
* **Form** + **TextFormField** – Input fields for event details
* **DropdownButtonFormField** – For selecting event status
* **DatePicker / TimePicker** – To choose date and time
* **Dismissible** – Swipe to delete
* **FloatingActionButton** – Add new events

---

## 💾 Data Storage

All events are saved locally using `SharedPreferences` under the key `events_v1`. Each event is stored as a JSON object containing all its fields.

---

## 📄 License

This project is released under the **MIT License** — feel free to modify, use, and share.

---

## 👨‍💻 Author

**Ahmed Taha**
Built with ❤️ using Flutter and Dart.

---

## 📝 Example Description for GitHub Repository

> A simple Flutter app for managing personal or community events with full offline support. Features event CRUD operations, filtering by status, attendance tracking, and data persistence using SharedPreferences. Ideal for learning local storage and form handling in Flutter.
