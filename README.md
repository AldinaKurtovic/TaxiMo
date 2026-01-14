# TaxiMo

**TaxiMo** is a fullstack taxi booking application designed to help users request rides and manage their transportation needs across devices. It includes a Flutter-based mobile app, a .NET backend API, and a desktop admin application.

**Project Status:** Done

---

## Desktop Application (Admin Panel) Features

- **Users Management:**

  - View all users with name, email, phone, date of birth, status, and profile photo

  - Search and filter by status (active/inactive)

  - Add new users, edit existing ones, delete users

- **Drivers Management:**

  - View all drivers with name, email, phone, license number, rating, total rides, and status

  - Search and filter drivers

  - Add new drivers, edit existing ones, delete drivers

- **Rides Management:**

  - View all rides with user, driver, pickup/dropoff locations, status, fare, and date

  - Search and filter rides by status

  - Assign drivers to rides

  - View ride details on map

- **Reviews Overview:**

  - View all reviews by users with driver data, rating, description, and date

  - Filter and sort reviews

  - Read-only, no edits allowed

- **Statistics:**

  - Overview of total users, drivers, rides, reviews, revenue, average ratings, and ride trends

- **Promo Codes Management:**

  - View all promo codes, create new ones, edit or delete existing codes

- **Payments Overview:**

  - View all payments with user, ride, amount, payment method, and date

  - Filter and sort payments

---

## Mobile Application Features

- **User Features:**

  - **Home Page:**

    - Quick access to book a ride

    - Recommended drivers

    - Quick actions for trip history, payments, reviews

  - **Book a Ride:**

    - Select pickup and destination locations on map

    - Choose ride type

    - View fare estimate

    - Apply promo codes

  - **Trip History:**

    - View all past rides with details

    - Sort by date

  - **Payment History:**

    - View all payment transactions

    - Track payment methods and status

  - **Reviews:**

    - View all reviews given to drivers

    - Rate and review completed rides

  - **Profile:**

    - Edit personal information and app settings

    - View user statistics

- **Driver Features:**

  - **Home:**

    - View active rides and availability status

    - Quick access to ride requests

  - **Ride Requests:**

    - View and accept incoming ride requests

    - See pickup and destination details

  - **Active Rides:**

    - Manage current active rides

    - Navigate to pickup and destination locations

  - **Statistics:**

    - Track total rides, earnings, average rating

    - View ride statistics and trends

  - **Reviews:**

    - View all reviews received from users

    - Track average rating

  - **Profile:**

    - Edit driver information and vehicle details

    - Manage availability

---

## Technology Stack

- **Frontend:** Flutter (mobile and desktop)  

- **Backend:** C# .NET Core  

- **Database:** MS SQL Server  

- **Deployment:** Docker

## RabbitMQ Notifications

This project uses RabbitMQ to send real-time in-app notifications to users and drivers. Whenever a ride is created, notifications are sent via the subscriber service.

---

## Running the Application

### 1. Prepare backend

- Unpack `fit-build-2026_env.zip`  
- Inside the folder, run: 
   ```bash
  docker-compose up --build
   ```

### 2. Mobile App

- Unpack the mobile app build zip file

- Find the APK: `folder-mobilne-app/build/app/outputs/flutter-apk/app-release.apk`

- Drag & drop APK into Android Emulator (AVD) or install on Android device

- Launch the app in emulator/device

- **API address:** `http://10.0.2.2:5244` (for Android Emulator) or `http://localhost:5244` (for physical device)

---

### 3. Desktop App

- In the build zip, find `.exe`: `folder-desktop-app/build/windows/x64/runner/Release/taximo.exe`

- Run the `.exe` file

- **API address:** `http://localhost:5244`

---

### Test Accounts

**Desktop (Admin):**

- Username: `admin` / Password: `test`

**Mobile (User):**

- Username: `user` / Password: `test`

**Mobile (Driver):**

- Username: `driver` / Password: `test`

---

### 💳 Stripe Integration

Payment for orders is enabled through Stripe integration in the mobile application.

**Test Card Credentials:**

- Card Number: `4242 4242 4242 4242`
- Expiry Date: `10/31`
- CVC: `123`
- Country Selection: `11000`
