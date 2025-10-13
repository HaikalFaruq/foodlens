# Food Recognizer App 🍔🍕🥗

A Flutter project that identifies food items in images using TensorFlow Lite, retrieves nutrition information using Google Gemini AI, and provides a user-friendly interface for image selection and analysis. This app helps users quickly understand the nutritional content of their meals.

## 🚀 Key Features

- **Image Selection**: Allows users to select images from their gallery or capture new ones using the camera. 📸
- **Image Cropping**: Provides image cropping functionality to focus on the food item of interest. ✂️
- **Food Recognition**: Utilizes a TensorFlow Lite model to identify food items in images. 🤖
- **Real-time Analysis**: Offers real-time food recognition using the camera. 📹
- **Nutrition Information**: Retrieves nutrition information for identified food items using Google Gemini AI. ℹ️
- **Local Data Support**: Provides nutrition information from a local JSON file as a fallback. 💾
- **Food Description**: Generates descriptions of food items using Google Gemini AI. 📝
- **User-Friendly Interface**: Offers a clean and intuitive user interface for easy navigation and interaction. 📱

## 🛠️ Tech Stack

- **Frontend**:
  - Flutter
  - Dart
- **Machine Learning**:
  - TensorFlow Lite (`tflite_flutter`)
  - Firebase ML Model Downloader (`firebase_ml_model_downloader`)
  - Google Generative AI (`google_generative_ai`)
- **Image Processing**:
  - `image` package
  - `image_picker` package
  - `image_cropper` package
  - `camera` package
- **Backend**:
  - Firebase (for model hosting)
  - Google Gemini AI (for nutrition information and descriptions)
- **State Management**:
  - Provider
- **Asynchronous Operations**:
  - `dart:async`
  - `dart:isolate`
- **HTTP Requests**:
  - `http` package
- **Environment Variables**:
  - `envied`
- **UI**:
  - Material Design
  - `cupertino_icons`
- **Other**:
  - `path_provider`
  - `collection`
  - `build_runner`
  - `flutter_lints`
  - `flutter_test`

## 📦 Getting Started

### Prerequisites

- Flutter SDK (version >=3.0.0 <4.0.0)
- Firebase project
- Google Gemini API key
- Android Studio or VS Code with Flutter extension

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/mhmdnurulkarim/food_recognizer_app
    cd food_recognizer_app
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Set up Firebase:**

    - Create a Firebase project in the Firebase Console.
    - Enable the ML Model Downloader.
    - Add the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files to their respective platform directories.
    - Configure Firebase in your Flutter project using the `firebase_core` package.

4.  **Configure Environment Variables:**

    - Create a `.env` file in the root of the project.
    - Add your Gemini API key to the `.env` file:

    ```
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY
    ```

5.  **Generate Environment Variables:**

    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

### Running Locally

1.  **Connect a device or emulator:**

    - Ensure that you have a connected Android or iOS device, or an emulator running.

2.  **Run the application:**

    ```bash
    flutter run
    ```

## 📂 Project Structure

```
food_recognizer_app/
├── android/                # Android-specific files
├── ios/                    # iOS-specific files
├── lib/
│   ├── controller/         # Contains controller classes for state management
│   │   ├── photo_picker_controller.dart
│   │   └── result_controller.dart
│   ├── model/              # Contains data model classes
│   │   ├── analysis_result.dart
│   │   ├── food_info.dart
│   │   └── nutrition_info.dart
│   ├── service/            # Contains service classes for business logic
│   │   ├── gemini_service.dart
│   │   ├── image_service.dart
│   │   ├── lite_rt_service.dart
│   │   ├── ml_service.dart
│   │   └── nutrition_service.dart
│   ├── ui/                 # Contains UI widgets and screens
│   │   ├── camera_screen.dart
│   │   ├── photo_picker_screen.dart
│   │   ├── result_screen.dart
│   │   ├── route/
│   │   │   ├── navigation_args.dart
│   │   │   └── navigation_route.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── env/                  # Contains environment configuration
│   │   └── env.dart
│   ├── firebase_options.dart # Firebase configuration options
│   └── main.dart             # Entry point of the application
├── assets/                 # Contains assets like images, data files, and TFLite model
│   ├── data/
│   │   └── nutrition_data.json
│   ├── images/
│   └── labelmap.txt
├── .env                    # Environment variables (API keys, etc.)
├── pubspec.yaml            # Flutter project configuration file
├── README.md               # Project documentation
```

## 📸 Screenshots

(Screenshots will be added here)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Make your changes and commit them with descriptive messages.
4.  Push your changes to your fork.
5.  Submit a pull request.

## 📬 Contact

If you have any questions or suggestions, feel free to contact me at [mhmdnurulkarim@gmail.com](mailto:mhmdnurulkarim@gmail.com).

## 💖 Thanks Message

Thank you for checking out the Restaurant App! We hope you find it useful and enjoyable. Your feedback and contributions are greatly appreciated.
