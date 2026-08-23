<div align="center">

<h1>Cipher-X</h1>

<p><strong>A startup-quality, real-time security workforce and operations management platform — multi-factor attendance verification, live site coverage, incident reporting with evidence, and an immutable audit trail. Built in 10 days on a zero-rupee infrastructure budget.</strong></p>

<br/>

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-Free%20Tier-FFCA28?logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Riverpod-State%20Management-4A90D9" />
<img src="https://img.shields.io/badge/GoRouter-Navigation-5C6BC0" />
<img src="https://img.shields.io/badge/Freezed-Immutable%20Models-00BCD4" />
<img src="https://img.shields.io/badge/Firebase%20App%20Check-Attestation-FF6F00" />
<img src="https://img.shields.io/badge/Budget-%E2%82%B90-22c55e" />
<img src="https://img.shields.io/badge/Timeline-10%20Days-6366F1" />
<img src="https://img.shields.io/badge/License-MIT-blue.svg" />

<br/><br/>

</div>

---

## Table of Contents

- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Operational Loop](#operational-loop)
- [System Architecture](#system-architecture)
- [Firestore Data Model](#firestore-data-model)
- [Attendance Verification Engine](#attendance-verification-engine)
- [Authentication and RBAC Flow](#authentication-and-rbac-flow)
- [Incident and Evidence Pipeline](#incident-and-evidence-pipeline)
- [Alert Architecture](#alert-architecture)
- [10-Day Build Roadmap](#10-day-build-roadmap)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Security Model](#security-model)
- [Getting Started](#getting-started)
- [Firebase Emulator Setup](#firebase-emulator-setup)
- [Definition of Done](#definition-of-done)
- [Documentation Directory](#documentation-directory)
- [Team Decrypters](#team-decrypters)
- [Contributing](#contributing)
- [License](#license)

---

## The Problem

Security companies deploy hundreds of guards daily across dispersed locations. Head offices rely on phone calls and WhatsApp messages to confirm attendance, leading to systemic failures:

| Failure Mode | Reality |
|---|---|
| Attendance spoofing | Guards mark check-in from home via phone calls to supervisors |
| Zero real-time visibility | Head office has no live view of which sites are understaffed |
| Delayed incident response | Incident reports reach management hours after occurrence |
| No audit trail | Disputes over attendance, incidents, and shift changes have no verifiable history |
| Informal shift assignment | Shift scheduling happens over WhatsApp with no conflict checking |
| Missing evidence | Incidents reported verbally with no photos, timestamps, or location data |

---

## The Solution

Cipher-X is a closed-loop security operations platform that replaces every informal process with a structured, verifiable, and auditable digital workflow.

Rather than a single feature, the product is an **operational loop** — every action feeds the next stage, and nothing falls through.

---

## Operational Loop

```mermaid
flowchart LR
    ASSIGN([ASSIGN\nAdmin creates shift]) --> SHIFT[SHIFT\nGuard notified]
    SHIFT --> ARRIVE[ARRIVE\nGuard reaches site]
    ARRIVE --> VERIFY[VERIFY\nGPS + QR + Shift window]
    VERIFY --> CHECKIN[CHECK-IN\nAttendance record created]
    CHECKIN --> MONITOR[MONITOR\nAdmin dashboard updates]
    MONITOR --> ALERT[ALERT\nMissed shift or late detected]
    ALERT --> INCIDENT[INCIDENT\nGuard reports with evidence]
    INCIDENT --> RESOLVE[RESOLVE\nAdmin reviews and closes]
    RESOLVE --> AUDIT[AUDIT\nImmutable log entry created]
    AUDIT --> ASSIGN
```

Every stage is a distinct data event in Firestore. The loop runs continuously across all active sites and all deployed guards simultaneously.

---

## System Architecture

The full component topology of Cipher-X — feature-first Flutter application talking exclusively to the Firebase platform with zero paid backend infrastructure.

```mermaid
graph TB
    subgraph Flutter [Flutter App - Android, iOS, Web]
        subgraph UI [UI Layer]
            GUARD_UI[Guard App\nShift, Check-in, Incidents]
            ADMIN_UI[Admin Dashboard\nCoverage, Alerts, Reports]
            SUPERVISOR_UI[Supervisor View\nSite monitoring]
        end

        subgraph State [State Layer - Riverpod]
            ASYNC_NOTIFIER[AsyncNotifierProvider\nper feature]
            STREAM_PROVIDER[StreamProvider\nFirestore real-time listeners]
        end

        subgraph Repo [Repository Layer]
            AUTH_REPO[AuthRepository]
            GUARD_REPO[GuardRepository]
            SITE_REPO[SiteRepository]
            SHIFT_REPO[ShiftRepository]
            ATTEND_REPO[AttendanceRepository]
            INCIDENT_REPO[IncidentRepository]
            ALERT_REPO[AlertRepository]
            AUDIT_REPO[AuditRepository]
        end

        subgraph Engine [Verification Engine]
            GEO_ENGINE[GeofenceEngine\nHaversine distance]
            QR_ENGINE[QREngine\nSite code validation]
            SHIFT_ENGINE[ShiftValidator\nWindow and overlap check]
        end
    end

    subgraph Firebase [Firebase Platform - Zero Cost Tier]
        FA[Firebase Auth\nIdentity and custom role claims]
        FS[(Cloud Firestore\nMulti-tenant NoSQL)]
        FSTORAGE[Firebase Storage\nIncident evidence files]
        FCM[Firebase Cloud Messaging\nPush alerts]
        APPCHECK[Firebase App Check\nClient attestation]
    end

    subgraph Router [Navigation - GoRouter]
        GUARD_ROUTES[Guard routes]
        ADMIN_ROUTES[Admin routes]
        SUPERVISOR_ROUTES[Supervisor routes]
        ROLE_GUARD[Role-based route guard]
    end

    GUARD_UI --> ASYNC_NOTIFIER
    ADMIN_UI --> STREAM_PROVIDER
    ASYNC_NOTIFIER --> REPO
    STREAM_PROVIDER --> REPO
    REPO --> ENGINE
    AUTH_REPO --> FA
    GUARD_REPO --> FS
    SITE_REPO --> FS
    SHIFT_REPO --> FS
    ATTEND_REPO --> FS
    INCIDENT_REPO --> FS
    INCIDENT_REPO --> FSTORAGE
    ALERT_REPO --> FCM
    AUDIT_REPO --> FS
    APPCHECK --> FS
    APPCHECK --> FSTORAGE
    Router --> GUARD_ROUTES
    Router --> ADMIN_ROUTES
    Router --> SUPERVISOR_ROUTES
    ROLE_GUARD --> GUARD_ROUTES
    ROLE_GUARD --> ADMIN_ROUTES
    ROLE_GUARD --> SUPERVISOR_ROUTES
```

---

## Firestore Data Model

Multi-tenant Firestore schema. Every document is scoped to an `organizationId` ensuring complete isolation between tenants at the query and security rules layer.

```mermaid
erDiagram
    Organization {
        string organizationId PK
        string name
        string plan
        timestamp createdAt
    }

    User {
        string uid PK
        string organizationId FK
        string name
        string email
        string phone
        string role
        string status
        timestamp createdAt
        timestamp updatedAt
    }

    Site {
        string siteId PK
        string organizationId FK
        string name
        string address
        float latitude
        float longitude
        int geofenceRadius
        string qrCode
        string status
        timestamp createdAt
    }

    Shift {
        string shiftId PK
        string organizationId FK
        string guardId FK
        string siteId FK
        date date
        timestamp startTime
        timestamp endTime
        string status
        timestamp createdAt
    }

    Attendance {
        string attendanceId PK
        string organizationId FK
        string guardId FK
        string shiftId FK
        string siteId FK
        timestamp checkInTime
        float checkInLatitude
        float checkInLongitude
        float checkInAccuracy
        timestamp checkOutTime
        string verificationMethod
        timestamp createdAt
    }

    Incident {
        string incidentId PK
        string organizationId FK
        string reportedBy FK
        string siteId FK
        string type
        string severity
        string description
        float latitude
        float longitude
        string status
        timestamp createdAt
        timestamp resolvedAt
        string resolvedBy
    }

    Alert {
        string alertId PK
        string organizationId FK
        string type
        string severity
        string guardId FK
        string siteId FK
        string message
        boolean acknowledged
        timestamp createdAt
    }

    AuditLog {
        string logId PK
        string organizationId FK
        string actorId FK
        string action
        string targetCollection
        string targetId
        map before
        map after
        timestamp createdAt
    }

    Organization ||--o{ User : "has"
    Organization ||--o{ Site : "owns"
    Organization ||--o{ Shift : "schedules"
    User ||--o{ Shift : "assigned to"
    Site ||--o{ Shift : "hosts"
    Shift ||--o{ Attendance : "produces"
    Site ||--o{ Incident : "occurs at"
    User ||--o{ Incident : "reports"
    Organization ||--o{ Alert : "receives"
    Organization ||--o{ AuditLog : "tracks"
```

---

## Attendance Verification Engine

The hero feature of Cipher-X. Multi-factor verification runs sequentially — every gate must pass before the attendance record is created.

```mermaid
flowchart TD
    START([Guard taps Check-In]) --> AUTH_CHECK{Authenticated\nwith valid session?}
    AUTH_CHECK -->|No| DENY_AUTH([Redirect to login])
    AUTH_CHECK -->|Yes| SHIFT_CHECK{Active shift\nexists for today?}

    SHIFT_CHECK -->|No| DENY_SHIFT([Error: No active shift])
    SHIFT_CHECK -->|Yes| GUARD_CHECK{Shift assigned\nto this guard?}

    GUARD_CHECK -->|No| DENY_GUARD([Error: Not your shift])
    GUARD_CHECK -->|Yes| WINDOW_CHECK{Current time within\nshift window?}

    WINDOW_CHECK -->|No| DENY_WINDOW([Error: Outside shift window])
    WINDOW_CHECK -->|Yes| DUP_CHECK{Already checked\nin for this shift?}

    DUP_CHECK -->|Yes| DENY_DUP([Error: Already checked in])
    DUP_CHECK -->|No| GPS_CHECK{GPS permission\ngranted?}

    GPS_CHECK -->|No| DENY_GPS([Error: Location permission required])
    GPS_CHECK -->|Yes| ACCURACY_CHECK{GPS accuracy\nbelow 50m threshold?}

    ACCURACY_CHECK -->|No| DENY_ACCURACY([Error: Poor GPS signal - move outdoors])
    ACCURACY_CHECK -->|Yes| GEOFENCE_CHECK{Haversine distance\nwithin site radius?}

    GEOFENCE_CHECK -->|No| DENY_GEO([Error: Not at site location])
    GEOFENCE_CHECK -->|Yes| QR_SCAN[Guard scans site QR code]

    QR_SCAN --> QR_CHECK{QR code matches\nthis site?}
    QR_CHECK -->|No| DENY_QR([Error: Invalid or wrong site QR])
    QR_CHECK -->|Yes| CREATE_ATTENDANCE[(CREATE Attendance record\nwith server timestamp)]

    CREATE_ATTENDANCE --> AUDIT_LOG[(Append to Audit Log)]
    AUDIT_LOG --> NOTIFY[Update Admin Dashboard\nvia Firestore listener]
    NOTIFY --> DONE([Check-in confirmed])
```

---

## Authentication and RBAC Flow

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant GoRouter as GoRouter Guard
    participant FirebaseAuth as Firebase Auth
    participant Firestore as Cloud Firestore
    participant AppCheck as Firebase App Check

    User->>App: Opens application
    App->>AppCheck: Attest app integrity
    AppCheck-->>App: Token issued

    App->>FirebaseAuth: onAuthStateChanged listener
    FirebaseAuth-->>App: Auth state stream

    alt User not authenticated
        App->>GoRouter: Redirect to /login
        User->>App: Enter credentials
        App->>FirebaseAuth: signInWithEmailAndPassword
        FirebaseAuth-->>App: UserCredential + custom claims
    end

    App->>Firestore: Fetch users/uid document
    Firestore-->>App: User profile with role field

    App->>GoRouter: Evaluate role claim

    alt Role is ADMIN
        GoRouter->>App: Mount admin route tree
        Note over App: Access to all features
    else Role is SUPERVISOR
        GoRouter->>App: Mount supervisor route tree
        Note over App: Site and coverage view only
    else Role is GUARD
        GoRouter->>App: Mount guard route tree
        Note over App: Shift, check-in, incidents only
    end

    Note over Firestore: Security Rules enforce same\nisolation at database layer
```

---

## Incident and Evidence Pipeline

```mermaid
flowchart TD
    GUARD([Guard observes incident]) --> OPEN_FORM[Open incident report form]

    OPEN_FORM --> SELECT_TYPE[Select incident type]
    SELECT_TYPE --> SELECT_SEV[Select severity\nLOW, MEDIUM, HIGH, CRITICAL]
    SELECT_SEV --> DESCRIPTION[Enter description]
    DESCRIPTION --> CAPTURE_LOC[Capture GPS location\nautomatically]
    CAPTURE_LOC --> UPLOAD_EVIDENCE{Upload photo evidence?}

    UPLOAD_EVIDENCE -->|Yes| VALIDATE_FILE[Validate file type\nand size limit]
    VALIDATE_FILE --> COMPRESS[Compress image\nbefore upload]
    COMPRESS --> UPLOAD[(Upload to Firebase Storage\nincidents/incidentId/evidence/fileId)]
    UPLOAD --> GET_URL[Get download URL]
    GET_URL --> SUBMIT

    UPLOAD_EVIDENCE -->|No| SUBMIT[Submit incident record\nto Firestore]

    SUBMIT --> CREATE_INCIDENT[(CREATE incident document\nstatus: OPEN)]
    CREATE_INCIDENT --> FCM_ALERT[Send FCM push\nto Admin and Supervisors]
    CREATE_INCIDENT --> AUDIT[(Append to Audit Log)]
    FCM_ALERT --> ADMIN_VIEW[Admin sees incident\nin Command Center]

    ADMIN_VIEW --> REVIEW[Admin reviews evidence\nand description]
    REVIEW --> STATUS_UPDATE[Update status\nINVESTIGATING]
    STATUS_UPDATE --> RESOLVE[Add resolution notes\nUpdate status: RESOLVED]
    RESOLVE --> AUDIT2[(Append resolution\nto Audit Log)]
```

---

## Alert Architecture

The alert system is deliberately decoupled from any paid scheduler or backend function. Alert evaluation happens client-side on admin app launch and on a configurable periodic interval, keeping the architecture replaceable and the infrastructure cost at zero.

```mermaid
flowchart LR
    subgraph Triggers [Alert Trigger Sources]
        T1[Shift start time passed\nno check-in recorded]
        T2[Check-in time exceeds\nshift start plus tolerance]
        T3[Active shifts count\nbelow required minimum for site]
        T4[Incident severity\nis CRITICAL]
    end

    subgraph Evaluation [Alert Evaluation Engine - Client-Side]
        QUERY[(Query Firestore\nfor shifts and attendance)]
        RULE_ENGINE[Evaluate rules\nfor each active shift]
        DEDUP{Alert already\nexists in Firestore?}
    end

    subgraph Output [Alert Output]
        CREATE_ALERT[(CREATE Alert document\nin Firestore)]
        FCM[FCM push notification\nto Admin tokens]
        DASHBOARD[Alert badge\non Admin Dashboard]
        FEED[Alert entry\nin Activity Feed]
    end

    T1 --> QUERY
    T2 --> QUERY
    T3 --> QUERY
    T4 --> QUERY

    QUERY --> RULE_ENGINE
    RULE_ENGINE --> DEDUP
    DEDUP -->|Already exists| SKIP([Skip duplicate])
    DEDUP -->|New alert| CREATE_ALERT
    CREATE_ALERT --> FCM
    CREATE_ALERT --> DASHBOARD
    CREATE_ALERT --> FEED
```

---

## 10-Day Build Roadmap

```mermaid
gantt
    title Cipher-X 10-Day Build Plan - 40 PRs
    dateFormat YYYY-MM-DD
    section Phase 0 - Architecture
    PR 1 Product Documentation        :done, p1, 2025-01-01, 1d
    PR 2 System Architecture          :done, p2, after p1, 1d
    PR 3 Data and Security Design     :done, p3, after p2, 1d
    PR 4 Engineering Workflow         :done, p4, after p3, 1d
    section Phase 1 - Foundation
    PR 5 Flutter Bootstrap            :done, p5, 2025-01-02, 1d
    PR 6 Firebase Integration         :done, p6, after p5, 1d
    PR 7 Application Shell            :done, p7, after p6, 1d
    PR 8 CI Foundation                :done, p8, after p7, 1d
    section Phase 2 - Auth and RBAC
    PR 9 Firebase Authentication      :active, p9, 2025-01-03, 1d
    PR 10 User Profiles               :p10, after p9, 1d
    PR 11 Role-Based Navigation       :p11, after p10, 1d
    section Phase 3 - Guards and Sites
    PR 12 Guard Domain                :p12, 2025-01-04, 1d
    PR 13 Guard Management UI         :p13, after p12, 1d
    PR 14 Site Domain                 :p14, after p13, 1d
    PR 15 Site Management UI          :p15, after p14, 1d
    section Phase 4 - Shifts
    PR 16 Shift Domain                :p16, 2025-01-05, 1d
    PR 17 Shift Creation UI           :p17, after p16, 1d
    PR 18 Assignment Validation       :p18, after p17, 1d
    PR 19 Guard Shift Experience      :p19, after p18, 1d
    section Phase 5 - Attendance
    PR 20 Location Service            :p20, 2025-01-06, 1d
    PR 21 Geofence Engine             :p21, after p20, 1d
    PR 22 QR Verification             :p22, after p21, 1d
    PR 23 Secure Check-In             :p23, after p22, 1d
    PR 24 Check-Out and History       :p24, after p23, 1d
    section Phase 6 - Incidents
    PR 25 Incident Domain             :p25, 2025-01-08, 1d
    PR 26 Incident Reporting          :p26, after p25, 1d
    PR 27 Evidence Storage            :p27, after p26, 1d
    PR 28 Incident Management         :p28, after p27, 1d
    PR 29 Alert Engine                :p29, after p28, 1d
    section Phase 7 - Command Center
    PR 30 Admin Dashboard             :p30, 2025-01-09, 1d
    PR 31 Site Coverage               :p31, after p30, 1d
    PR 32 Alerts and Activity Feed    :p32, after p31, 1d
    section Phase 8 - Security
    PR 33 Firestore Security Rules    :p33, 2025-01-10, 1d
    PR 34 Validation and Error States :p34, after p33, 1d
    PR 35 Automated Tests             :p35, after p34, 1d
    PR 36 Security and QA Hardening   :p36, after p35, 1d
    section Phase 9 - Release
    PR 37 Production Configuration    :p37, 2025-01-11, 1d
    PR 38 UX Polish                   :p38, after p37, 1d
    PR 39 Demo Data and Docs          :p39, after p38, 1d
    PR 40 Final Release v1.0.0        :p40, after p39, 1d
```

### Phase Summary

| Phase | Scope | Days | PRs |
|---|---|---|---|
| Phase 0 | Product and architecture documentation | Day 1 morning | 4 |
| Phase 1 | Flutter bootstrap, Firebase integration, CI | Day 1 afternoon | 4 |
| Phase 2 | Authentication, user profiles, RBAC routing | Day 2 | 3 |
| Phase 3 | Guard domain, site domain, management UIs | Day 3 | 4 |
| Phase 4 | Shift management, assignment validation, guard shift view | Day 4 | 4 |
| Phase 5 | Location service, geofence engine, QR, secure check-in, check-out | Days 5–6 | 5 |
| Phase 6 | Incident domain, reporting, evidence upload, incident management, alert engine | Day 7 | 5 |
| Phase 7 | Admin dashboard, site coverage, alerts and activity feed | Day 8 | 3 |
| Phase 8 | Firestore security rules, validation, automated tests, security hardening | Day 9 | 4 |
| Phase 9 | Production config, UX polish, demo data, final release | Day 10 | 4 |
| **Total** | | **10 days** | **40 PRs** |

---

## Tech Stack

All infrastructure runs on the Firebase free tier. Zero paid services required.

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| Framework | Flutter | 3.x | Cross-platform mobile and web application |
| Language | Dart | 3.x | Type-safe application code |
| State management | Riverpod | Latest | AsyncNotifierProvider, StreamProvider, unidirectional data flow |
| Routing | GoRouter | Latest | Declarative navigation with role-based route guards |
| Data models | Freezed + json_serializable | Latest | Immutable data classes with value equality and JSON codegen |
| Authentication | Firebase Auth | Latest | Email/password login, custom role claims, session persistence |
| Database | Cloud Firestore | Latest | Real-time multi-tenant NoSQL with security rules |
| File storage | Firebase Storage | Latest | Incident evidence photos with type and size enforcement |
| Push notifications | Firebase Cloud Messaging | Latest | Alert delivery to admin and supervisor devices |
| App integrity | Firebase App Check | Latest | Client attestation preventing unauthorised API access |
| QR scanning | mobile_scanner | Latest | Camera-based QR code reading |
| Maps and geofence | geolocator + math | Latest | GPS permission, coordinates, Haversine distance calculation |

### Infrastructure Cost Breakdown

| Service | Free Tier Limit | Cipher-X Usage | Cost |
|---|---|---|---|
| Firebase Auth | Unlimited MAU | All users | Zero |
| Cloud Firestore | 1 GiB storage, 50k reads/day, 20k writes/day | Operational data | Zero |
| Firebase Storage | 5 GB storage, 1 GB/day download | Incident evidence | Zero |
| FCM | Unlimited messages | All push alerts | Zero |
| Firebase App Check | Included | All requests | Zero |
| Total | — | — | Zero |

---

## Project Structure

```
cipher-x/
|
+-- lib/
|   +-- app/
|   |   +-- app.dart                     # MaterialApp, theme, GoRouter configuration
|   |   +-- router.dart                  # All route definitions with role guard
|   |   +-- theme.dart                   # Light and dark theme configuration
|   |
|   +-- core/
|   |   +-- constants/                   # App constants, Firestore collection names
|   |   +-- errors/                      # Custom exception types, error formatting
|   |   +-- extensions/                  # Dart extensions (DateTime, String)
|   |   +-- services/
|   |   |   +-- firebase_service.dart    # Firebase initialisation and app check
|   |   |   +-- location_service.dart    # GPS permission and coordinate stream
|   |   |   +-- notification_service.dart# FCM token management and foreground handling
|   |   +-- utils/
|   |   |   +-- geofence_utils.dart      # Haversine distance calculation
|   |   |   +-- qr_utils.dart            # QR code generation and parsing
|   |   |   +-- shift_utils.dart         # Shift window and overlap validation
|   |   +-- widgets/
|   |       +-- loading_widget.dart
|   |       +-- error_widget.dart
|   |       +-- empty_state_widget.dart
|   |
|   +-- features/
|   |   +-- auth/
|   |   |   +-- data/                    # AuthRepository - Firebase Auth calls
|   |   |   +-- domain/                  # User model, role enum, auth state
|   |   |   +-- presentation/            # LoginScreen, SplashScreen, AuthController
|   |   +-- guards/
|   |   |   +-- data/                    # GuardRepository - Firestore CRUD
|   |   |   +-- domain/                  # Guard model, guard status enum
|   |   |   +-- presentation/            # GuardListScreen, GuardDetailScreen, CreateGuardScreen
|   |   +-- sites/
|   |   |   +-- data/                    # SiteRepository - Firestore CRUD, QR generation
|   |   |   +-- domain/                  # Site model with geofence fields
|   |   |   +-- presentation/            # SiteListScreen, SiteDetailScreen, CreateSiteScreen
|   |   +-- shifts/
|   |   |   +-- data/                    # ShiftRepository - CRUD, overlap validation
|   |   |   +-- domain/                  # Shift model, shift status enum
|   |   |   +-- presentation/            # ShiftCalendarScreen, CreateShiftScreen, GuardShiftScreen
|   |   +-- attendance/
|   |   |   +-- data/                    # AttendanceRepository - check-in, check-out
|   |   |   +-- domain/                  # Attendance model, verification method enum
|   |   |   +-- engines/
|   |   |   |   +-- geofence_engine.dart # Haversine verification with accuracy weighting
|   |   |   |   +-- qr_engine.dart       # QR payload validation against site document
|   |   |   |   +-- shift_engine.dart    # Sequential gate evaluation
|   |   |   +-- presentation/            # CheckInScreen, AttendanceHistoryScreen
|   |   +-- incidents/
|   |   |   +-- data/                    # IncidentRepository, evidence upload via Storage
|   |   |   +-- domain/                  # Incident model, severity enum, status enum
|   |   |   +-- presentation/            # ReportIncidentScreen, IncidentListScreen, IncidentDetailScreen
|   |   +-- alerts/
|   |   |   +-- data/                    # AlertRepository - create, acknowledge
|   |   |   +-- domain/                  # Alert model, alert type enum
|   |   |   +-- engine/
|   |   |   |   +-- alert_engine.dart    # Client-side rule evaluation against Firestore
|   |   |   +-- presentation/            # AlertFeedWidget, AlertBadgeWidget
|   |   +-- dashboard/
|   |       +-- data/                    # DashboardRepository - aggregated queries
|   |       +-- domain/                  # DashboardStats model
|   |       +-- presentation/            # AdminDashboardScreen, CoverageScreen, ActivityFeedScreen
|   |
|   +-- main.dart                        # Entry point, Firebase init, Riverpod scope
|
+-- test/
|   +-- unit/
|   |   +-- geofence_engine_test.dart    # Inside, outside, boundary, poor accuracy
|   |   +-- shift_validator_test.dart    # Overlap, inactive guard, invalid window
|   |   +-- attendance_test.dart         # Sequential gate tests
|   |   +-- rbac_test.dart               # Role permission matrix tests
|   |   +-- incident_test.dart           # Severity, status transitions
|   +-- widget/
|       +-- check_in_screen_test.dart
|       +-- dashboard_screen_test.dart
|
+-- firestore.rules                      # Firestore security rules with multi-tenant isolation
+-- storage.rules                        # Firebase Storage security rules for evidence
+-- firebase.json                        # Firebase project configuration
+-- .firebaserc                          # Firebase project aliases
+-- pubspec.yaml                         # Flutter dependencies
+-- analysis_options.yaml               # Dart linting rules
+-- .github/
|   +-- workflows/
|       +-- ci.yml                       # Flutter analyze, test, format on every PR
+-- docs/                                # Full documentation suite
+-- CONTRIBUTING.md
+-- LICENSE
+-- README.md
```

---

## Security Model

Cipher-X implements a three-layer defence-in-depth model.

**Layer 1 — Firebase App Check**: Every request to Firestore and Firebase Storage is attested by App Check. Requests from non-genuine clients (emulators, API scraping tools, modified APKs) are rejected before any data is accessed.

**Layer 2 — Firestore Security Rules**: Every read and write is evaluated against rules that enforce authentication, role verification, and organisation isolation. No client can bypass these rules regardless of what Flutter code sends.

**Layer 3 — Application RBAC**: GoRouter guards prevent unauthenticated or unauthorised navigation. Riverpod providers reject state mutations from non-privileged roles before any repository call is made.

### Security Rules Design Principles

| Principle | Implementation |
|---|---|
| Deny by default | All documents deny read and write unless a matching `allow` rule explicitly permits it |
| Authentication required | Every rule begins with `request.auth != null` — unauthenticated access is impossible |
| Organisation isolation | Every query and mutation must include `organizationId == request.auth.token.organizationId` |
| Role-based write control | Only users with the Admin or Supervisor role claim can write to guard, site, shift, and incident collections |
| Guard self-access only | Guards can only read their own user document and attendance records — not other guards' data |
| Immutable audit logs | Audit log documents deny update and delete — only create is permitted, enforcing an append-only ledger |
| Evidence access control | Firebase Storage rules restrict evidence downloads to users in the same organisation as the incident |

### Security Test Matrix (PR #33 and #36)

```
Guard reads another guard's document        -> DENY
Guard reads admin dashboard data            -> DENY
Guard modifies their own attendance record  -> DENY
Guard reads audit logs                      -> DENY
Organisation A reads Organisation B data    -> DENY
Unauthenticated request to any document     -> DENY
Admin creates a guard document              -> ALLOW
Guard creates attendance for own shift      -> ALLOW
Guard creates incident report               -> ALLOW
```

---

## Getting Started

### Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Flutter SDK | 3.41.0+ | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| Dart SDK | 3.11.0+ | Bundled with Flutter |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| VS Code or Android Studio | Latest | With Flutter and Dart plugins |
| Java | 17+ | Required for Android build |

### Installation

```bash
# Clone the repository
git clone https://github.com/kalviumcommunity/-S116-0826-Decrypters-Full-Stack-With-Flutter-Dart-Firebase-CipherX.git
cd -S116-0826-Decrypters-Full-Stack-With-Flutter-Dart-Firebase-CipherX

# Install Flutter dependencies
flutter pub get

# Run code generation (Freezed and json_serializable)
dart run build_runner build --delete-conflicting-outputs
```

---

## Firebase Emulator Setup

Run the full Firebase backend locally with no cloud connection required — zero cost, zero quota consumption during development.

```bash
# Authenticate with Firebase
firebase login

# Start all required emulators
firebase emulators:start --only auth,firestore,storage

# Emulator UI available at:
# http://localhost:4000

# Individual emulator ports:
# Auth:      http://localhost:9099
# Firestore: http://localhost:8080
# Storage:   http://localhost:9199
```

Configure the Flutter app to point to local emulators by setting the `USE_EMULATOR=true` environment flag or via the `--dart-define` build flag.

### Launch the App

```bash
# Android device or emulator
flutter run -d android

# iOS simulator (macOS only)
flutter run -d ios

# Chrome (web)
flutter run -d chrome

# With specific device ID
flutter devices
flutter run -d <device_id>
```

### Code Quality

```bash
# Dart static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Format code
dart format .

# Rebuild generated files after model changes
dart run build_runner build --delete-conflicting-outputs
```

---

## Definition of Done

A PR is not considered complete until every item is checked:

| Category | Checklist |
|---|---|
| Functionality | Feature works end-to-end |
| Code quality | `flutter analyze` passes with zero issues |
| Formatting | `dart format .` produces no changes |
| Tests | Relevant unit or widget tests pass |
| State coverage | Loading state, success state, error state, and empty state all exist |
| Security | Security implications reviewed — does this expose data incorrectly? |
| Firestore | Queries reviewed — are indexes required? Is pagination applied? |
| Stability | No obvious runtime errors on happy path or error path |
| UX | UI is usable on a physical device |
| Review | At least one teammate has reviewed and approved the PR |
| Docs | Relevant documentation updated if architecture or data model changed |

---

## Priority System

When time becomes tight, cut in this order:

| Priority | Features | Decision |
|---|---|---|
| P0 — Must ship | Auth, RBAC, Guards, Sites, Shifts, GPS, Geofence, QR, Check-in, Check-out, Incidents, Dashboard, Security Rules | Never cut |
| P1 — Should ship | Alerts, Evidence, Coverage, Audit logs, Analytics | Cut only if P0 is at risk |
| P2 — Can cut | Advanced animations, complex analytics, advanced filtering, video evidence | Cut first |
| P3 — Future | AI, face recognition, predictive absenteeism, payroll, chat, video calling | Not in MVP |

Never cut P0 security.

---

## Documentation Directory

| Document | Description |
|---|---|
| [PRODUCT_REQUIREMENTS.md](docs/PRODUCT_REQUIREMENTS.md) | Problem definition, target users, core workflows, success criteria |
| [SYSTEM_ARCHITECTURE.md](docs/SYSTEM_ARCHITECTURE.md) | Flutter architecture, Firebase topology, data flow diagrams |
| [TECH_STACK.md](docs/TECH_STACK.md) | Full technology choices with rationale and free-tier constraints |
| [USER_ROLES.md](docs/USER_ROLES.md) | RBAC matrix — Admin, Supervisor, Guard permissions per operation |
| [FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md) | Complete collection and document schema with field types |
| [SECURITY_MODEL.md](docs/SECURITY_MODEL.md) | Security rules design, multi-tenant isolation, App Check configuration |
| [ATTENDANCE_VERIFICATION.md](docs/ATTENDANCE_VERIFICATION.md) | Geofence engine, QR validation, sequential gate specification |
| [INCIDENT_WORKFLOW.md](docs/INCIDENT_WORKFLOW.md) | Incident lifecycle, evidence upload pipeline, admin resolution flow |
| [ALERT_SYSTEM.md](docs/ALERT_SYSTEM.md) | Alert trigger rules, client-side evaluation architecture, FCM delivery |
| [AUDIT_LOGGING.md](docs/AUDIT_LOGGING.md) | Audit log schema, immutability enforcement, query patterns |
| [DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) | Full 10-day, 40-PR execution plan with daily sync ritual |
| [GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) | Branch strategy, commit convention, PR review process |
| [MVP_SCOPE.md](docs/MVP_SCOPE.md) | P0/P1/P2/P3 scope boundaries with cut decision rules |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributor guidelines, PR checklist, ownership matrix |

---

## Team Decrypters

| Developer | Role | Ownership |
|---|---|---|
| Hardik Kaurani | Tech Lead and Architecture | System architecture, Firebase setup, Auth and RBAC, Firestore security rules, geofence engine, attendance verification, core integration, code review, release |
| Gauri | Guard Experience Lead | Guard mobile app, shift experience, GPS, QR scanner, check-in and check-out, incident reporting, evidence upload, guard UX |
| Avadhut | Admin and Operations Lead | Admin dashboard, guard management UI, site and geofence management UI, shift scheduler, coverage dashboard, incident management, alert UI, QA support, demo data |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

```bash
# Never push directly to main
git checkout -b feature/your-feature-name
git commit -m "feat(scope): describe your change"
git push origin feature/your-feature-name
# Open a Pull Request
```

**Branch naming**: `feature/auth`, `feature/sites`, `feature/shifts`, `feature/attendance`, `feature/incidents`, `feature/dashboard`

**Commit format examples**:

```
feat(auth): add firebase authentication
feat(attendance): implement geofence verification
fix(shifts): prevent overlapping assignments
test(attendance): add geofence validation tests
```

Every PR requires one reviewer. Never approve blindly.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">

*Cipher-X — from informal WhatsApp attendance to a verifiable, real-time security operations platform.*

**Team Decrypters** — Hardik · Gauri · Avadhut

*10 Days. Startup Quality.*

</div>
