# 🧼 Final Touch – Smart Cleaning Services App

**Final Touch** is a Flutter-based mobile app that allows users to easily book home, office, or car cleaning services with smart features like location detection, secure payments, and **AI-powered dirt level pricing** for personalized cost estimation.  
Built using **Flutter with BLoC state management** and Firebase as the backend.

---

## 🚀 Features

- 📍 **Location Verification**  
  Auto-detects the user's location and confirms service availability.

- 👤 **User Authentication**  
  Firebase Email/Password login and registration.

- 🧼 **Service Selection**  
  Browse a range of static cleaning service packages (Home, Office, Car).

- 🧠 **AI-Powered Dirt Level Detection & Pricing**  
  Users can upload a photo of their space (room/car/etc).  
  The AI model analyzes the image and automatically adjusts the cleaning price based on dirt level:  
  - Light  
  - Moderate  
  - Heavy  
  This ensures **fair pricing** based on actual workload.

- 📝 **Booking Flow**  
  Users select date, time, address, and provide optional instructions before booking.

- 💳 **Payment Integration**  
  Secure, real-time payments via **PayFast**, **Yoco**, or **Stripe**.

- ✅ **Booking Confirmation**  
  Booking summary shown after successful payment with reference ID.

- 📅 **Booking History Tab**  
  View upcoming and past bookings in an organized, filterable list.

- 👤 **User Profile**  
  View and update user information, including name and address.  
  Logout securely using Firebase.

---

## 📱 Tech Stack

| Tech | Description |
|------|-------------|
| [Flutter](https://flutter.dev/) | Cross-platform mobile app SDK |
| [BLoC](https://bloclibrary.dev/) | State management architecture |
| [Firebase](https://firebase.google.com/) | Auth, Firestore, Storage |
| [Geolocator](https://pub.dev/packages/geolocator) | Location services |
| [Stripe / Yoco / PayFast] | Payment gateway integration |
| [Firebase ML Kit / TensorFlow Lite] | AI image classification for dirt level |


