# Fuel Tracker Setup Instructions

## Requirements

Before setting up this project you need Flutter installed on your computer. You also need Android Studio or Xcode depending on the platform you want to run the app on. An internet connection is required since the app connects to Firebase.

## Cloning the project

Clone the repository using the following command.

git clone the repository link here

Then move into the project folder.

cd fuel_tracker

## Installing dependencies

Run the following command inside the project folder to install all required packages.

flutter pub get

## Dependencies used in this project

firebase_core
cloud_firestore
image_picker
path_provider
path
uuid
table_calendar
flutter_slidable

## Firebase configuration

This project uses Firebase Firestore as the database. The Firebase configuration files are already included in the repository so no additional Firebase project setup is required to run the app. The files included are lib/firebase_options.dart, android/app/google-services.json, and ios/Runner/GoogleService-Info.plist. These connect the app directly to the Firestore database used for this project.

If the Firebase connection does not work for some reason, run the following command using the Firebase CLI and Flutterfire CLI to regenerate the configuration.

flutterfire configure

## Running the app

Run the following command from inside the project folder to launch the app on a connected device, emulator, or simulator.

flutter run

If running on iOS through Xcode, open ios/Runner.xcworkspace instead of the .xcodeproj file.

This project was built for study purpose only.