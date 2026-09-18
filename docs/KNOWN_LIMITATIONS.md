# Cipher-X Technical Known Limitations & Tradeoffs

**Target Version:** v1.0.0  
**Status:** Release Document  

---

## 1. ₹0 Infrastructure Constraint
- **No Background Serverless Webhooks**: Alerts and activity notifications are driven by reactive Firestore snapshot streams rather than dedicated Cloud Functions or paid webhook services.
- **FCM Push Notifications**: Real-time alerting within the app is instant via Riverpod streams. Native background OS push notifications require APNs / FCM Apple Developer and Google Play Console registrations which are out-of-scope for the local zero-cost MVP.

## 2. Physical Sensor Simulation (Emulators)
- **GPS Simulation**: On Android Virtual Devices or iOS Simulators, simulated coordinates must be injected via emulator control panels (e.g. Setting emulator location to `17.4483, 78.3742` for Cyber Gateway).
- **Camera QR Scanning**: Virtual camera or mock QR payloads are utilized on emulators where a physical camera lens is absent.

## 3. Offline Capabilities & Conflict Resolution
- Firestore offline persistence caches attendance records locally. However, initial authentication and session refresh require network connectivity.
