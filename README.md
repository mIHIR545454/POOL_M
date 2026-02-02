# Pool Table Management System

A real-time pool/billiard table management system with admin panel and staff dashboard.

## 🚀 Features

- **Real-time Updates**: Live table status updates using Socket.IO
- **Admin Panel**: Manage tables, rates, and games
- **Staff Dashboard**: Monitor active tables and sessions
- **Time Tracking**: Automatic time tracking with alerts
- **Multi-game Support**: Support for Pool, Snooker, and Billiards

## 🛠️ Tech Stack

### Backend
- Node.js + Express
- MongoDB + Mongoose
- Socket.IO for real-time updates
- JWT Authentication
- bcryptjs for password hashing

### Frontend
- Flutter (Mobile App)

## 📦 Deployment on Render

### Prerequisites
1. MongoDB Atlas account (free tier available)
2. Render account (free tier available)

### Step-by-Step Deployment

#### 1. Set up MongoDB Atlas
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a free cluster
3. Create a database user
4. Whitelist all IPs (0.0.0.0/0) for Render access
5. Get your connection string

#### 2. Deploy Backend on Render
1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository: `https://github.com/mIHIR545454/POOL_M.git`
4. Configure the service:
   - **Name**: `pool-backend` (or any name you prefer)
   - **Region**: Choose closest to your users
   - **Branch**: `main`
   - **Root Directory**: Leave empty (we have render.yaml)
   - **Environment**: `Node`
   - **Build Command**: `cd backend && npm install`
   - **Start Command**: `cd backend && npm start`
   - **Instance Type**: Free

5. Add Environment Variables:
   - `MONGODB_URI`: Your MongoDB Atlas connection string
   - `JWT_SECRET`: A random secure string (e.g., `your-super-secret-jwt-key-12345`)
   - `NODE_ENV`: `production`
   - `PORT`: `10000` (Render's default)

6. Click "Create Web Service"

#### 3. Verify Deployment
- Wait for the build to complete (5-10 minutes)
- Check the logs for "Server running on port 10000"
- Your API will be available at: `https://pool-backend.onrender.com`

### Environment Variables Required

```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/pool_db
JWT_SECRET=your-super-secret-jwt-key
PORT=10000
NODE_ENV=production
```

## 🔧 Local Development

### Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your MongoDB URI and JWT secret
npm start
```

The server will run on `http://localhost:5000`

### Frontend Setup (Flutter)
```bash
cd ttc_pool
flutter pub get
flutter run
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Tables
- `GET /api/tables` - Get all tables
- `POST /api/tables` - Create new table
- `PUT /api/tables/:id` - Update table
- `DELETE /api/tables/:id` - Delete table

### Admin
- `GET /api/admin/tables` - Get all tables (admin)
- `PUT /api/admin/tables/:id` - Update table (admin)

## 🔌 Socket.IO Events

### Client → Server
- `connection` - Client connects

### Server → Client
- `tableUpdate` - Table status updates
- `notification` - System notifications (time over, etc.)

## 🐛 Troubleshooting

### Render Deployment Issues

**Issue**: "Could not open requirements file"
- **Solution**: This is fixed by the `render.yaml` configuration file

**Issue**: "MongoDB connection failed"
- **Solution**: Check your MongoDB Atlas IP whitelist (should include 0.0.0.0/0)

**Issue**: "Port already in use"
- **Solution**: Render automatically sets PORT=10000, no action needed

### Local Development Issues

**Issue**: "Cannot connect to MongoDB"
- **Solution**: Check your `.env` file has correct MONGODB_URI

**Issue**: "Socket.IO not connecting"
- **Solution**: Ensure CORS is properly configured in `server.js`

## 📝 License

ISC

## 👨‍💻 Author

Mihir Darji

## 🔗 Links

- **GitHub**: https://github.com/mIHIR545454/POOL_M
- **Backend API**: https://pool-backend.onrender.com (after deployment)
