# Cipher-X — Firestore Security & Identity Schema Specification

> **Document Version**: 1.0.0  
> **Phase**: Phase 2 — Identity + Access Control  
> **PR**: #10 (User Profiles + Organization Membership)  

---

## 1. Security Architecture

Cipher-X separates **Authentication**, **Identity**, and **Authorization** into distinct architectural boundaries:

- **Authentication (PR #9)**: Managed by Firebase Authentication (`uid`, credentials, email verification).
- **Identity & Organization (PR #10)**: Managed by Firestore documents under `users/{uid}` and `organizations/{orgId}`.
- **Authorization & RBAC (PR #11)**: Role and permission enforcement across application routes and data queries.

---

## 2. Collection Schemas

### 2.1 Collection: `users`
> **Path**: `users/{uid}`

| Field | Type | Purpose | Client Mutability | Security Rule Enforcement |
|---|---|---|---|---|
| `uid` | `string` | Firebase Auth UID | **Immutable** | Enforced (Must match `request.auth.uid`) |
| `email` | `string` | Primary User Email | Immutable | Set from Auth |
| `displayName` | `string` | User Full Name | **Editable** | User can update |
| `phone` | `string` | Mobile Phone Number | **Editable** | User can update |
| `organizationId` | `string` | Tenant Isolation Key | **Immutable** | Cannot be modified by client |
| `status` | `string` | Account Status (`active`, `inactive`, `suspended`) | **Immutable** | Cannot be modified by client |
| `role` | `string` | Identity Role (`admin`, `supervisor`, `guard`) | **Immutable** | Cannot be modified by client |
| `createdAt` | `timestamp` | Server Creation Timestamp | **Immutable** | Enforced on write |
| `updatedAt` | `timestamp` | Server Update Timestamp | System Controlled | Server timestamp |

---

### 2.2 Collection: `organizations`
> **Path**: `organizations/{organizationId}`

| Field | Type | Purpose | Client Mutability | Security Rule Enforcement |
|---|---|---|---|---|
| `id` | `string` | Organization ID (e.g., `org_decrypters_001`) | **Immutable** | Read-Only for Members |
| `name` | `string` | Agency Name | Immutable | Read-Only |
| `code` | `string` | Agency Invite/Join Code | Immutable | Read-Only |
| `status` | `string` | Tenant Status (`active`, `inactive`) | Immutable | Read-Only |
| `createdAt` | `timestamp` | Server Creation Timestamp | Immutable | Read-Only |
| `updatedAt` | `timestamp` | Server Update Timestamp | Immutable | Read-Only |

---

## 3. Firestore Security Rules Summary

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read: if isOwner(userId);
      
      allow create: if isOwner(userId) 
        && request.resource.data.uid == userId
        && request.resource.data.organizationId != null
        && request.resource.data.organizationId != '';

      allow update: if isOwner(userId)
        && request.resource.data.uid == resource.data.uid
        && request.resource.data.organizationId == resource.data.organizationId
        && request.resource.data.status == resource.data.status
        && (!('createdAt' in resource.data) || request.resource.data.createdAt == resource.data.createdAt)
        && (!('role' in resource.data) || request.resource.data.role == resource.data.role);

      allow delete: if false;
    }

    match /organizations/{organizationId} {
      allow read: if isAuthenticated() 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.organizationId == organizationId;
      
      allow write: if false;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```
