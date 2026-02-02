# Pool & Snooker Management Application

## Setup Instructions

### Backend
1. Ensure MongoDB is running on `mongodb://localhost:27017/ttc_pool`.
2. Navigate to `backend` directory.
3. Install dependencies: `npm install`.
4. Start the server: `npm start`.
5. Seed initial users (one-time):
   Run `curl -X POST http://localhost:5000/api/auth/seed` or use Postman.
   - **Admin**: username: `admin`, password: `admin123`
   - **Staff**: username: `staff`, password: `staff123`

### Frontend (Flutter)
1. Ensure Flutter is installed.
2. Navigate to `ttc_pool`.
3. Fetch dependencies: `flutter pub get`.
4. Run on your platform of choice: `flutter run`.
   - **Note for Android Emulator**: The app is configured to use `10.0.2.2` to reach the local backend.
   - **Note for Web/Desktop**: You may need to change the `baseUrl` in `lib/services/api_service.dart` to `localhost`.

## Features Implemented
- **Secure Login**: Username/Mobile + Password.
- **Role-based Access**: Admin and Staff roles.
- **Auth Guard**: Restricted routes (Admin only).
- **Auto Logout**: Inactivity detection (reset on touch/interaction).
- **Session-based**: JWT token stored locally.
- **Premium UI**: Modern dark theme with Outfit typography.
