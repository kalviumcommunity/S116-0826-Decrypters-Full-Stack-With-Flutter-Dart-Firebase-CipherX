# Cipher-X Command Center & Site Coverage Architecture (PR #30 + PR #31)

## Overview
This architectural specification unifies **PR #30 (Admin Dashboard / Command Center)** and **PR #31 (Site Coverage)** into a single, cohesive, high-performance operational cockpit for Cipher-X administrators.

## 1. Core Objectives
The Command Center answers 10 operational questions in real time:
1. **Total Guards**: Total active/registered workforce in the tenant organization.
2. **On Duty**: Number of guards with active checked-in attendance records currently on site.
3. **Absent**: Scheduled shift guards who have missed their shift boundary without a check-in.
4. **Late**: Guards who have exceeded the lateness threshold past scheduled shift start.
5. **Active Sites**: Total operational facilities active in the tenant organization.
6. **Open Incidents**: Total incidents in `OPEN` lifecycle status requiring investigation.
7. **Critical Alerts**: Active high-severity alerts (`CRITICAL_INCIDENT`, understaffed conditions).
8. **Fully Staffed Sites**: Sites where actual checked-in guards meet or exceed scheduled requirement.
9. **Understaffed Sites**: Sites experiencing a workforce deficit (`actual < required`).
10. **Site-by-Site Staffing Ratio**: Granular `actual / required` staffing ratio with filtering (`All`, `Fully Staffed`, `Understaffed`).

## 2. Dependency Direction & Layering

```
UI (AdminDashboardScreen & SiteCoverageView)
  ↓
Presentation State (DashboardStatisticsNotifier & SiteCoverageFilterProvider)
  ↓
Application / Domain Services (DashboardStatisticsService & SiteCoverageService)
  ↓
Repository Interfaces (GuardRepo, SiteRepo, ShiftRepo, AttendanceRepo, IncidentRepo, AlertRepo)
  ↓
Infrastructure (Firebase Data Sources with Organization Isolation)
```

## 3. Strict Multi-Tenant Security & RBAC
- Every query is strictly parameterized by the authenticated administrator's `organizationId`.
- No global collections or unscoped queries are executed.
- Read access is bounded by existing Firestore security rules under `/organizations/{organizationId}/*`.
