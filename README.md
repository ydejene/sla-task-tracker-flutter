# SLAtrix — SLA Task Tracker (Flutter)

SLA-aware task tracking for small software teams. Team members pick their
profile, create and assign tasks, and see each task's SLA health
(**On Track · At Risk · Overdue · Completed**) calculated automatically.

## Screens

| # | Screen | File |
|---|--------|------|
| 1 | User Selection | `lib/screens/auth/user_selection_screen.dart` |
| 2 | Dashboard (Overview) | `lib/screens/dashboard/dashboard_screen.dart` |
| 3 | Task List (search, filter chips, sort) | `lib/screens/tasks/task_list_view.dart` |
| 4 | Task Details (status actions, SLA timeline, delete) | `lib/screens/tasks/task_detail_view.dart` |
| 5 | Create / Edit Task (validated form) | `lib/screens/tasks/create_task_view.dart` |
| 6 | Team | `lib/screens/team/team_screen.dart` |
| 7 | Profile / Team Member Profile | `lib/screens/team/profile_screen.dart` |

## Architecture

```
lib/
├── main.dart              App entry, theme, AppScope
├── app_scope.dart         InheritedWidget giving screens access to controllers
├── models/                Task (+ Priority, TaskStatus, SlaStatus), TeamMember
├── controllers/           TaskController, TeamController
├── services/              StorageService (sqflite), SlaService (business rules)
├── screens/               UI, one folder per feature + home_shell / navigation
├── widgets/               TaskCard, StatusBadge, SlaBadge, PriorityBadge,
│                          MemberAvatar, AppButton, AppTextField, ...
├── theme/app_theme.dart   Design tokens from Figma (colours, type, radii)
└── utils/                 Constants, date formatters
```

**State management:** `setState()` + Controller pattern (no third-party package).
`User action → Controller → SQLite → in-memory refresh → setState() → rebuild`.

**Persistence:** SQLite via `sqflite`. Tables `team_members` and `tasks`;
`tasks.assigned_to` references `team_members.id` with `ON DELETE SET NULL`
and foreign keys enabled (`PRAGMA foreign_keys = ON`). Demo data is seeded on
first launch with timestamps relative to "now", so every SLA state is visible.
Profile → *Reset demo data* restores it.

## SLA rules (`lib/services/sla_service.dart`)

```
IF status == Completed          → Completed
ELSE IF now > deadline          → Overdue
ELSE IF now >= atRiskAt         → At Risk
ELSE                            → On Track

atRiskAt = createdAt + (deadline − createdAt) × 0.75
```

* `atRiskAt` is stored when a task is created and recalculated if the deadline is edited.
* **Pause:** entering *Paused* records `pausedAt`; while paused the SLA is evaluated
  at `pausedAt` (clock frozen). Leaving *Paused* shifts `deadline` and `atRiskAt`
  by the paused duration and clears `pausedAt`.
* Priority (Low/Medium/High) is independent of SLA status.

Statuses follow the Figma design: Todo, In Progress, Paused, Completed
(*In Review* was left out as optional in the spec).

## Running

Requirements: Flutter stable 3.47+ (Dart ^3.13, as in `pubspec.yaml`), Android Studio with an emulator or device.

```bash
flutter pub get
flutter run
```

Tests (SLA rules, model mapping, shared widgets):

```bash
flutter test
```

## Contributing

Follow the team workflow: branch from `dev` (`feature/...`, `fix/...`), use
`feat:` / `fix:` / `chore:` commit messages, and open a PR into `dev` with at
least one peer approval.
