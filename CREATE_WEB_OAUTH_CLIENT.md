# Create Web OAuth Client - Next Step

## ✅ **After Creating Android Client:**

1. **Copy your Android Client ID** (the one that just appeared)
2. **Save it somewhere** - you'll need it for Flutter code later

---

## 🔴 **NOW CREATE WEB OAUTH CLIENT** (For Laravel Backend)

**You need BOTH:**
- ✅ Android Client ID (just created)
- ⏳ Web Client ID + Secret (need to create now)

---

### **Steps to Create Web OAuth Client:**

1. **Go back to "Clients" page:**
   - Click the **back arrow** (top left) or
   - Left sidebar → **"Clients"**

2. **Click "Create OAuth client"** button (top of page)

3. **Select Application Type:**
   - Choose **"Web application"** (NOT Android)

4. **Fill in the form:**
   - **Name**: `NavistFind Web`
   - **Authorized redirect URIs**: Click "Add URI" and add:
     ```
     http://localhost:8000/api/auth/google/callback
     ```
   - **Add another URI**:
     ```
     http://127.0.0.1:8000/api/auth/google/callback
     ```

5. **Click "Create"**

6. **💾 IMPORTANT - Copy BOTH:**
   - **Client ID**: `123456789-abc.apps.googleusercontent.com`
   - **Client Secret**: `GOCSPX-abc123...`
   
   **Save these for Laravel `.env` file!**

7. **Click "OK"**

---

## ✅ **What You Should Have Now:**

- ✅ **Android Client ID**: `987654321-xyz.apps.googleusercontent.com`
- ✅ **Web Client ID**: `123456789-abc.apps.googleusercontent.com`
- ✅ **Web Client Secret**: `GOCSPX-abc123...`

---

**After you create the Web client, let me know and I'll proceed with code implementation!**

