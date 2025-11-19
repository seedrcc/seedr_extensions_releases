# Roku Pay Quick Reference

## 🎯 Product Codes to Configure

Configure these exact product codes in Roku Developer Portal:

```
seedr_premium_monthly   → $3.99/month (7-day trial)
seedr_premium_yearly    → $39.99/year (Save 17%)
seedr_pro_monthly       → $7.99/month (Optional)
seedr_pro_yearly        → $79.99/year (Optional)
```

## 🚀 How to Test

1. **Enable Test Mode** in Roku Developer Portal
2. **Side-load** your app to Roku device
3. **Trigger subscription screen**:
   ```brightscript
   m.top.getScene().showSubscriptionScreen = true
   ```
4. **Complete test purchase**
5. **Verify** premium features unlock

## 📝 Key Functions

### Check if user is premium:

```brightscript
if isPremiumUser() then
    ' User has active subscription
end if
```

### Check specific feature access:

```brightscript
if canAccessFeature("hd_streaming") then
    ' User can access HD streaming
end if
```

### Get user's tier:

```brightscript
tier = getTierDisplayName()  ' Returns: "Free", "Premium", or "Pro"
```

### Get storage limit:

```brightscript
storageGB = getStorageLimitGB()  ' Returns: 5, 50, or 200
```

### Show upgrade prompt:

```brightscript
if shouldShowUpgradePrompt("hd_streaming") then
    showDialog("Upgrade to Premium", getUpgradeCTAText("hd_streaming"))
end if
```

## 🔧 Where to Add "Upgrade" Button

### Option 1: In SeedrHomeScene

**File**: `components/SeedrHomeScene.brs`

```brightscript
' Add to your menu or button press handler:
sub onUpgradePressed()
    m.top.getScene().showSubscriptionScreen = true
end sub
```

### Option 2: Feature Gate Example

```brightscript
sub onHDVideoSelected()
    if not canAccessFeature("hd_streaming") then
        ' Show upgrade screen
        m.top.getScene().showSubscriptionScreen = true
        return  ' Don't play video
    end if

    ' Play HD video...
end sub
```

### Option 3: Settings Menu

```brightscript
if selectedOption = "Manage Subscription" then
    m.top.getScene().showSubscriptionScreen = true
end if
```

## 📊 Subscription Status Fields

Access via `m.global.subscriptionStatus`:

```brightscript
{
    tier: "premium"              ' "free", "premium", or "pro"
    isActive: true               ' Is subscription active?
    isPremium: true              ' Has any premium subscription?
    expiryDate: "2025-11-08"     ' When subscription expires
    productId: "seedr_premium_monthly"
    purchaseDate: "2025-10-08"
    isTrial: true                ' Currently in trial?
    trialEndDate: "2025-10-15"
    autoRenew: true              ' Will auto-renew?
    renewalDate: "2025-11-08"
}
```

## 🎨 Tier Benefits

| Feature | Free      | Premium | Pro      |
| ------- | --------- | ------- | -------- |
| Storage | 5GB       | 50GB    | 200GB    |
| Quality | SD        | HD      | 4K       |
| Devices | 1         | 3       | 5        |
| Ads     | Yes       | No      | No       |
| Support | Community | Email   | Priority |

## 🔍 Debug Commands

Check subscription status in logs:

```brightscript
logSubscriptionStatus()
```

Outputs:

```
[Entitlements] === Subscription Status ===
  Tier: premium
  Active: true
  Premium: true
  Product ID: seedr_premium_monthly
  Trial: false
  Auto-Renew: true
  Storage Limit: 50 GB
  Device Limit: 3
  Max Quality: HD
  Show Ads: false
[Entitlements] ==========================
```

## 📦 Files Created

### Components

- `components/PurchaseHandler.xml` - Roku Pay integration
- `components/PurchaseHandler.brs` - Purchase logic
- `components/SubscriptionScreen.xml` - UI for plans
- `components/SubscriptionScreen.brs` - Screen logic

### Source

- `source/entitlements.brs` - Subscription utilities

### Documentation

- `docs/ROKU_PAY_SETUP_GUIDE.md` - Complete setup guide
- `docs/ROKU_PAY_INTEGRATION_PLAN.md` - Full integration plan
- `docs/ROKU_PAY_QUICK_REFERENCE.md` - This file

### Modified

- `components/HeroMainScene.xml` - Added components
- `components/HeroMainScene.brs` - Added handlers
- `manifest` - Updated version, added IAP support

## ⚡ Common Tasks

### Show subscription screen:

```brightscript
m.top.getScene().showSubscriptionScreen = true
```

### Check if premium:

```brightscript
isPremiumUser()  ' Returns boolean
```

### Get tier name:

```brightscript
getTierDisplayName()  ' Returns "Free", "Premium", or "Pro"
```

### Feature gating:

```brightscript
if not canAccessFeature("hd_streaming") then
    showUpgradePrompt()
    return
end if
```

### Log status:

```brightscript
logSubscriptionStatus()
```

## 🐛 Troubleshooting

**Products not loading?**

- Check Developer Portal → Monetization → Enable In-Channel Purchasing
- Verify products are created with correct codes
- Enable Test Mode for development

**Purchase fails?**

- Test Mode must be ON for test purchases
- Check internet connection
- Verify Roku account has payment method (live only)

**Premium features don't unlock?**

- Check logs for `[PurchaseHandler] ✓ Purchases loaded successfully`
- Verify product codes match exactly
- Restart app to refresh status

## 📞 Need Help?

1. Check full guide: [ROKU_PAY_SETUP_GUIDE.md](./ROKU_PAY_SETUP_GUIDE.md)
2. Read integration plan: [ROKU_PAY_INTEGRATION_PLAN.md](./ROKU_PAY_INTEGRATION_PLAN.md)
3. Roku Forums: https://community.roku.com
4. Email: developer@roku.com

---

**Ready to launch!** 🚀 Just configure products in Roku Developer Portal and you're good to go!
