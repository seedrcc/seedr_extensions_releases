# Roku Pay Integration - Complete Setup Guide

This guide will walk you through setting up Roku Pay (Channel Store) for your Seedr subscription app on Roku.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Roku Developer Dashboard Setup](#roku-developer-dashboard-setup)
3. [Creating Products](#creating-products)
4. [Testing with Test Users](#testing-with-test-users)
5. [Updating Product IDs in Code](#updating-product-ids-in-code)
6. [Testing the Integration](#testing-the-integration)
7. [Publishing & Going Live](#publishing--going-live)
8. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites

Before starting, ensure you have:

✅ **Roku Developer Account** - Sign up at https://developer.roku.com
✅ **Roku Device** (for testing) - Or use the Roku Simulator
✅ **Your App Published** - At least in development mode
✅ **Payment Processor Account** - Roku uses their payment system

---

## 2. Roku Developer Dashboard Setup

### Step 2.1: Access Developer Dashboard

1. Go to https://developer.roku.com
2. Log in to your account
3. Navigate to **"Developer Dashboard"**

### Step 2.2: Create or Select Your Channel

1. Click **"Manage My Channels"**
2. Either:
   - Select your existing Seedr channel, OR
   - Click **"Add Channel"** to create a new one

### Step 2.3: Enable In-Channel Products

1. In your channel settings, find **"In-Channel Products"** or **"Monetization"**
2. Click **"Enable In-Channel Products"**
3. Accept Roku's Terms of Service for monetization

---

## 3. Creating Products

You need to create products for each subscription plan and billing cycle.

### Step 3.1: Access Product Management

1. In your channel dashboard, click **"In-Channel Products"**
2. Click **"Add a Product"**

### Step 3.2: Create Each Product

Create **16 products** total (8 plans × 2 billing cycles):

#### **Basic Plan - Monthly**

- **Product Name**: `Seedr Basic Monthly`
- **Product Identifier**: `seedr_basic_monthly` ⚠️ IMPORTANT: Use exactly this ID
- **Product Type**: `Monthly Subscription`
- **Price Tier**: `$6.99` (choose appropriate tier)
- **Description**: `50GB storage, 2 task slots, HD streaming`
- **Trial Period**: `7 days` (optional)

#### **Basic Plan - Yearly**

- **Product Name**: `Seedr Basic Yearly`
- **Product Identifier**: `seedr_basic_yearly`
- **Product Type**: `Yearly Subscription`
- **Price Tier**: `$69.00`
- **Description**: `50GB storage, 2 task slots, HD streaming - Save $13.90/year`
- **Trial Period**: `7 days` (optional)

#### **Pro Plan - Monthly**

- **Product Name**: `Seedr Pro Monthly`
- **Product Identifier**: `seedr_pro_monthly`
- **Product Type**: `Monthly Subscription`
- **Price Tier**: `$11.99`
- **Description**: `150GB storage, 8 task slots, Full-HD streaming, Private trackers`

#### **Pro Plan - Yearly**

- **Product Name**: `Seedr Pro Yearly`
- **Product Identifier**: `seedr_pro_yearly`
- **Product Type**: `Yearly Subscription`
- **Price Tier**: `$99.00`
- **Description**: `150GB storage, 8 task slots, Full-HD streaming - Save $19.90/year`

#### **Master Plan - Monthly**

- **Product Name**: `Seedr Master Monthly`
- **Product Identifier**: `seedr_master_monthly`
- **Product Type**: `Monthly Subscription`
- **Price Tier**: `$18.99`
- **Description**: `1TB storage, 25 task slots, 4K streaming, WebDAV mount`

#### **Master Plan - Yearly**

- **Product Name**: `Seedr Master Yearly`
- **Product Identifier**: `seedr_master_yearly`
- **Product Type**: `Yearly Subscription`
- **Price Tier**: `$199.00`
- **Description**: `1TB storage, 25 task slots, 4K streaming - Save $39.90/year`

#### **Gold Plans (Repeat for Gold 1, 2, 3, 4)**

Follow the same pattern for:

- `seedr_gold1_monthly` / `seedr_gold1_yearly`
- `seedr_gold2_monthly` / `seedr_gold2_yearly`
- `seedr_gold3_monthly` / `seedr_gold3_yearly`
- `seedr_gold4_monthly` / `seedr_gold4_yearly`

### Step 3.3: Set Up Product Images

For each product, upload:

- **Product Icon**: 290×218 pixels (PNG)
- **HD Promo Image**: 1920×1080 pixels (optional, for promotions)

---

## 4. Testing with Test Users

### Step 4.1: Enable Test Mode

1. In Developer Dashboard, go to **"In-Channel Products"**
2. Find **"Test Users"** section
3. Add test user email addresses
4. Enable **"Test Mode"** for your channel

### Step 4.2: Test Purchases

Test users can:

- ✅ Make purchases without being charged
- ✅ Test subscription flows
- ✅ Test cancellation flows
- ✅ See how purchases appear in the app

**Important**: Test purchases don't actually charge money!

---

## 5. Updating Product IDs in Code

### Step 5.1: Update PlanConfig.brs

Open `components/PlanConfig.brs` and update product IDs:

```brightscript
' Basic Plan
basic: {
    name: "Basic"
    monthlyPlanId: "seedr_basic_monthly"    ' ← Your actual Roku product ID
    yearlyPlanId: "seedr_basic_yearly"      ' ← Your actual Roku product ID
    ' ... rest of config
}
```

### Step 5.2: Verify All Product IDs Match

Ensure **EXACT MATCH** between:

- Product IDs in Roku Developer Dashboard
- Product IDs in `PlanConfig.brs`

**Common Mistake**: Typos or case sensitivity issues!

---

## 6. Testing the Integration

### Step 6.1: Side-load Your App

1. Enable Developer Mode on your Roku device:
   - Press **Home** 3×, **Up** 2×, **Right**, **Left**, **Right**, **Left**, **Right**
2. Note the IP address shown
3. In browser, go to `http://[ROKU_IP]`
4. Upload your channel package (.zip)

### Step 6.2: Test Purchase Flow

1. Launch your app
2. Navigate to subscription screen
3. Select a plan
4. Click **"Buy Now"**
5. Roku overlay should appear:
   - Shows product name & price
   - Shows payment method
   - Confirm or Cancel buttons

### Step 6.3: Verify Purchase Success

After purchase:

- ✅ Success dialog should appear
- ✅ Plan card should update to "Active"
- ✅ User should have access to premium features

### Step 6.4: Check Logs

Monitor logs in development console:

```
[RokuPay] Requesting product catalog...
[RokuPay] Catalog contains 16 products
[RokuPay] Initiating purchase for: Pro
[RokuPay] Purchase completed successfully
```

---

## 7. Publishing & Going Live

### Step 7.1: Submit for Certification

1. Complete all Roku certification requirements:

   - Privacy Policy URL
   - Support Contact
   - Content Rating
   - Screenshots & descriptions

2. Submit channel for review

### Step 7.2: After Approval

1. **Publish** your channel to Roku Channel Store
2. **Disable Test Mode** in In-Channel Products
3. **Real purchases** will now be charged

### Step 7.3: Monitor Sales

Track revenue in:

- **Developer Dashboard** → **Analytics**
- **Monthly Payment Reports**

---

## 8. Troubleshooting

### Issue: "Product not found" error

**Solution**:

- Verify product ID matches exactly (case-sensitive)
- Ensure products are published in Developer Dashboard
- Wait 10-15 minutes after creating products for Roku to sync

### Issue: Purchase overlay doesn't appear

**Solution**:

- Check if `roChannelStore` is initialized
- Verify app is packaged correctly
- Check device internet connection
- Review logs for errors

### Issue: Products show $0.00 price

**Solution**:

- Ensure price tiers are set in Dashboard
- Products might still be in draft mode
- Republish products and wait for sync

### Issue: "Already owned" error

**Solution**:

- User already owns an active subscription
- Check `GetPurchases()` to validate
- Implement logic to handle subscription upgrades/downgrades

### Issue: Test purchases not working

**Solution**:

- Verify test user email is added in Dashboard
- Ensure channel is in Test Mode
- Sign out and sign back in on Roku device
- Clear channel cache: Settings → System → Advanced → Factory Reset (careful!)

---

## 📞 Support & Resources

### Official Roku Documentation

- [Roku Pay Developer Guide](https://developer.roku.com/docs/developer-program/roku-pay/roku-pay.md)
- [roChannelStore API](https://developer.roku.com/docs/references/brightscript/components/rochannelstore.md)
- [In-Channel Products FAQ](https://developer.roku.com/docs/developer-program/roku-pay/in-channel-products-faq.md)

### Roku Developer Forums

- https://community.roku.com/

### Contact Roku Support

- Developer Support: developer@roku.com
- Partner Success Team (for published channels)

---

## ✅ Quick Checklist

Before going live, verify:

- [ ] All 16 products created in Developer Dashboard
- [ ] Product IDs match exactly in code
- [ ] Test purchases work correctly
- [ ] Success/error dialogs display properly
- [ ] Purchase state persists across app restarts
- [ ] Subscription features unlock correctly
- [ ] Privacy policy published
- [ ] Support contact provided
- [ ] Channel submitted for certification
- [ ] Payment information set up in Roku account

---

## 🎯 Next Steps

1. **Create products** in Roku Developer Dashboard (Step 3)
2. **Copy product IDs** to `PlanConfig.brs` (Step 5)
3. **Test with test users** (Step 4)
4. **Submit for certification** when ready (Step 7)

---

**Good luck with your Roku Pay integration! 🚀**

If you encounter issues not covered here, check the Roku forums or contact their developer support team.













