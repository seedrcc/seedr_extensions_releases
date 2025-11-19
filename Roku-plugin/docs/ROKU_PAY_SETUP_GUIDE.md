# Roku Pay Setup Guide for Seedr

## 🎯 Quick Start

This guide will help you set up Roku Pay (in-channel purchasing) for your Seedr Roku app. The integration code is already complete - you just need to configure products in the Roku Developer Portal.

---

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ Roku Developer Account ([developer.roku.com](https://developer.roku.com))
- ✅ Your Seedr channel published or in development
- ✅ Tax information submitted to Roku (required for monetization)
- ✅ Banking information for payouts

---

## 🔧 Step 1: Enable In-Channel Purchasing

### 1.1 Access Developer Portal

1. Log in to [developer.roku.com](https://developer.roku.com)
2. Navigate to **Manage Channels**
3. Select your **Seedr for Roku** channel
4. Click **Monetization** in the left sidebar

### 1.2 Enable Roku Pay

1. Toggle **"Enable In-Channel Purchasing"** to ON
2. Read and accept the Roku Pay terms and conditions
3. Click **Save**

---

## 💰 Step 2: Create Product Catalog

### 2.1 Recommended Products

Configure these products in your Roku Developer Portal:

#### Product 1: Premium Monthly

```
Product Code: seedr_premium_monthly
Product Name: Seedr Premium Monthly
Product Type: Monthly Subscription
Price: $3.99 USD
Description: 50GB storage, HD streaming, no ads, 3 devices
Free Trial: 7 days (optional but recommended)
```

#### Product 2: Premium Yearly

```
Product Code: seedr_premium_yearly
Product Name: Seedr Premium Yearly
Product Type: Yearly Subscription
Price: $39.99 USD (17% savings vs monthly)
Description: 50GB storage, HD streaming, no ads, 3 devices - Best value!
Free Trial: 7 days (optional but recommended)
```

#### Product 3: Pro Monthly (Optional)

```
Product Code: seedr_pro_monthly
Product Name: Seedr Pro Monthly
Product Type: Monthly Subscription
Price: $7.99 USD
Description: 200GB storage, 4K streaming, no ads, 5 devices, priority support
Free Trial: 7 days (optional)
```

#### Product 4: Pro Yearly (Optional)

```
Product Code: seedr_pro_yearly
Product Name: Seedr Pro Yearly
Product Type: Yearly Subscription
Price: $79.99 USD
Description: 200GB storage, 4K streaming, no ads, 5 devices - Ultimate plan
Free Trial: 7 days (optional)
```

### 2.2 Create Products in Portal

For each product:

1. In **Monetization** → **Products**, click **Add Product**
2. Fill in the form:
   - **Product Code**: Enter the code exactly as shown above (e.g., `seedr_premium_monthly`)
   - **Product Name**: User-friendly name that appears in purchase dialog
   - **Product Type**: Select "Subscription"
   - **Subscription Duration**: Select "Monthly" or "Yearly"
   - **Price**: Enter the price in USD
   - **Description**: Add the product description
3. **Optional**: Configure free trial
   - Check "Enable Free Trial"
   - Trial Duration: 7 days
   - Trial Type: Time-based
4. Click **Save**

**⚠️ IMPORTANT**: Product codes must match exactly what's in the code, or purchases won't work!

### 2.3 Set Up Test Products

For development and testing:

1. Go to **Monetization** → **Testing**
2. Click **Create Test Products**
3. Roku will create test versions of your products with special test pricing ($0.00)
4. Use these during development to test the purchase flow without real money

---

## 🧪 Step 3: Testing Setup

### 3.1 Enable Test Mode

1. In **Monetization** → **Settings**
2. Enable **"Test Mode"**
3. This allows you to test purchases without real transactions

### 3.2 Test on Device

1. Side-load your channel to a Roku device
2. Navigate to the subscription screen in the app
3. Select a plan and initiate purchase
4. Roku will show a test purchase dialog
5. Complete the test purchase
6. Verify that premium features unlock

### 3.3 Test Scenarios to Verify

- ✅ Successful purchase
- ✅ Cancelled purchase
- ✅ Purchase failure handling
- ✅ Premium features unlock after purchase
- ✅ Subscription status persists across app restarts
- ✅ Multiple purchases (upgrade/downgrade)
- ✅ Expiration handling

---

## 🚀 Step 4: Going Live

### 4.1 Pre-Launch Checklist

- [ ] All products created with correct codes
- [ ] Product descriptions are accurate and compelling
- [ ] Free trial configured (if offering)
- [ ] Test mode disabled
- [ ] Tax and banking information verified
- [ ] Privacy policy updated to mention subscriptions
- [ ] Terms of service updated for billing
- [ ] Support email/contact set up for billing questions

### 4.2 Enable Live Purchases

1. Disable **Test Mode** in Developer Portal
2. Set channel to **Published** or **Beta** status
3. Submit channel for certification (if not already published)
4. Wait for Roku approval (typically 3-7 business days)

### 4.3 Monitor Launch

After going live:

1. Check **Analytics** in Developer Portal
2. Monitor conversion rates
3. Watch for support inquiries
4. Track revenue in **Reports** section

---

## 📊 Step 5: Product Configuration Best Practices

### 5.1 Pricing Strategy

**Recommended Approach:**

- **Free Tier**: Always available, limited features (5GB storage, SD quality, ads)
- **Premium Tier**: Most popular, good value ($3.99/mo or $39.99/yr)
- **Pro Tier** (Optional): For power users ($7.99/mo or $79.99/yr)

**Psychological Pricing:**

- Use `.99` endings ($3.99 vs $4.00)
- Show annual savings prominently ("Save 17%!")
- Offer 7-day free trial to reduce friction

### 5.2 Product Descriptions

Write clear, benefit-focused descriptions:

❌ **Bad**: "Premium subscription with more storage"

✅ **Good**: "Get 50GB of cloud storage, HD streaming, ad-free experience, and use on up to 3 devices"

### 5.3 Free Trial Strategy

**Benefits of offering trials:**

- Lower barrier to entry
- Users experience premium features
- Higher conversion rates after trial
- Industry standard practice

**Recommended:**

- 7 days for monthly plans
- Consider no trial for yearly (already discounted)

---

## 🔗 Step 6: Update Code (If Needed)

The integration is already complete, but if you need to modify product IDs:

### 6.1 Update Product IDs

If you use different product codes, update these files:

**File**: `components/PurchaseHandler.brs`

```brightscript
' Around line 158 - update this list:
productIdsToCheck = [
    "seedr_premium_yearly"    ' Change to your product code
    "seedr_premium_monthly"   ' Change to your product code
    "seedr_pro_yearly"        ' Change to your product code
    "seedr_pro_monthly"       ' Change to your product code
]
```

**File**: `components/SubscriptionScreen.brs`

```brightscript
' Around line 68 - update planConfigs:
{
    id: "seedr_premium_monthly"  ' Change to match your product code
    title: "Premium"
    price: "$3.99"
    // ... rest of config
}
```

**File**: `source/entitlements.brs`

```brightscript
' Around line 109 - update this list:
premiumProducts = [
    "seedr_premium_monthly"   ' Change to your product code
    "seedr_premium_yearly"    ' Change to your product code
    "seedr_pro_monthly"       ' Change to your product code
    "seedr_pro_yearly"        ' Change to your product code
]
```

---

## 🎨 Step 7: Customize UI (Optional)

### 7.1 Update Colors

**File**: `components/SubscriptionScreen.xml`

Change the accent color from Seedr green:

```xml
<!-- Current: Seedr green -->
<Rectangle color="0x1DB954FF" />

<!-- Change to your brand color -->
<Rectangle color="0xYOURCOLORFF" />
```

### 7.2 Update Product Benefits

**File**: `components/SubscriptionScreen.brs`

Modify the `features` array in `planConfigs`:

```brightscript
features: [
    "50GB Storage"          ' Update storage amount
    "Fast Speed"            ' Change feature description
    "No Ads"                ' Add/remove features
    "3 Devices"             ' Update device count
    "Email Support"         ' Change support level
]
```

---

## 📱 Step 8: Add Subscription Button to Your App

To trigger the subscription screen from your app:

### 8.1 From SeedrHomeScene

Add an "Upgrade" button or menu item:

**File**: `components/SeedrHomeScene.brs`

```brightscript
' When user clicks upgrade button:
sub onUpgradeButtonPressed()
    ' Show subscription screen
    m.top.getScene().showSubscriptionScreen = true
end sub
```

### 8.2 From Settings Menu

```brightscript
' In your settings/menu component:
if menuItem = "Manage Subscription" then
    m.top.getScene().showSubscriptionScreen = true
end if
```

### 8.3 Add Upgrade Prompts

Show upgrade prompts when users try premium features:

```brightscript
' Check if feature requires premium
if not isPremiumUser() and featureRequiresPremium then
    ' Show upgrade prompt
    showUpgradeDialog("This feature requires Premium")
    m.top.getScene().showSubscriptionScreen = true
    return
end if
```

---

## 🔍 Step 9: Verification

### 9.1 Check Integration

Run these checks to verify everything works:

1. **Products Load**:

   - Launch app
   - Check logs for: `[PurchaseHandler] ✓ Catalog loaded successfully`

2. **Subscription Screen Shows**:

   - Navigate to subscription screen
   - Verify all plans display correctly
   - Check pricing and descriptions

3. **Purchase Flow**:

   - Select a plan
   - Roku Pay dialog appears
   - Complete test purchase
   - Check for: `[HeroMainScene] ✓✓✓ Purchase successful! ✓✓✓`

4. **Entitlements Work**:
   - After purchase, check logs for subscription status
   - Verify premium features unlock
   - Restart app and confirm subscription persists

### 9.2 Common Issues

**Issue**: Products don't load

```
[PurchaseHandler] Processing 0 catalog items...
```

**Solution**:

- Verify In-Channel Purchasing is enabled in Developer Portal
- Check that products are created and active
- Ensure channel is in development/published state

---

**Issue**: Purchase fails with error

```
[HeroMainScene] ✗ Purchase failed: Purchase failed. Please try again.
```

**Solution**:

- Check that Test Mode is enabled (for development)
- Verify device has internet connection
- Ensure Roku account has payment method (for live purchases)
- Check product codes match exactly

---

**Issue**: Premium features don't unlock

```
[Entitlements] No active subscriptions - user is on free tier
```

**Solution**:

- Check that purchase completed successfully
- Verify `onPurchasesReady()` is called after purchase
- Check product ID matching in `updateSubscriptionStatus()`

---

## 💡 Step 10: Next Steps

### 10.1 Analytics

Monitor these metrics:

- **Free to Paid Conversion**: Target > 2%
- **Trial to Paid**: Target > 40%
- **Monthly Churn**: Target < 5%
- **MRR Growth**: Track monthly

### 10.2 Optimization

After launch:

1. **A/B Test Pricing**: Try different price points
2. **Test Trial Duration**: 7 days vs 14 days vs 30 days
3. **Optimize Upgrade Prompts**: When and where to show them
4. **Add Premium Features**: Continuously improve value proposition

### 10.3 Marketing

Promote your subscriptions:

- **In-App**: Banners, badges on premium content
- **Email**: Announce to existing users
- **Social Media**: Share benefits of premium
- **App Store**: Update description with subscription info

---

## 📞 Support Resources

### Official Roku Documentation

- [Roku Pay Overview](https://developer.roku.com/docs/developer-program/roku-pay/how-roku-pay-works.md)
- [ChannelStore API Reference](https://developer.roku.com/docs/references/scenegraph/control-nodes/channelstore.md)
- [Billing Best Practices](https://developer.roku.com/docs/developer-program/roku-pay/implementation/best-practices.md)

### Community

- [Roku Developer Forums](https://community.roku.com)
- Email: developer@roku.com

---

## ✅ Final Checklist

Before launching subscriptions:

- [ ] Products created in Roku Developer Portal
- [ ] Product codes match between portal and code
- [ ] Test purchases work correctly
- [ ] Premium features unlock properly
- [ ] Subscription persists across app restarts
- [ ] Test mode disabled for live launch
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Support contact information added
- [ ] Analytics tracking verified
- [ ] Channel submitted for certification
- [ ] Tax and banking information verified

---

## 🎉 You're Ready!

Your Roku Pay integration is complete! The code handles:

✅ Product catalog loading
✅ Purchase management  
✅ Subscription checking
✅ Entitlement verification
✅ Beautiful subscription screen UI
✅ Error handling
✅ Multiple subscription tiers

All you need to do is configure products in the Roku Developer Portal and start earning revenue!

---

**Questions?** Check the main integration plan: [ROKU_PAY_INTEGRATION_PLAN.md](./ROKU_PAY_INTEGRATION_PLAN.md)

**Good luck with your launch! 🚀**
