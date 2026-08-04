# 📱 Student Counseling Management System (SCMS)

A cross-platform mobile application built with **Flutter** and a **PHP + MySQL** backend that digitizes and streamlines the university counseling appointment workflow.

---

## 📋 Table of Contents

- [About](#about)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Getting Started](#getting-started)
- [Team](#team)

---

## About

SCMS replaces informal, manual university counseling processes with a structured mobile application. Students can find counselors, book time slots, and track their request status. Counselors can manage their weekly schedule, review and approve or reject requests, and monitor analytics through a statistics dashboard.

---

## Features

### 👨‍🎓 Student
- Register and login with role-based access
- Browse counselors filtered by department
- Book appointment slots by selecting date and available time
- Track counseling request status (Pending / Approved / Rejected)
- View upcoming and completed appointments with full details
- Receive rejection reason when a request is declined
- Edit profile information

### 👨‍💼 Counselor
- Define weekly schedule with day, time slot, and room number
- Review pending student requests with full student details
- Approve or reject requests with a mandatory reason
- View weekly schedule showing only approved appointments
- Statistics dashboard with charts and session analytics
- Edit profile and personal information

### 🔒 System
- Slot-based conflict prevention — zero double bookings
- Database-level constraints enforce one booking per slot per date
- Role-based navigation (Student / Counselor / Admin)
- Session persistence using SharedPreferences
- Real-time data via RESTful PHP API

---

## Screenshots

<table>
  <tr>
    <td align="center"><b>Login</b></td>
    <td align="center"><b>Register</b></td>
    <td align="center"><b>Student Home</b></td>
    <td align="center"><b>Student Profile</b></td>
  </tr>
  <tr>
    <td><img src="scms-app/images/login.jpg" width="180"/></td>
    <td><img src="scms-app/images/register.jpg" width="180"/></td>
    <td><img src="scms-app/images/student_home.jpg" width="180"/></td>
    <td><img src="scms-app/images/student_profile.jpg" width="180"/></td>
  </tr>
  <tr>
    <td align="center"><b>Find Counselor</b></td>
    <td align="center"><b>Book Appointment</b></td>
    <td align="center"><b>My Requests</b></td>
    <td align="center"><b>Appointments (Upcoming)</b></td>
  </tr>
  <tr>
    <td><img src="scms-app/images/avilable_couselor.jpg" width="180"/></td>
    <td><img src="scms-app/images/book_appointment.jpg" width="180"/></td>
    <td><img src="scms-app/images/student_myreqest_screen.jpg" width="180"/></td>
    <td><img src="scms-app/images/student_appointment(upcoming).jpg" width="180"/></td>
  </tr>
  <tr>
    <td align="center"><b>Appointments (Completed)</b></td>
    <td align="center"><b>Edit Profile</b></td>
    <td align="center"><b>Counselor Home</b></td>
    <td align="center"><b>Pending Requests</b></td>
  </tr>
  <tr>
    <td><img src="scms-app/images/student_appointment(complete).jpg" width="180"/></td>
    <td><img src="scms-app/images/edit_student_profile.jpg" width="180"/></td>
    <td><img src="scms-app/images/Counselor_home_screen.jpg" width="180"/></td>
    <td><img src="scms-app/images/Couselor_pending_request_screen.jpg" width="180"/></td>
  </tr>
  <tr>
    <td align="center"><b>My Schedule</b></td>
    <td align="center"><b>Statistics</b></td>
    <td align="center"><b>Counselor Profile</b></td>
    <td align="center"><b>Counselor Info</b></td>
  </tr>
  <tr>
    <td><img src="scms-app/images/my_schedule.jpg" width="180"/></td>
    <td><img src="scms-app/images/counselor_Statistical_info.jpg" width="180"/></td>
    <td><img src="scms-app/images/counselor_profile_screen.jpg" width="180"/></td>
    <td><img src="scms-app/images/counselor_profile_information.jpg" width="180"/></td>
  </tr>
</table>

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| Backend API | PHP 8 |
| Database | MySQL 8 |
| Local Server | XAMPP |
| API Tunneling | ngrok |
| HTTP Client | Dart `http` package |
| Charts | `fl_chart` |
| Session Storage | `shared_preferences` |
| Version Control | Git & GitHub |

---

## Project Structure

```
SCMS/
├── scms-app/                        # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── api_service.dart         # All HTTP API calls
│   │   ├── constants.dart           # Base URL and app constants
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── student/
│   │   │   │   ├── student_home.dart
│   │   │   │   ├── my_requests_screen.dart
│   │   │   │   ├── my_appointments_screen.dart
│   │   │   │   └── new_request_flow/
│   │   │   │       ├── counselor_search_screen.dart
│   │   │   │       └── book_appointment_screen.dart
│   │   │   └── counselor/
│   │   │       ├── counselor_home.dart
│   │   │       ├── pending_requests_screen.dart
│   │   │       ├── weekly_schedule_screen.dart
│   │   │       ├── schedule_manager_screen.dart
│   │   │       └── statistics_screen.dart
│   └── pubspec.yaml
│
└── scms_api/                        # PHP REST API
    ├── config.php
    ├── db.php
    ├── login.php
    ├── register.php
    ├── book_appointment.php
    ├── approve_request.php
    ├── reject_request.php
    ├── reject_appointment.php
    ├── get_available_slots.php
    ├── get_counselors.php
    ├── get_pending_requests.php
    ├── get_weekly_schedule.php
    ├── get_statistics.php
    ├── get_my_requests.php
    ├── get_my_appointments.php
    ├── add_schedule_slot.php
    ├── delete_schedule_slot.php
    ├── get_schedule.php
    └── update_profile.php
```

---

## Database Schema

| Table | Description |
|---|---|
| `users` | All users — students, counselors, admins |
| `counselor_schedule_slots` | Counselor weekly time slots with room info |
| `appointments` | Student bookings linked to slots and dates |
| `counseling_requests` | Approval workflow — pending/approved/rejected |
| `counseling_categories` | Academic, Career, Personal, Class Reschedule |
| `notifications` | In-app alerts for status changes |
| `rooms` | Room assignments for approved sessions |

---

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `login.php` | POST | Authenticate user and return role |
| `register.php` | POST | Register new student or counselor |
| `get_counselors.php` | GET | List counselors by department |
| `get_available_slots.php` | GET | Get available slots for a date |
| `book_appointment.php` | POST | Book a counseling slot |
| `get_my_requests.php` | GET | Fetch student's requests |
| `get_pending_requests.php` | GET | Fetch counselor's pending requests |
| `approve_request.php` | POST | Approve a counseling request |
| `reject_request.php` | POST | Reject a pending request with reason |
| `reject_appointment.php` | POST | Reject an already approved appointment |
| `get_weekly_schedule.php` | GET | Get counselor's weekly approved appointments |
| `get_statistics.php` | GET | Fetch counselor analytics data |
| `add_schedule_slot.php` | POST | Add a new weekly slot |
| `delete_schedule_slot.php` | POST | Delete a schedule slot |
| `update_profile.php` | POST | Update user profile information |

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- PHP 7.4+ and MySQL 8 (XAMPP recommended)
- Android device or emulator

### 1. Clone the repository
```bash
git clone https://github.com/Hassanamil2019/student-counseling-management-system-scms-app.git
cd student-counseling-management-system-scms-app
```

### 2. Set up the database
- Open **phpMyAdmin** at `http://localhost/phpmyadmin`
- Create a new database named `scms`
- Import the `scms.sql` file

### 3. Configure the API
- Copy the `scms_api` folder to `C:\xampp\htdocs\`
- Open `scms_api/db.php` and update your database credentials:
```php
$host = "localhost";
$user = "root";
$pass = "";
$db   = "scms";
```

### 4. Set the base URL in Flutter
- Open `scms-app/lib/constants.dart`
- Update the base URL to your server address (use ngrok if testing on a physical device):
```dart
static const String baseUrl = 'http://YOUR_IP_OR_NGROK_URL/scms_api';
```

### 5. Run the Flutter app
```bash
cd scms-app
flutter pub get
flutter run
```

---

## Developer


**Jaimul Haque**
**Ezabul Alam**

**Supervised by:** Md. Maruf Billah — Lecturer, Department of CSE, BUBT

**Institution:** Bangladesh University of Business and Technology (BUBT)

**Course:** CSE 300 — Software Development Project III

---

> © 2026 SCMS — BUBT CSE Intake 52
---


