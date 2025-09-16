HEAD
# Secure Wipe - Flutter UI (frontend-app)

This is the frontend (UI only). It must be integrated with the native wipe engine (Rust) and backend certificate service.

Run (dev):
1. Install Flutter SDK (with desktop support if needed).
2. `cd frontend-app`
3. `flutter pub get`
4. `flutter run -d <device>` (e.g. `-d windows`, `-d linux`, or connected Android)

Important integration points:
- MethodChannel (native): `secure_wipe/native`
  - Methods: `init()`, `detectDevice()`, `startWipe(Map params)`, `getWipeLog(String jobId)`
- EventChannel (progress events): `secure_wipe/events`
  - Sends JSON-like strings: `{"progress": 0.42, "message": "Overwriting..."}`

- Backend endpoints (replace `ApiService.baseUrl`):
  - `POST /api/wipe/submit` — accepts JSON log, returns `{ certificate: { id, json_url, pdf_url, hash, blockchain_tx } }`
  - `GET /api/cert/verify/{id}` — returns verification result

Notes:
- This UI intentionally does not implement destructive operations locally. The native engine performs wipes; Flutter communicates via channels.
- When integrating, ensure the native responses match the JSON schema used by DeviceModel and the certificate model.
=======
"# OneWipe" 
>>>>>>> 949af9b126679ae2ab10385673ee8fee4937137f
