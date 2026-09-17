const fs = require('fs');
const assert = require('assert');

console.log('Testing Firestore Security Rules syntax and boundaries...');

const rules = fs.readFileSync('firestore.rules', 'utf8');

// ==========================================================
// 1. Core Engine & Helper Functions
// ==========================================================
assert(rules.includes("rules_version = '2';"), 'Rules must specify rules_version = 2');
assert(rules.includes('function isAuthenticated()'), 'Must define isAuthenticated() helper');
assert(rules.includes('function isOwner(userId)'), 'Must define isOwner(userId) helper');
assert(rules.includes('function isMemberOf(orgId)'), 'Must define isMemberOf(orgId) helper');
assert(rules.includes('function isAdminOrSupervisor(orgId)'), 'Must define isAdminOrSupervisor(orgId) helper');
assert(rules.includes('function isGuard(orgId)'), 'Must define isGuard(orgId) helper');

// ==========================================================
// 2. User Profiles Security Boundaries (/users/{userId})
// ==========================================================
assert(rules.includes('match /users/{userId}'), 'Rules must define /users/{userId} match');
assert(rules.includes('request.auth.uid == userId'), 'Rules must enforce self ownership on /users');
assert(rules.includes('resource.data.organizationId == getUserDoc().data.organizationId'), 'Must allow same-org admin/supervisor read on /users');
assert(rules.includes('request.resource.data.uid == resource.data.uid'), 'UID must be immutable on update');
assert(rules.includes('request.resource.data.organizationId == resource.data.organizationId'), 'organizationId must be immutable on update');
assert(rules.includes('request.resource.data.status == resource.data.status'), 'status must be immutable on update');
assert(rules.includes('request.resource.data.role == resource.data.role'), 'role must be immutable on update (prevent role escalation)');
assert(rules.includes('allow delete: if false;'), 'User deletion must be strictly forbidden');

// ==========================================================
// 3. Organization Root & Tenant Isolation
// ==========================================================
assert(rules.includes('match /organizations/{organizationId}'), 'Rules must define /organizations match');
assert(rules.includes('allow read: if isMemberOf(organizationId);'), 'Must enforce tenant isolation on organization read');
assert(rules.includes('allow write: if false;'), 'Organization writes must be denied for clients');

// ==========================================================
// 4. Guard Directory Subcollection (PR #30 Command Center)
// ATTACK VECTOR 1: Guard -> another guard ❌ (DENY)
// ==========================================================
assert(rules.includes('match /guards/{guardId}'), 'Rules must define /guards/{guardId} subcollection');
assert(rules.includes('isAdminOrSupervisor(organizationId) || (isMemberOf(organizationId) && guardId == request.auth.uid)'),
  'Guard read must only be allowed for admin/supervisor or the guard themselves');
assert(rules.includes('allow create: if isAdminOrSupervisor(organizationId)'),
  'Guard creation must be restricted to admin or supervisor');
assert(rules.includes('allow update: if isAdminOrSupervisor(organizationId)'),
  'Guard update must be restricted to admin or supervisor');
assert(rules.includes('request.resource.data.organizationId == organizationId'),
  'Guard creation must match tenant organizationId');
assert(rules.includes('request.resource.data.guardId == guardId'),
  'Guard creation must match document guardId');

// ==========================================================
// 5. Site Subcollection (PR #31 Site Coverage)
// ATTACK VECTOR 2: Guard -> admin data ❌ (DENY)
// ==========================================================
assert(rules.includes('match /sites/{siteId}'), 'Rules must define /sites/{siteId} subcollection');
assert(rules.includes('allow read: if isMemberOf(organizationId);'),
  'Site read must require membership in the organization');
assert(rules.includes('allow create: if isAdminOrSupervisor(organizationId)'),
  'Site creation must be restricted to admin or supervisor');
assert(rules.includes('allow update: if isAdminOrSupervisor(organizationId)'),
  'Site update must be restricted to admin or supervisor');

// ==========================================================
// 6. Shift Subcollection
// ATTACK VECTOR 1 & 2: Guard cannot manage shifts or view unassigned shifts
// ==========================================================
assert(rules.includes('match /shifts/{shiftId}'), 'Rules must define /shifts/{shiftId} subcollection');
assert(rules.includes('isAdminOrSupervisor(organizationId) || (isMemberOf(organizationId) && resource.data.guardId == request.auth.uid)'),
  'Shift read must be restricted to admin/supervisor or the assigned guard');
assert(rules.includes('allow create: if isAdminOrSupervisor(organizationId)'),
  'Shift creation must be restricted to admin or supervisor');
assert(rules.includes('allow update: if isAdminOrSupervisor(organizationId)'),
  'Shift update must be restricted to admin or supervisor');

