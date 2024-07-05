# Visual Aid for Visually Impaired (G36-PS24)

This project aims to provide visual assistance for visually impaired individuals using Flutter and Firebase.

## Getting Started

Follow these steps to set up and run the project on your local machine.

### Prerequisites

- Flutter SDK
- Git
- Firebase account
- Android Studio or VS Code (with Flutter and Dart plugins)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/iAm-Abhiram7/VisualAidForVisuallyImpaired-G36-PS24.git
   ```

2. Navigate to the project directory:
   ```
   cd VisualAidForVisuallyImpaired-G36-PS24
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

### Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/).

2. Add a new app to your Firebase project:
   - For web, follow the instructions on the Firebase Console.
   - For Android, follow the [Flutter setup guide for Firebase](https://firebase.google.com/docs/flutter/setup?platform=android).

3. Set up SHA and SHA-1 fingerprints for your Android app:
   - Follow the guide at [Google Developers](https://developers.google.com/android/guides/client-auth).

4. Enable Cloud Firestore API:
   - Visit [Google Cloud Console](https://console.cloud.google.com/apis/library/firestore.googleapis.com?project=your-project-name) and enable the API for your project.

5. Create a Firestore database:
   - In the Firebase Console, select your project.
   - In the left-hand navigation pane, click on "Firestore Database".
   - Click on "Create database".
   - Set up the database rules as follows:

     ```
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if request.time < timestamp.date(2024, 7, 18);
         }
       }
     }
     ```

   Note: These rules are set to expire on July 18, 2024. Make sure to update them before that date.

### Running the App

1. Start an Android emulator or connect a physical device.

2. Run the app:
   ```
   flutter run
   ```

