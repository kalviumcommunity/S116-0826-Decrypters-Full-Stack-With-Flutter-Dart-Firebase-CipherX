# Cipher-X Production Configuration & Observability

**Release:** v1.0.0  
**Budget:** ₹0 (Zero Paid Services Constraint)  
**Authentication:** Firebase Authentication (Email/Password)  
**Database:** Cloud Firestore (Multi-tenant document architecture)  
**Storage:** Firebase Storage (Incident evidence files)  

---

## 1. Zero-Cost Infrastructure Architecture

All production workflows in Cipher-X run strictly within the Firebase Spark (free) tier:
- **Cloud Firestore**: Standard reads, writes, and composite indexes.
- **Firebase Authentication**: User identity and token issuance.
- **Firebase Storage**: Evidence photo storage with size quotas enforced at client and rule levels.
- **Local Push & In-App Alerts**: Reactive Riverpod streams avoid external paid webhook / SMS providers.

## 2. Observability & Logging Strategy
- Centralized `FailureMapper` formats all domain, platform, and network exceptions into non-sensitive user alerts.
- Structured logging using Flutter's native logger.
- No third-party paid APM or monitoring services introduced.
