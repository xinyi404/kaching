# 🚀 Kaching Online Deployment Guide

This guide walks you through deploying **Kaching** online for free using:
1. **Backend:** [Render.com](https://render.com) (FastAPI + Managed Database)
2. **Frontend:** [Vercel](https://vercel.com) or [Firebase Hosting](https://firebase.google.com/docs/hosting) (Flutter Web)

---

## Architecture Overview

```
                      ┌───────────────────────────────┐
                      │   Flutter Web / Android App   │
                      │  (Hosted on Vercel / Phone)   │
                      └───────────────┬───────────────┘
                                      │
                        HTTPS / REST API Requests
                        (https://kaching-api.onrender.com)
                                      ▼
                      ┌───────────────────────────────┐
                      │    FastAPI Backend Server     │
                      │      (Hosted on Render)       │
                      └───────────────┬───────────────┘
                                      │
                                      ▼
                      ┌───────────────────────────────┐
                      │   Managed Cloud Database      │
                      │  (Render PostgreSQL or MySQL) │
                      └───────────────────────────────┘
```

---

## Part 1: Deploy Backend to Render (Free)

Render provides free hosting for Python/FastAPI services with automated SSL and GitHub sync.

### Step 1: Push your Code to GitHub
Ensure your repository is pushed to your GitHub account:
```bash
git add .
git commit -m "feat: add deployment configuration"
git push origin main
```

### Step 2: Create a Free Blueprint Service on Render
1. Go to [Render Dashboard](https://dashboard.render.com/) and sign in with GitHub.
2. Click **New +** > **Blueprint**.
3. Connect your **kaching** GitHub repository.
4. Render will automatically detect [`render.yaml`](./render.yaml).
5. It will provision:
   - **`kaching-db`**: A managed PostgreSQL database (free tier).
   - **`kaching-api`**: The FastAPI backend service.
6. Enter your `GEMINI_API_KEY` when prompted in the environment variables list.
7. Click **Apply**.

Render will build and deploy your backend. Once complete, you will receive a public URL such as:
```
https://kaching-api.onrender.com
```

### Step 3: Verify the Live Backend
Test that your backend is up by opening the following in your browser:
- Health check: `https://<YOUR-RENDER-APP>.onrender.com/health` (should return `{"status": "ok", "database": "connected"}`)
- Interactive Swagger docs: `https://<YOUR-RENDER-APP>.onrender.com/docs`

---

## Part 2: Deploy Frontend (Flutter Web)

Now point your Flutter app to your live backend URL: `https://<YOUR-RENDER-APP>.onrender.com`.

### Option A: Deploy to Vercel (Fastest & Free)

1. **Build the production web bundle with your API URL:**
   ```bash
   cd frontend
   flutter build web --release --dart-define=API_BASE_URL="https://<YOUR-RENDER-APP>.onrender.com"
   ```

2. **Deploy with Vercel CLI (or via Vercel Dashboard):**
   ```bash
   npm i -g vercel
   vercel --prod
   ```
   *When prompted, select `build/web` as your output directory (already configured in [`frontend/vercel.json`](./frontend/vercel.json)).*

3. Your live web app will be available at:
   ```
   https://kaching.vercel.app
   ```

---

### Option B: Deploy to Firebase Hosting (Free)

1. **Build the production web bundle:**
   ```bash
   cd frontend
   flutter build web --release --dart-define=API_BASE_URL="https://<YOUR-RENDER-APP>.onrender.com"
   ```

2. **Initialize & Deploy Firebase:**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init hosting  # Select existing project or create new, choose frontend/build/web
   firebase deploy --only hosting
   ```

3. Your live web app will be published to:
   ```
   https://<YOUR-PROJECT-ID>.web.app
   ```

---

## Part 3: Point Android App to the Online Backend

If you want to use the native Android APK on your phone and connect to your online server:

1. **Build the release APK with your live backend URL:**
   ```bash
   cd frontend
   flutter build apk --release --dart-define=API_BASE_URL="https://<YOUR-RENDER-APP>.onrender.com"
   ```

2. Locate the generated APK:
   ```
   frontend/build/app/outputs/flutter-apk/app-release.apk
   ```

3. Install it onto your phone:
   ```bash
   adb install -r frontend/build/app/outputs/flutter-apk/app-release.apk
   ```
   *(Or transfer the `.apk` file to your phone via Google Drive, Telegram, or WhatsApp and tap to install).*

---

## Environment Variables Reference

| Variable | Description | Example / Default |
|---|---|---|
| `DATABASE_URL` | Cloud database connection string | `postgresql+psycopg2://user:pass@host/kaching` |
| `GEMINI_API_KEY` | Google Gemini API Key | `AIzaSy...` |
| `DEFAULT_USER_ID` | Default user identifier | `1` |
| `API_BASE_URL` | Flutter client API endpoint | `https://kaching-api.onrender.com` |
