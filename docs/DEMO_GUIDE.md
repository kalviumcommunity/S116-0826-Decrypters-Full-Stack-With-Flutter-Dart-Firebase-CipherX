# Cipher-X Operations Demo Walkthrough Guide

Follow this guided operational flow to demonstrate the end-to-end capabilities of Cipher-X v1.0.0.

---

## Persona 1: System Administrator
1. **Login**: Authenticate as Admin user.
2. **Command Center**: View real-time KPIs:
   - On Duty Guards
   - Site Coverage Status (Fully Staffed vs Understaffed)
   - Open Incidents & Critical Alerts
3. **Shift Assignment**: Navigate to Shifts -> Assign Shift to Guard Rahul Sharma at Cyber Gateway Tech Park.

---

## Persona 2: Security Guard
1. **Login**: Authenticate as Guard Rahul Sharma.
2. **My Shifts**: Discover scheduled shift for Cyber Gateway Tech Park.
3. **Check-In**:
   - Tap Check-In CTA.
   - Device verifies GPS presence within 75m geofence radius.
   - Scan Site QR Code.
   - Attendance is verified and recorded atomically in Cloud Firestore.
4. **Incident Reporting**:
   - Tap 'Report Incident'.
   - Select Severity: High. Type: 'Unauthorized Entry Attempt'.
   - System auto-acquires GPS location and attaches timestamp.
   - Submit report.
   - Instant Alert broadcast to Admin Command Center feed.
5. **Check-Out**:
   - Access Active Attendance session.
   - Tap 'Check Out'. Session is marked completed and locked against tampering.
