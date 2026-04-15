# Firebase Chat Setup (Firestore)

## 1) Create Firebase project
- Create a Firebase project.
- Add **Android** app + **iOS** app.

## 2) Configure Flutter (required)
This code expects Firebase to be configured via the standard FlutterFire files.

### Recommended (Web + Mobile): FlutterFire CLI
- Run `flutterfire configure`
- It will generate/overwrite: `lib/firebase_options.dart`

### Android
- Download `google-services.json`
- Put it here: `android/app/google-services.json`

### iOS
- Download `GoogleService-Info.plist`
- Put it here: `ios/Runner/GoogleService-Info.plist` (and ensure it’s added to the Runner target in Xcode)

## 3) Enable Authentication
- In Firebase Console → Authentication → Sign-in method
- Enable **Anonymous** sign-in.

## 4) Enable Cloud Firestore
- Create Firestore database (in production or test mode).

## 5) Suggested Firestore rules (basic)
Use this as a starting point (adjust when you add real store accounts):

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /chatThreads/{threadId} {
      allow read, write: if request.auth != null
        && request.resource.data.customerUid == request.auth.uid;

      match /messages/{messageId} {
        allow read, write: if request.auth != null
          && get(/databases/$(database)/documents/chatThreads/$(threadId)).data.customerUid == request.auth.uid;
      }
    }
  }
}
```

## Data model used by the app
- `chatThreads/{threadId}`
  - `customerUid`: uid of the logged-in (anonymous) customer
  - `storeKey`: store key like `store_elegance`
  - `storeName`: translated store name at creation time
  - `updatedAt`, `createdAt`
  - `lastMessageText`, `lastMessageAt`
- `chatThreads/{threadId}/messages/{autoId}`
  - `sender`: `customer` or `store`
  - `text`
  - `createdAt`
  - `senderUid`

