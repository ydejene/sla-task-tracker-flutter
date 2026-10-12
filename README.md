# SLA Task Tracker (Flutter)

A mobile task management and Service Level Agreement (SLA) monitoring application built with Flutter and SQLite. The application helps software teams prioritize time-sensitive deliverables, track SLA health in real time, and manage task lifecycles with dynamic deadline adjustments.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Application Structure](#application-structure)
- [Getting Started](#getting-started)
- [How It Works](#how-it-works)
- [Testing](#testing)
- [Project Context](#project-context)

---

## Overview

In engineering and operations workflows, task delivery is governed by Service Level Agreements (SLAs). Traditional task boards often display static workflow states ("Todo", "In Progress") without immediate insight into approaching breach windows.

**SLA Task Tracker** addresses this problem by calculating real-time SLA health directly from deadlines and timestamps:
- It warns teams before an SLA is breached by establishing an automated **At Risk** threshold (75% elapsed duration).
- It provides team-wide health analytics on an **Overview Dashboard**.
- It supports pausing and resuming tasks, automatically extending deadlines to account for external blockers.
- It operates completely offline using a local SQLite relational database.

---

## Features

### 1. SLA Health & Dashboard Overview
- **Team SLA Health Ring**: Dynamic percentage indicator displaying the proportion of on-track tasks relative to total active work.
- **2x2 Metrics Grid**: Quick-glance counters for **Active**, **On Track**, **At Risk**, and **Overdue** tasks.
- **Urgent Tasks Section**: Priority queue of tasks requiring attention, with filter presets (**Urgent First**, **At Risk Only**, **Overdue Only**).
- **Recent Activity Feed**: Chronological log of recent task lifecycle events (started, paused, resumed, completed).

### 2. Task Management & Search
- **Live Search**: Instant keyword search matching task titles and descriptions.
- **Filter Chips**: Quick status filtering across **All**, **On Track**, **At Risk**, **Overdue**, and **Completed** tasks with live counts.
- **Task Creation & Editing**: Create and edit tasks with title, description, assignee selection, priority level (**Low**, **Medium**, **High**), and date/time deadline picker.
- **Empty States**: Clear empty-state messaging when searches or filters return no matching tasks.

### 3. Task Lifecycle Management
- **Status Transitions**:
  - `Start Task`: Moves a task from `Todo` to `In Progress`.
  - `Pause Task`: Places an in-progress task into `Paused` and records the pause timestamp.
  - `Resume Task`: Moves a paused task back to `In Progress` and extends both the deadline and the at-risk threshold by the pause duration.
  - `Complete Task`: Marks the task as `Completed`.
  - `Delete Task`: Removes the task with a confirmation dialog.
- **Dynamic Countdown**: Task Details screen displays remaining time or overdue duration alongside status badges.

### 4. Team Directory & Member Profiles
- **Team Directory**: Overview of all team members with roles, active task assignments, and a "You" badge for the current user.
- **Profile Workload Analytics**: Detailed breakdown of assigned tasks, individual SLA statistics (Active, Completed, Overdue, On Track), and priority workload bars.
- **User Switching**: Easily switch between team members to simulate collaborative workflows.

---

## Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Framework** | [Flutter](https://flutter.dev/) | Dart SDK `^3.13.2` |
| **Local Database** | [sqflite](https://pub.dev/packages/sqflite) (`^2.4.4+1`) | SQLite relational database for offline persistence |
| **Path Utilities** | [path](https://pub.dev/packages/path) (`^1.9.1`) | Cross-platform database file path handling |
| **UUID Generation** | [uuid](https://pub.dev/packages/uuid) (`^4.6.0`) | RFC4122 v4 UUIDs for task and member IDs |
| **State Management** | Flutter `StatefulWidget` / `setState` | Clean reactive local state with `GlobalKey` tab reload triggers |
| **Design System** | Custom Design Tokens (`AppTheme`) | Prototype-faithful typography, pixel-accurate spacing, and color palette |
| **Testing** | `flutter_test` / `flutter_lints` | Unit testing, widget testing, and static analysis |

---

## Application Structure

The codebase follows a clean, layered architecture:

```
sla_task_tracker_flutter/
├── lib/
│   ├── main.dart                      # App entry point, theme configuration, initial route
│   ├── models/
│   │   ├── enums.dart                 # TaskStatus, TaskPriority, SlaStatus enums
│   │   ├── exceptions.dart            # Domain exceptions (ValidationException, DatabaseException)
│   │   ├── task.dart                  # Task domain model with SQLite serialization
│   │   └── team_member.dart           # TeamMember domain model with avatar color styling
│   ├── services/
│   │   ├── database_service.dart      # SQLite database initialization, schema creation, seed data, CRUD
│   │   └── task_service.dart          # SLA calculations, lifecycle transitions, pause/resume logic
│   ├── theme/
│   │   └── app_theme.dart             # Central design tokens, color palette, card styling, visual helpers
│   ├── widgets/
│   │   ├── app_header.dart            # Unified screen header with navigation back button and avatar
│   │   ├── avatar_widget.dart         # Reusable circular avatar with tone styles and initials
│   │   ├── task_card.dart             # Reusable card with SLA indicator, priority badge, and deadline
│   │   └── team_member_card.dart      # Reusable member row card with active task counter and "You" badge
│   └── screens/
│       ├── user_selection_screen.dart # Initial screen to choose the active logged-in member
│       ├── main_shell.dart            # 4-tab bottom navigation shell (Overview, Tasks, Team, Profile)
│       ├── dashboard_screen.dart      # Overview dashboard with health ring, 2x2 grid, activity feed
│       ├── tasks_screen.dart          # Searchable, filterable task list with creation FAB
│       ├── task_details_screen.dart   # Task metadata, remaining duration banner, lifecycle action buttons
│       ├── task_form_screen.dart      # Modal form for creating and editing tasks with validation
│       ├── team_screen.dart           # Team member list with profile drill-down
│       └── profile_screen.dart        # Member workload analytics, statistics card, switch user button
└── test/
    ├── task_service_test.dart         # Unit tests for SLA calculations, pause/resume rules, and validations
    └── screens_and_widgets_test.dart  # Widget tests for TaskCard and TeamMemberCard components
```

---

## Getting Started

### Prerequisites

Ensure you have the following installed on your development machine:
- **Flutter SDK**: `>= 3.13.2` ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Bundled with Flutter
- **Android Studio / Android SDK**: With Android SDK Command-line Tools and Platform-tools installed
- **Target Device**: An active Android emulator (API level 24+) or a physical Android device with USB debugging enabled

Verify your setup with:
```bash
flutter doctor
```

### Installation & Setup

1. **Navigate to the Flutter project directory**:
   ```bash
   cd sla-task-tracker-flutter
   ```

2. **Fetch project dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify connected devices**:
   ```bash
   flutter devices
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

   To run on a specific device or emulator:
   ```bash
   flutter run -d <device-id>
   ```

### SQLite Database Note
The application automatically creates and seeds the local SQLite database (`sla_task_tracker.db`) on its first launch with four default team members:
- **Maya Kim** (Backend Engineer)
- **Jordan Lee** (Product Engineer)
- **Priya Shah** (QA Engineer)
- **Noah Wilson** (Frontend Engineer)

No external API keys or remote backend services are required.

---

## How It Works

### SLA Classification Rules

SLA health is determined dynamically by comparing the effective current time against the task's creation timestamp and deadline:

1. **Total Duration**: `totalDuration = deadline - createdAt`
2. **At Risk Threshold (`atRiskAt`)**:
   $$\text{atRiskAt} = \text{createdAt} + (\text{totalDuration} \times 0.75)$$
   The task enters the **At Risk** state once 75% of the total allotted window has elapsed.
3. **Status Rules**:
   - **Completed**: The task status is `TaskStatus.completed`.
   - **Overdue**: The effective time is strictly after `deadline`.
   - **At Risk**: The effective time is at or after `atRiskAt` and before or equal to `deadline`.
   - **On Track**: The effective time is before `atRiskAt`.

### Pausing & Resuming Mechanics

When external factors prevent work on a task:
- **Pausing**: Transitioning to `TaskStatus.paused` records the exact timestamp in `paused_at`. While paused, SLA evaluations use `paused_at` rather than the progressing wall clock, freezing SLA deterioration.
- **Resuming**: When resumed, the system calculates the duration the task spent on hold ($\Delta t = \text{resumedAt} - \text{pausedAt}$). It then adds $\Delta t$ to both `deadline` and `atRiskAt`, moving them forward in time. This ensures team members are not penalized for blocked duration.

---

## Testing

The project includes unit and widget tests covering SLA business logic, validation rules, task lifecycle transitions, and UI components.

### Run All Tests
```bash
flutter test
```

### Run Static Analysis
Ensure code cleanliness and adherence to recommended lints:
```bash
flutter analyze
```

---

## Project Context

This application was developed as a university group project for **Mobile Application Development (Trimester 06 / Week 5)** at the **African Leadership University (ALU)** Bachelor of Software Engineering (BSE) program.

The project demonstrates:
- Mobile software engineering and layered application architecture in Flutter.
- Offline-first relational data persistence using SQLite (`sqflite`).
- Time-critical business logic modeling and test-driven SLA calculation rules.
- High-fidelity UI implementation aligned with modern design systems.
