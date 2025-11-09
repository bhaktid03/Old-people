# Profile API Integration Analysis

## Executive Summary
**Status: NOT INTEGRATED** ❌

The profile screens (`profile_screen.dart` and `profile_setup_screen.dart`) are currently using hardcoded/mock data and have **NO API integration** with the backend profiles API.

## Current API Integration Pattern

Your codebase follows this pattern:

1. **API Client** (`lib/api/client/api_client.dart`)
   - Custom HTTP client using `dart:io`
   - Methods: `postJson`, `getJson`, `putJson`, `postMultipart`, `putMultipart`, `postMultipartMultiple`

2. **API Classes** (e.g., `AuthApi`, `HeadlinesApi`, `CommunityPostsApi`)
   - Wrap `ApiClient`
   - Located in `lib/api/{feature}/`
   - Handle specific feature endpoints

3. **Repository Pattern** (e.g., `AuthRepository`)
   - Wrap API classes
   - Provide abstraction layer
   - Located in `lib/api/{feature}/` or `lib/features/{feature}/data/`

4. **Endpoints** (`lib/api/common/endpoints.dart`)
   - Centralized endpoint definitions
   - Uses `apiBaseUrl` variable

5. **Authentication**
   - Currently NO JWT tokens in headers
   - Some APIs use `x-user-id` header (e.g., `HeadlinesApi`)
   - Session stored in `SessionManager` (userId, displayName)

## Profiles API Status

### Existing
- ✅ One endpoint defined: `updateProfile(String userId)` → `PUT /api/v1/profiles/$userId`

### Missing
- ❌ NO `profiles_api.dart` class
- ❌ NO `profiles_repository.dart` 
- ❌ NO profile model
- ❌ NO GET profile endpoint (should be `GET /api/v1/profiles/{userId}`)
- ❌ NO integration in profile screens

## Profile Screens Status

### `profile_screen.dart`
- ❌ Uses hardcoded data: `_myPosts` list with mock data
- ❌ Shows hardcoded "User Name" 
- ❌ Shows hardcoded "100 Points"
- ❌ NO API calls to fetch profile data
- ❌ NO API calls to fetch user posts
- ❌ Edit Profile button does nothing

### `profile_setup_screen.dart`
- ❌ Has UI for name and photo
- ❌ NO API call to update profile
- ❌ Just calls `onContinue` callback (handled in router)
- ❌ Photo file is never uploaded to backend

## Required Integration

### 1. Backend Endpoints Needed
```
GET  /api/v1/profiles/{userId}     - Get user profile
PUT  /api/v1/profiles/{userId}     - Update profile (already defined)
POST /api/v1/profiles/{userId}/photo - Upload profile photo (or use PUT with multipart)
GET  /api/v1/profiles/{userId}/posts - Get user's posts (for profile feed)
```

### 2. Files to Create

#### `lib/api/profiles/profiles_api.dart`
- `getProfile(String userId)` → GET profile
- `updateProfile(String userId, {String? displayName, File? photoFile})` → PUT profile
- Handle multipart upload for photo

#### `lib/api/profiles/profiles_repository.dart`
- Wrap `ProfilesApi`
- Provide clean interface for screens

#### `lib/api/profiles/models/profile.dart`
- Profile model with: userId, displayName, photoUrl, points, createdAt, etc.

### 3. Integration Points

#### `profile_screen.dart`
- Fetch profile on `initState()`
- Fetch user posts on `initState()`
- Display real data instead of hardcoded
- Handle loading/error states

#### `profile_setup_screen.dart`
- Call API to update profile on "Continue"
- Upload photo file to backend
- Handle success/error states

#### `lib/app/router.dart`
- Update `_onProfileContinue` to call profiles API
- Handle photo upload

## Implementation Notes

1. **Photo Upload**: Use `putMultipart` or `postMultipart` from `ApiClient`
2. **User ID**: Get from `SessionManager.userId`
3. **Error Handling**: Follow pattern from `AuthApi` (throw exceptions, catch in UI)
4. **Loading States**: Add loading indicators during API calls
5. **Caching**: Consider caching profile data locally

## Example API Response Structure (Assumed)

```json
{
  "userId": "123",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "points": 100,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

## Next Steps

1. ✅ Create profiles API class
2. ✅ Create profiles repository
3. ✅ Create profile model
4. ✅ Add GET profile endpoint
5. ✅ Add GET user posts endpoint
6. ✅ Integrate into `profile_screen.dart`
7. ✅ Integrate into `profile_setup_screen.dart`

## Implementation Status

### ✅ Completed

1. **Created `lib/api/profiles/profiles_api.dart`**
   - `getProfile(String userId)` - GET profile
   - `getUserPosts({required String userId, int? limit})` - GET user posts
   - `updateProfile({required String userId, String? displayName, File? photoFile})` - PUT profile with multipart support for photo

2. **Created `lib/api/profiles/profiles_repository.dart`**
   - Wrapper around ProfilesApi
   - Clean interface for screens

3. **Created `lib/api/profiles/models/profile.dart`**
   - Profile model with: userId, displayName, photoUrl, points, createdAt
   - Handles various JSON response formats

4. **Updated `lib/api/common/endpoints.dart`**
   - Added `getProfile(String userId)` endpoint
   - Added `getUserPosts(String userId, {int? limit})` endpoint

5. **Updated `lib/features/profile/presentation/profile_screen.dart`**
   - ✅ Fetches profile data on initState
   - ✅ Fetches user posts on initState
   - ✅ Displays real data (name, photo, points)
   - ✅ Shows loading state
   - ✅ Shows error state with retry
   - ✅ Pull-to-refresh support
   - ✅ Empty state for no posts

6. **Updated `lib/features/profile/presentation/profile_setup_screen.dart`**
   - ✅ Calls API to update profile on "Continue"
   - ✅ Uploads photo file to backend (multipart)
   - ✅ Shows loading state during submission
   - ✅ Shows success/error messages
   - ✅ Updates session with new display name

### ⚠️ Notes

1. **Backend Endpoints Required:**
   - `GET /api/v1/profiles/{userId}` - Must return profile data
   - `GET /api/v1/profiles/{userId}/posts?limit={limit}` - Must return user's posts
   - `PUT /api/v1/profiles/{userId}` - Must accept multipart/form-data for photo upload

2. **Response Format Expectations:**
   - Profile: `{userId, displayName, photoUrl?, points?, createdAt?}`
   - Posts: Array of post objects with fields like `{text, imageUrls?, videoPath?, likes, comments, createdAt, ...}`

3. **Error Handling:**
   - All API calls have try-catch blocks
   - Errors are displayed to users via snackbars
   - Retry functionality available

4. **Session Management:**
   - Uses `SessionManager` to get userId
   - Updates displayName in session after profile update

### 🔄 Testing Checklist

- [ ] Test profile fetch with valid userId
- [ ] Test profile fetch with invalid userId (should handle error gracefully)
- [ ] Test profile update with name only
- [ ] Test profile update with name + photo
- [ ] Test photo upload (verify multipart request format)
- [ ] Test user posts fetch
- [ ] Test empty posts state
- [ ] Test loading states
- [ ] Test error states and retry
- [ ] Test pull-to-refresh on profile screen

