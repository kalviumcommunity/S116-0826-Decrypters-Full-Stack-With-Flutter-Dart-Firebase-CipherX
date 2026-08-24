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

// 5. Default deny rule
assert(rules.includes('match /{document=**}'), 'Default deny rule must exist');

console.log('✅ Firestore Security Rules Structural & Boundary Verification PASSED!');
