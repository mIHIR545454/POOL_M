# 🔑 DEPLOYMENT CREDENTIALS & SETUP

## ✅ JWT Secret Key (READY TO USE)

```
JWT_SECRET=ttc-pool-7f9a2b8e4c1d6f3a9e5b2c8d4f1a7e3b9c5d2f8a4e1b7c3d9f6a2e8b5c1d4f7a3e9b
```

**✅ This has been added to your local `.env` file**

---

## 🗄️ MongoDB Atlas Connection String

### After you complete MongoDB Atlas setup, your connection string will look like:

```
MONGODB_URI=mongodb+srv://pooladmin:YOUR_PASSWORD@poolcluster.xxxxx.mongodb.net/ttc_pool?retryWrites=true&w=majority
```

### Replace these parts:
- `YOUR_PASSWORD` → The password you generated in MongoDB Atlas
- `poolcluster.xxxxx` → Your actual cluster address (MongoDB will give you this)

### Example (with fake credentials):
```
MONGODB_URI=mongodb+srv://pooladmin:aB3xK9mP2qR7sT4v@poolcluster.abc123.mongodb.net/ttc_pool?retryWrites=true&w=majority
```

---

## 📋 Complete Environment Variables for Render

When deploying to Render, add these 4 environment variables:

### 1. MONGODB_URI
```
mongodb+srv://pooladmin:YOUR_PASSWORD@poolcluster.xxxxx.mongodb.net/ttc_pool?retryWrites=true&w=majority
```
*(Replace with your actual connection string from MongoDB Atlas)*

### 2. JWT_SECRET
```
ttc-pool-7f9a2b8e4c1d6f3a9e5b2c8d4f1a7e3b9c5d2f8a4e1b7c3d9f6a2e8b5c1d4f7a3e9b
```

### 3. NODE_ENV
```
production
```

### 4. PORT
```
10000
```

---

## 🚀 MongoDB Atlas Quick Setup Checklist

Follow these steps on https://cloud.mongodb.com:

- [ ] **Step 1**: Sign up / Login to MongoDB Atlas
- [ ] **Step 2**: Create FREE M0 cluster (choose AWS + Mumbai/Singapore region)
- [ ] **Step 3**: Create database user
  - Username: `pooladmin`
  - Password: (autogenerate and SAVE IT)
  - Privileges: "Read and write to any database"
- [ ] **Step 4**: Add IP whitelist
  - Click "Network Access"
  - Add IP: `0.0.0.0/0` (Allow from anywhere)
- [ ] **Step 5**: Get connection string
  - Click "Database" → "Connect" → "Connect your application"
  - Copy the connection string
  - Replace `<password>` with your password
  - Add `/ttc_pool` before the `?` to specify database name

---

## 📊 Your Current Local Setup

**Local .env file location**: `e:\ttc pool\backend\.env`

**Current values**:
```env
PORT=5001
MONGODB_URI=mongodb://localhost:27017/ttc_pool
JWT_SECRET=ttc-pool-7f9a2b8e4c1d6f3a9e5b2c8d4f1a7e3b9c5d2f8a4e1b7c3d9f6a2e8b5c1d4f7a3e9b
SESSION_TIMEOUT=1800000
TAX_RATE=12
```

---

## 🔄 Migrating Local Data to MongoDB Atlas (Optional)

If you have existing data in your local MongoDB and want to move it to Atlas:

### Step 1: Export local data
```bash
mongodump --db ttc_pool --out ./backup
```

### Step 2: Import to Atlas
```bash
mongorestore --uri "mongodb+srv://pooladmin:YOUR_PASSWORD@poolcluster.xxxxx.mongodb.net/ttc_pool" ./backup/ttc_pool
```

---

## ⚠️ IMPORTANT SECURITY NOTES

1. **NEVER commit `.env` file to GitHub** (already in `.gitignore` ✅)
2. **Keep your MongoDB password secure**
3. **Keep your JWT secret secure**
4. **For production, use strong passwords**

---

## 🎯 Next Steps

1. ✅ JWT Secret is ready (already in your local `.env`)
2. 🔲 Create MongoDB Atlas account → https://cloud.mongodb.com
3. 🔲 Follow the setup checklist above
4. 🔲 Get your connection string
5. 🔲 Update local `.env` with Atlas connection string (for testing)
6. 🔲 Add all 4 environment variables to Render
7. 🔲 Deploy to Render! 🚀

---

## 📞 Quick Links

- **MongoDB Atlas**: https://cloud.mongodb.com
- **Render Dashboard**: https://dashboard.render.com
- **Your GitHub Repo**: https://github.com/mIHIR545454/POOL_M

---

**Status**: 🟢 JWT Secret Ready | 🟡 MongoDB Atlas Setup Needed
