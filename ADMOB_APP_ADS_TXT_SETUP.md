# AdMob app-ads.txt Setup Guide

## 🚨 **URGENT: Required for AdMob Compliance**

Starting January 2025, all AdMob apps **MUST** have app-ads.txt verification to prevent limited ad serving and revenue loss.

## 📄 **Your app-ads.txt File**

The `app-ads.txt` file has been created in your project root with the correct content:

```
google.com, pub-1738655803893663, DIRECT, f08c47fec0942fa0
```

## 🌐 **Step 1: Get Your Developer Website Domain**

You need to identify the **exact domain** listed in your Google Play Store app listing:

1. Go to [Google Play Console](https://play.google.com/console)
2. Find your "Empire Tycoon" app
3. Look for the **Developer Website** field in your app listing
4. Note the exact domain (e.g., `yourdomain.com`)

## 📋 **Step 2: Upload app-ads.txt to Your Website**

### Option A: If You Have a Website
Upload the `app-ads.txt` file to the **root directory** of your website:

**✅ Correct Location:**
```
https://yourdomain.com/app-ads.txt
```

**❌ Incorrect Locations:**
```
https://yourdomain.com/ads/app-ads.txt          ❌ Not in root
https://www.yourdomain.com/app-ads.txt          ❌ Wrong subdomain
https://yourdomain.com/empire-tycoon/app-ads.txt ❌ In subfolder
```

### Option B: If You Don't Have a Website

You need to create one! Here are quick options:

**Free Options:**
- **GitHub Pages** (Recommended for developers)
- **Netlify** 
- **Firebase Hosting**
- **Google Sites**

**Quick GitHub Pages Setup:**
1. Create GitHub repository named `yourusername.github.io`
2. Upload the `app-ads.txt` file to root
3. Enable GitHub Pages in repository settings
4. Your domain will be: `https://yourusername.github.io`

## 🔗 **Step 3: Update Google Play Store Listing**

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your "Empire Tycoon" app
3. Go to **Store presence** > **Store listing**
4. Add/Update the **Website** field with your domain
5. **Save changes**

**Important:** Use the exact domain format:
- ✅ `https://yourdomain.com` 
- ✅ `http://yourdomain.com`
- ❌ `www.yourdomain.com` (if your actual domain doesn't use www)

## ✅ **Step 4: Verify Setup**

### Manual Check:
Visit your app-ads.txt URL in a browser:
```
https://yourdomain.com/app-ads.txt
```

You should see:
```
google.com, pub-1738655803893663, DIRECT, f08c47fec0942fa0
```

### AdMob Verification:
1. Go to [AdMob Console](https://admob.google.com)
2. Navigate to **Apps** > **View all apps**
3. Find your "Empire Tycoon" app
4. Check the **app-ads.txt status**
5. If needed, click **Crawl** to trigger verification

## ⏰ **Timeline & Important Notes**

### Processing Time:
- **Google Play Store**: Up to 24 hours to detect website changes
- **AdMob Crawling**: Up to 24 hours to verify app-ads.txt
- **Total**: Allow 48 hours for complete verification

### Critical Requirements:
- ✅ File must be accessible via HTTP/HTTPS
- ✅ File must return HTTP 200 status
- ✅ Domain must match Google Play Store exactly
- ✅ No redirects allowed
- ✅ File must be in plain text format

## 🚨 **What Happens Without app-ads.txt?**

Starting January 2025:
- ❌ **Limited ad serving** (reduced revenue)
- ❌ **Policy center notifications**
- ❌ **Potential account issues**

## 📊 **Your AdMob Details**

**Publisher ID:** `pub-1738655803893663`
**App ID (Test):** `ca-app-pub-1738655803893663~7413442778`

## 🛠 **Troubleshooting**

### Common Issues:

**1. "App-ads.txt file not found"**
- Check URL is accessible in browser
- Ensure file is in root directory
- Verify no typos in filename

**2. "Developer website missing"**
- Add website to Google Play Store listing
- Wait 24 hours for Google to detect changes

**3. "Domain mismatch"**
- Ensure Play Store domain matches app-ads.txt domain exactly
- Check for www vs non-www differences

**4. "File format error"**
- Ensure plain text file (not .docx or .html)
- Check for extra spaces or characters
- Verify exact content matches requirement

### Test Your Setup:
```bash
# Test if your app-ads.txt is accessible
curl -I https://yourdomain.com/app-ads.txt

# Should return: HTTP/1.1 200 OK
```

## 📞 **Need Help?**

If you encounter issues:
1. Check [AdMob Help Center](https://support.google.com/admob)
2. Verify each step above carefully
3. Wait full 48 hours before troubleshooting
4. Contact AdMob support if issues persist

---

## 🎯 **Quick Checklist**

- [ ] Created app-ads.txt file with correct content
- [ ] Uploaded to root of developer website  
- [ ] Updated Google Play Store listing with website
- [ ] Verified file is accessible via browser
- [ ] Waited 24-48 hours for verification
- [ ] Checked AdMob console for verification status

**Once verified, you'll be compliant with AdMob requirements and ready for full ad serving!** 