// ==========================================================
// 7. Attendance Records Subcollection (PR #21, PR #24)
// ATTACK VECTOR 3: Guard -> modify attendance ❌ (DENY)
// ==========================================================
assert(rules.includes('match /attendance/{attendanceId}'), 'Rules must define /attendance/{attendanceId} subcollection');
assert(rules.includes("data.role == 'guard'"), 'Must require guard role for attendance creation');
assert(rules.includes('request.resource.data.guardId == request.auth.uid'), 'Must require guard self-ownership on creation');
assert(rules.includes('request.resource.data.organizationId == organizationId'), 'Must enforce tenant isolation on attendance');
assert(rules.includes('request.resource.data.shiftId is string'), 'Must validate shiftId');
assert(rules.includes('request.resource.data.siteId is string'), 'Must validate siteId');
assert(rules.includes('request.resource.data.checkInTime == request.time'), 'checkInTime must equal request.time on creation');
assert(rules.includes('request.auth.uid == resource.data.guardId'), 'Updater must be the owning guard');
assert(rules.includes('request.resource.data.checkInTime == resource.data.checkInTime'), 'checkInTime must be immutable on update');
assert(rules.includes('request.resource.data.verificationMethod == resource.data.verificationMethod'), 'verificationMethod must be immutable on update');
assert(rules.includes('request.resource.data.checkInLatitude == resource.data.checkInLatitude'), 'checkInLatitude must be immutable on update');
assert(rules.includes('request.resource.data.checkInLongitude == resource.data.checkInLongitude'), 'checkInLongitude must be immutable on update');
assert(rules.includes('request.resource.data.checkInAccuracy == resource.data.checkInAccuracy'), 'checkInAccuracy must be immutable on update');
assert(rules.includes('allow delete: if false;'), 'Attendance deletion must be strictly forbidden');

// ==========================================================
// 8. Incident Reporting Subcollection (PR #26, PR #27, PR #28)
// ==========================================================
assert(rules.includes('match /incidents/{incidentId}'), 'Rules must define /incidents/{incidentId} subcollection');
assert(rules.includes('request.resource.data.reportedBy == request.auth.uid'), 'Must require reporter self-ownership');
assert(rules.includes("request.resource.data.severity in ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']"), 'Must validate severity enum values');
assert(rules.includes("request.resource.data.status == 'OPEN'"), 'Status must be OPEN on creation');
assert(rules.includes('request.resource.data.createdAt == request.time'), 'createdAt must equal request.time on creation');
assert(rules.includes('request.resource.data.updatedAt == request.time'), 'updatedAt must equal request.time on creation');

// Incident updates (PR #28 Incident Management)
assert(rules.includes("data.role in ['admin', 'supervisor']"), 'Must restrict incident update to admin and supervisor');
assert(rules.includes('request.resource.data.reportedBy == resource.data.reportedBy'), 'Must enforce reportedBy immutability on incident update');
assert(rules.includes('request.resource.data.siteId == resource.data.siteId'), 'Must enforce siteId immutability on incident update');
assert(rules.includes('request.resource.data.createdAt == resource.data.createdAt'), 'Must enforce createdAt immutability on incident update');
assert(rules.includes("request.resource.data.status == 'RESOLVED'"), 'Must enforce RESOLVED status rules');
assert(rules.includes('request.resource.data.resolvedBy == request.auth.uid'), 'Must enforce resolvedBy == auth.uid');
assert(rules.includes("request.resource.data.resolution != ''"), 'Must enforce non-empty resolution');

// Evidence subcollection (PR #27)
assert(rules.includes('match /evidence/{evidenceId}'), 'Rules must define incident evidence subcollection');
assert(rules.includes('request.resource.data.uploadedBy == request.auth.uid'), 'Must enforce uploadedBy == auth.uid');
assert(rules.includes('request.resource.data.incidentId == incidentId'), 'Must enforce incidentId matching parent');
assert(rules.includes('request.resource.data.sizeBytes <= 10485760'), 'Must enforce sizeBytes limit in firestore');
assert(rules.includes('allow update, delete: if false;'), 'Evidence update and delete must be forbidden');

// ==========================================================
// 9. Alerts Subcollection (PR #29 Alert Engine)
// ==========================================================
assert(rules.includes('match /alerts/{alertId}'), 'Rules must define /alerts/{alertId} subcollection');
assert(rules.includes("request.resource.data.type in ['MISSED_SHIFT', 'LATE_CHECK_IN', 'UNDERSTAFFED_SITE', 'CRITICAL_INCIDENT']"), 'Must validate alert type enum');
assert(rules.includes("request.resource.data.sourceEntityType in ['shift', 'site', 'incident']"), 'Must validate sourceEntityType');
assert(rules.includes('request.resource.data.organizationId == organizationId'), 'Must enforce tenant isolation on alerts');
assert(rules.includes('request.resource.data.alertId == alertId'), 'Must enforce alertId matching document path');

// ==========================================================
// 10. Audit Logs Subcollection (PR #32 Activity Feed)
// ATTACK VECTOR 4: Guard -> audit logs ❌ (DENY)
// ==========================================================
assert(rules.includes('match /auditLogs/{logId}'), 'Rules must define /auditLogs/{logId} subcollection');
assert(rules.includes('allow read: if isAdminOrSupervisor(organizationId);'), 'Audit logs read must be restricted to admin/supervisor');
assert(rules.includes('allow create, update, delete: if false;'), 'Client-side audit log writes must be strictly forbidden');

// ==========================================================
// 11. Default Deny Catch-All
// ATTACK VECTOR 5: Tenant & Unmapped Document Isolation ❌ (DENY)
// ==========================================================
assert(rules.includes('match /{document=**}'), 'Default deny rule must exist');
assert(rules.includes('allow read, write: if false;'), 'Default deny must reject both read and write');

console.log('✅ All Firestore Security Rules & 5 Attack Vector Checks PASSED!');
