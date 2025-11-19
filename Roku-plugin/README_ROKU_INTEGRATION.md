# Seedr Roku App - Subscription Integration

## 🎯 Quick Start

This Roku app has been integrated with Roku Pay for subscription management. Follow these steps to get started:

### 1️⃣ Setup Roku Pay

Read the complete guide: **`ROKU_PAY_SETUP_GUIDE.md`**

### 2️⃣ Update Configuration

Edit **`components/PlanConfig.brs`** and replace product IDs with your actual Roku product codes.

### 3️⃣ Add Images

Place plan icon images in the `/images/` folder:

- `plan_basic_logo_SVG.png`
- `plan_pro_logo_SVG.png`
- `plan_master_logo_SVG.png`
- `plan_gold_logo_SVG.png`

### 4️⃣ Test

Side-load to Roku device and test purchase flows.

---

## 📁 Project Structure

```
/components
├── SubscriptionScreen.xml       # Main subscription screen UI
├── SubscriptionScreen.brs       # Subscription screen logic
├── PlanCard.xml                 # Individual plan card UI
├── PlanCard.brs                 # Plan card logic
├── PlanConfig.brs               # ⚠️ UPDATE PRODUCT IDs HERE
└── RokuPayHandler.brs           # Roku Pay integration

/images
├── plan_basic_logo_SVG.png      # Basic plan icon
├── plan_pro_logo_SVG.png        # Pro plan icon
├── plan_master_logo_SVG.png     # Master plan icon
└── plan_gold_logo_SVG.png       # Gold plan icon

/docs
├── ROKU_PAY_SETUP_GUIDE.md      # Complete setup instructions
├── IMPLEMENTATION_SUMMARY.md    # Technical overview
└── README_ROKU_INTEGRATION.md   # This file
```

---

## 🎮 User Experience

### Subscription Screen Features

- **Horizontal scrolling** plan cards
- **Monthly/Yearly toggle** for pricing
- **Focus indicators** for TV navigation
- **"Most Popular" badge** on Pro plan
- **Color-coded cards** per plan type
- **Purchase confirmation** dialogs
- **Roku Pay integration** for secure payments

### Supported Plans

1. **Basic** - $6.95/month or $69/year
2. **Pro** - $9.95/month or $99/year (Most Popular)
3. **Master** - $19.95/month or $199/year
4. **Gold 1-4** - Premium tiers up to $139/month

---

## 🔑 Key Files to Configure

### 1. Product IDs (REQUIRED)

**File**: `components/PlanConfig.brs`

```brightscript
' REPLACE THESE WITH YOUR ROKU PRODUCT CODES
monthlyPlanId: "seedr_basic_monthly"  ' ← Change
yearlyPlanId: "seedr_basic_yearly"    ' ← Change
```

### 2. Manifest File

**File**: `manifest`

Ensure you have:

```
requires_channel_store_access=1
```

### 3. Images

Add PNG images (100×100px recommended) to `/images/` folder.

---

## 🧪 Testing

### Local Testing

1. Enable Developer Mode on Roku device
2. Side-load your app
3. Navigate to subscription screen
4. Test purchase flow

### Test Mode

- Add test users in Roku Developer Dashboard
- Test purchases won't charge real money
- Verify purchase confirmation and entitlements

---

## 📖 Documentation

- **Setup Guide**: `ROKU_PAY_SETUP_GUIDE.md` - Step-by-step Roku Pay setup
- **Implementation**: `IMPLEMENTATION_SUMMARY.md` - Technical details
- **Roku Docs**: https://developer.roku.com/docs/developer-program/roku-pay/

---

## ⚡ Quick Commands

### Side-load to Roku

1. Enable Developer Mode: Press **Home 3×, Up 2×, Right, Left, Right, Left, Right**
2. Note IP address
3. Visit `http://[ROKU_IP]` in browser
4. Upload ZIP file

### Package for Production

```bash
# Create package
zip -r seedr-roku.zip . -x "*.git*" -x "*node_modules*"

# Upload to Developer Dashboard
# Submit for certification
```

---

## 🐛 Troubleshooting

### Cards don't show

- Check component files are in `/components/` folder
- Verify manifest includes component declarations
- Check console logs

### Purchase fails

- Verify product IDs match Dashboard exactly
- Ensure internet connection
- Check if products are published in Dashboard

### Prices incorrect

- Check pricing in `PlanConfig.brs`
- Verify annual/monthly toggle logic
- Review Roku product pricing in Dashboard

---

## 📞 Support

- **Roku Forums**: https://community.roku.com/
- **Developer Support**: developer@roku.com
- **Documentation**: https://developer.roku.com/

---

## ✅ Launch Checklist

Before publishing:

- [ ] All product IDs updated in `PlanConfig.brs`
- [ ] All 16 products created in Roku Dashboard
- [ ] Plan icon images added
- [ ] Test purchases successful
- [ ] Purchase confirmation works
- [ ] Entitlements verified
- [ ] Privacy policy URL set
- [ ] Support contact provided
- [ ] Channel submitted for certification

---

**Ready to integrate! Follow the guides and you'll be live soon. 🚀**

For detailed setup instructions, see **`ROKU_PAY_SETUP_GUIDE.md`**













