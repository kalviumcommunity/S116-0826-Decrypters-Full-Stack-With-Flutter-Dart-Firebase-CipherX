const fs = require('fs');
const assert = require('assert');

console.log('Testing Firestore Security Rules syntax and boundaries...');

const rules = fs.readFileSync('firestore.rules', 'utf8');

// 1. Must enforce rules_version = '2'
assert(rules.includes("rules_version = '2';"), 'Rules must specify rules_version = 2');

// 2. Must restrict /users/{userId}
assert(rules.includes('match /users/{userId}'), 'Rules must define /users/{userId} match');
assert(rules.includes('request.auth.uid == userId'), 'Rules must enforce self ownership');

// 3. Must protect identity fields on update
assert(rules.includes('request.resource.data.uid == resource.data.uid'), 'UID must be immutable');
assert(rules.includes('request.resource.data.organizationId == resource.data.organizationId'), 'organizationId must be immutable');
assert(rules.includes('request.resource.data.status == resource.data.status'), 'status must be immutable');
assert(rules.includes('request.resource.data.role == resource.data.role'), 'role must be immutable');

// 4. Must deny client-side organization writes
assert(rules.includes('match /organizations/{organizationId}'), 'Rules must define /organizations match');
assert(rules.includes('allow write: if false;'), 'Organization writes must be denied for clients');

// 5. Must secure /organizations/{organizationId}/attendance/{attendanceId}
assert(rules.includes('match /attendance/{attendanceId}'), 'Rules must define /attendance/{attendanceId} subcollection');
assert(rules.includes("data.role == 'guard'"), 'Must require guard role for attendance creation');
assert(rules.includes('request.resource.data.guardId == request.auth.uid'), 'Must require guard self-ownership');
assert(rules.includes('request.resource.data.organizationId == organizationId'), 'Must enforce tenant isolation');
assert(rules.includes('request.resource.data.shiftId is string'), 'Must validate shiftId');
assert(rules.includes('request.resource.data.siteId is string'), 'Must validate siteId');
assert(rules.includes('request.resource.data.checkInTime == resource.data.checkInTime'), 'checkInTime must be immutable on update');
assert(rules.includes('allow delete: if false;'), 'Attendance deletion must be strictly forbidden');

// 6. Default deny rule
assert(rules.includes('match /{document=**}'), 'Default deny rule must exist');

console.log('✅ Firestore Security Rules Structural & Boundary Verification PASSED!');
