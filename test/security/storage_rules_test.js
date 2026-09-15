const fs = require('fs');
const assert = require('assert');

console.log('Testing Firebase Storage Security Rules syntax and boundaries...');

const rules = fs.readFileSync('storage.rules', 'utf8');

// 1. Must enforce rules_version = '2'
assert(rules.includes("rules_version = '2';"), 'Storage rules must specify rules_version = 2');

// 2. Must match incidents/{incidentId}/evidence/{fileId}
assert(rules.includes('match /incidents/{incidentId}/evidence/{fileId}'), 'Must define incident evidence storage path');

// 3. Must require authentication for read & write
assert(rules.includes('request.auth != null'), 'Must require request.auth != null');

// 4. Must enforce 10 MB size limit
assert(rules.includes('10 * 1024 * 1024') || rules.includes('10485760'), 'Must enforce 10 MB file size limit');

// 5. Must restrict content types to images and pdf
assert(rules.includes('image/(jpeg|png|webp)') || rules.includes('image/jpeg'), 'Must validate allowed image types');
assert(rules.includes('application/pdf'), 'Must validate application/pdf');

// 6. Must prohibit delete
assert(rules.includes('allow delete: if false;'), 'Storage evidence deletion must be prohibited');

// 7. Default deny rule
assert(rules.includes('match /{allPaths=**}'), 'Default deny rule must exist');
assert(rules.includes('allow read, write: if false;'), 'Default deny must block read and write');

console.log('✅ Firebase Storage Security Rules Structural & Boundary Verification PASSED!');
