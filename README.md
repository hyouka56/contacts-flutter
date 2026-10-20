# Contacts Flutter

A minimal Android contacts app with a pure-black interface and white accents.

- Lists contacts stored on the phone and their phone numbers.
- Search by contact name or phone number.
- Tap a contact to see all saved phone numbers.
- Use the bottom-right plus button to open Android's contact editor and add a contact.
- Pull down on the list to refresh.
- No favorites, no recents, no call history, and no extra tabs.

The app reads the address book with read permission; creating a contact uses Android's system contact editor. The GitHub Actions workflow builds a release APK for arm64-v8a only and uploads it as an artifact.
