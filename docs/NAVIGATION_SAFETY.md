# Navigation & Responsive Layout Constraints

**Verified Flows:**
1. Authenticated Guard Route: `/guard/home` -> `/guard/shifts` -> `/guard/check-in` -> `/attendance/history`.
2. Admin Operations Route: `/admin/command-center` -> `/admin/guards` -> `/admin/sites` -> `/admin/shifts` -> `/admin/incidents`.
3. Safe back-navigation verified with GoRouter pop guards.
4. Compact layout overflow protection via SingleChildScrollView on forms and detail views.
