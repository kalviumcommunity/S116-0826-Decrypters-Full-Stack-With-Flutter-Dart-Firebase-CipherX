# Cipher-X

**Production-Grade Workforce Operations, Geofenced Attendance & Incident Response Platform**  
*Team Decrypters — v1.0.0 Release*

---

## 1. Overview

Cipher-X is a physical security workforce management platform built with **Flutter**, **Riverpod**, and **Cloud Firestore**. It combines high-reliability field execution for on-duty security guards with real-time operational command for security supervisors and administrative dispatchers.

### Core Capabilities:
- **Two-Factor Physical Attendance**: Hardware-agnostic QR code verification coupled with Haversine geofencing with GPS accuracy filtering (<= 50m).
- **Zero-Trust Multi-Tenancy**: Organization-scoped isolation enforced at both Firestore security rules and client query tiers.
- **Real-Time Incident Reporting**: Structured incident reporting with evidence capture, resolution workflows, and automatic alerts for critical/high severity events.
- **Admin Command Center**: Real-time facility staffing coverage metrics, on-duty ratios, incident dispatch, and activity feeds.
- **₹0 Infrastructure Budget**: Fully operational within standard Firebase Free (Spark) tier and local emulators without paid servers.

---

## 2. Quick Start & Setup

See the comprehensive [Setup Guide](docs/SETUP_GUIDE.md) for full instructions.

```bash
# 1. Clone repository
git clone https://github.com/kalviumcommunity/-S116-0826-Decrypters-Full-Stack-With-Flutter-Dart-Firebase-CipherX.git
cd -S116-0826-Decrypters-Full-Stack-With-Flutter-Dart-Firebase-CipherX

# 2. Get dependencies
flutter pub get

# 3. Run analyzer & tests
flutter analyze
flutter test

# 4. Run application
flutter run
```

---

## 3. Demo Walkthrough

Follow the step-by-step [Demo Guide](docs/DEMO_GUIDE.md) to experience:
1. Admin Command Center & Facility Staffing Coverage.
2. Guard Shift Discovery & Two-Factor Geofenced Check-in.
3. Incident Logging with Evidence & Real-time Alert Generation.
4. Incident Resolution & Guard Check-Out.

---

## 4. Documentation Index

- [Setup Guide](docs/SETUP_GUIDE.md)
- [Demo Walkthrough Guide](docs/DEMO_GUIDE.md)
- [Known Limitations & Architecture Decisions](docs/KNOWN_LIMITATIONS.md)
- [Production Release Audit](docs/RELEASE_AUDIT.md)
- [Firestore Security Rules](docs/FIRESTORE_SECURITY.md)
- [System Architecture](docs/SYSTEM_ARCHITECTURE.md)
