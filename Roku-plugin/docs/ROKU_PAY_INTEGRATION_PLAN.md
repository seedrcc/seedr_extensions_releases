# Roku Pay Integration Plan for Seedr

## 📋 Table of Contents

1. [Overview](#overview)
2. [Phase 1: Roku Developer Portal Setup](#phase-1-roku-developer-portal-setup)
3. [Phase 2: Architecture Design](#phase-2-architecture-design)
4. [Phase 3: Integration Flow](#phase-3-integration-flow)
5. [Phase 4: Technical Implementation](#phase-4-technical-implementation-details)
6. [Phase 5: Testing Strategy](#phase-5-testing-strategy)
7. [Phase 6: Implementation Checklist](#phase-6-implementation-checklist)
8. [Phase 7: Deployment Strategy](#phase-7-deployment-strategy)
9. [Phase 8: Analytics & Monitoring](#phase-8-analytics--monitoring)
10. [Phase 9: Security Considerations](#phase-9-security-considerations)
11. [Phase 10: Pricing Strategy](#phase-10-pricing-strategy)
12. [Resources & Next Steps](#resources--next-steps)

---

## 🎯 Overview

### What is Roku Pay?

Roku Pay allows you to:

- Sell **subscriptions** (monthly/yearly plans)
- Sell **one-time purchases** (premium features, content packs)
- Handle **free trials**
- Manage **billing** through Roku's infrastructure
- Roku handles all payment processing and takes a 20% commission

---

## 📊 Phase 1: Roku Developer Portal Setup

### Step 1.1: Product Catalog Configuration

**Location:** Roku Developer Dashboard → Your Channel → Monetization

#### Actions Needed:

1. **Enable In-Channel Purchasing**

   - Navigate to channel settings
   - Enable "In-Channel Products"
   - Agree to Roku Pay terms

2. **Create Product Catalog**

   Define your pricing tiers. Example products for Seedr:

   | Product ID              | Name            | Type         | Price       | Description                |
   | ----------------------- | --------------- | ------------ | ----------- | -------------------------- |
   | `seedr_premium_monthly` | Premium Monthly | Subscription | $3.99/month | 50GB storage, no ads       |
   | `seedr_premium_yearly`  | Premium Yearly  | Subscription | $39.99/year | Save 17% annually          |
   | `seedr_pro_monthly`     | Pro Monthly     | Subscription | $7.99/month | 200GB storage, priority    |
   | `seedr_pro_yearly`      | Pro Yearly      | Subscription | $79.99/year | Best value for power users |

3. **Configure Each Product:**
   - Product ID (unique identifier)
   - Product Name (user-facing)
   - Description (shown in Roku UI)
   - Price (in USD)
   - Product Type (subscription vs one-time)
   - Trial period (optional, e.g., 7 days free)
   - Subscription duration (monthly/yearly)

---

## 🏗️ Phase 2: Architecture Design

### New Files to Create

```
project_root/
├── components/
│   ├── PurchaseHandler.xml       ← Handles Roku Pay API calls
│   ├── PurchaseHandler.brs       ← Purchase logic
│   ├── SubscriptionScreen.xml    ← UI for subscription options
│   ├── SubscriptionScreen.brs    ← Subscription screen logic
│   ├── PurchaseDialog.xml        ← Confirmation dialog
│   └── PurchaseDialog.brs        ← Dialog logic
├── source/
│   ├── purchases.brs             ← Purchase utility functions
│   └── entitlements.brs          ← Check user access levels
└── docs/
    └── ROKU_PAY_INTEGRATION.md   ← This document
```

### Files to Modify

```
Existing Files to Update:
├── components/
│   ├── HeroMainScene.brs         ← Add purchase flow routing
│   ├── HeroMainScene.xml         ← Add subscription screen node
│   ├── SeedrHomeScene.brs        ← Add "Upgrade" UI elements
│   ├── SeedrHomeScene.xml        ← Add upgrade button
│   ├── AuthScreen.brs            ← Add subscription CTA
│   ├── AuthScreen.xml            ← Update UI for CTA
│   └── DeviceAuthScreen.brs      ← Optional: subscription after auth
├── source/
│   ├── api.brs                   ← Add subscription status API calls
│   └── main.brs                  ← Initialize global subscription state
└── manifest                      ← Update version, add permissions
```

---

## 🔄 Phase 3: Integration Flow

### User Journey Flowchart

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER OPENS CHANNEL                          │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│         Check Entitlements (on startup)                         │
│  • Query Roku Pay for active subscriptions                      │
│  • Store subscription status in m.global                        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                 USER SEES CONTENT                               │
│  • Free users: Limited content + Upgrade prompts                │
│  • Premium users: Full access                                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│         USER CLICKS "UPGRADE" BUTTON                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│              SHOW SUBSCRIPTION SCREEN                           │
│  • Display available plans                                      │
│  • Highlight benefits comparison                                │
│  • Show pricing (monthly vs yearly)                             │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│              USER SELECTS PLAN                                  │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│           LAUNCH ROKU PAY DIALOG                                │
│  • Roku handles payment UI automatically                        │
│  • User enters payment info (if first time)                     │
│  • User confirms purchase                                       │
└─────────────────────┬───────────────────────────────────────────┘
                      │
            ┌─────────┴─────────┐
            │                   │
            ▼                   ▼
┌───────────────────┐ ┌───────────────────┐
│     SUCCESS       │ │     FAILURE       │
└─────────┬─────────┘ └─────────┬─────────┘
          │                     │
          ▼                     ▼
┌───────────────────┐ ┌───────────────────┐
│ • Update          │ │ • Show error      │
│   entitlements    │ │ • Return to       │
│ • Unlock features │ │   subscription    │
│ • Show success    │ │   screen          │
│   message         │ │                   │
└───────────────────┘ └───────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│              ONGOING: CHECK SUBSCRIPTION STATUS                 │
│  • On app launch                                                │
│  • Periodically during session (every 10 minutes)               │
│  • Handle expiration/cancellation gracefully                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 💻 Phase 4: Technical Implementation Details

### 4.1: Roku Pay API Integration

#### Key Roku Components to Use

**1. ChannelStore Node (roChannelStore)**

```brightscript
' Create ChannelStore node
m.channelStore = CreateObject("roSGNode", "ChannelStore")
m.channelStore.observeField("catalog", "onCatalogLoaded")
m.channelStore.observeField("purchases", "onPurchasesLoaded")
m.channelStore.observeField("purchaseResult", "onPurchaseComplete")
```

**Methods:**

- `GetCatalog()` - Retrieve available products from Roku
- `GetPurchases()` - Get user's active/past purchases
- `DoOrder(productCode)` - Initiate purchase flow

**2. Product Information Structure**

```brightscript
' Each product from GetCatalog() contains:
product = {
    code: "seedr_premium_monthly",      ' Product ID
    name: "Premium Monthly",             ' Display name
    description: "50GB storage, no ads", ' Description
    price: 3.99,                         ' Price as number
    priceDisplay: "$3.99",               ' Formatted price string
    productType: "subscription",         ' Type: "subscription" or "purchase"
    freeTrialType: "time",               ' Trial type (if applicable)
    freeTrialQuantity: 7                 ' Trial duration in days
}
```

**3. Purchase Flow Implementation**

```brightscript
' Step 1: Get product catalog
sub getCatalog()
    m.channelStore.GetCatalog()
end sub

' Step 2: Handle catalog response
sub onCatalogLoaded()
    catalog = m.channelStore.catalog
    if catalog <> invalid and catalog.Count() > 0 then
        ' Display products to user
        displayProducts(catalog)
    end if
end sub

' Step 3: User selects product
sub purchaseProduct(productCode as string)
    m.channelStore.DoOrder(productCode)
end sub

' Step 4: Handle purchase result
sub onPurchaseComplete()
    result = m.channelStore.purchaseResult
    if result.success then
        ' Purchase successful - update entitlements
        updateUserEntitlements()
    else
        ' Purchase failed - show error
        showError(result.error)
    end if
end sub
```

---

### 4.2: Subscription Screen UI Design

#### Layout Plan

```
┌─────────────────────────────────────────────────────────────┐
│  [SEEDR LOGO]                            [Back Button]      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│              Choose Your Seedr Plan                         │
│              ═══════════════════                           │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐              │
│  │     FREE         │  │    PREMIUM       │              │
│  │                  │  │                  │              │
│  │  ✓ 5GB Storage   │  │  ✓ 50GB Storage  │              │
│  │  ✓ Basic Speed   │  │  ✓ Fast Speed    │              │
│  │  ✓ Ads           │  │  ✓ No Ads        │              │
│  │  ✓ 1 Device      │  │  ✓ HD Quality    │              │
│  │                  │  │  ✓ 3 Devices     │              │
│  │                  │  │                  │              │
│  │    $0/month      │  │   $3.99/month    │              │
│  │                  │  │   [7-day trial]  │              │
│  │                  │  │                  │              │
│  │   [Current]      │  │   [Upgrade]      │              │
│  └──────────────────┘  └──────────────────┘              │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              PREMIUM YEARLY                          │  │
│  │                                                      │  │
│  │  ✓ All Premium features                             │  │
│  │  ✓ Best Value - Save 17%!                          │  │
│  │                                                      │  │
│  │        $39.99/year (only $3.33/month)              │  │
│  │                                                      │  │
│  │                [Upgrade Now]                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  [Restore Purchases]          [Terms & Conditions]         │
└─────────────────────────────────────────────────────────────┘
```

#### Color Scheme

- Background: `0x121212FF` (dark)
- Cards: `0x1a1a1aFF` (slightly lighter)
- Premium highlight: `0x1DB954FF` (Seedr green)
- Text: `0xFFFFFFFF` (white)
- Muted text: `0x888888FF` (gray)
- Focus border: `0x1DB954FF` (green)

---

### 4.3: Entitlement Checking System

#### Global State Management

```brightscript
' Initialize in main.brs or MainScene.brs
sub initGlobalState()
    m.global.addFields({
        subscriptionStatus: {
            tier: "free",              ' "free" | "premium" | "pro"
            isActive: false,           ' Is subscription currently active?
            expiryDate: invalid,       ' Timestamp when expires
            productId: "",             ' e.g. "seedr_premium_monthly"
            purchaseDate: invalid,     ' When subscription started
            isTrial: false,            ' Is this a trial period?
            trialEndDate: invalid,     ' When trial ends
            autoRenew: true            ' Will it auto-renew?
        }
    })
end sub
```

#### Where to Check Entitlements

1. **On App Launch** - `MainScene.brs init()`

   ```brightscript
   sub init()
       ' ... other init code ...
       checkSubscriptionStatus()
   end sub
   ```

2. **After Purchase** - `PurchaseHandler.brs`

   ```brightscript
   sub onPurchaseComplete()
       if m.channelStore.purchaseResult.success then
           checkSubscriptionStatus()
       end if
   end sub
   ```

3. **Periodically During Session**

   ```brightscript
   ' Create timer to check every 10 minutes
   m.entitlementTimer = CreateObject("roSGNode", "Timer")
   m.entitlementTimer.duration = 600  ' 10 minutes
   m.entitlementTimer.repeat = true
   m.entitlementTimer.observeField("fire", "checkSubscriptionStatus")
   m.entitlementTimer.control = "start"
   ```

4. **Before Playing Premium Content**
   ```brightscript
   sub playVideo(fileContent as object)
       if fileContent.isPremiumOnly and not isPremiumUser() then
           showUpgradePrompt()
           return
       end if
       ' ... continue with playback ...
   end sub
   ```

---

### 4.4: Feature Gating Strategy

#### Tier Comparison Table

| Feature            | Free      | Premium | Pro      |
| ------------------ | --------- | ------- | -------- |
| Storage            | 5GB       | 50GB    | 200GB    |
| Video Quality      | SD        | HD      | HD + 4K  |
| Ads                | Yes       | No      | No       |
| Devices            | 1         | 3       | 5        |
| Priority Streaming | ❌        | ✅      | ✅       |
| Download Queue     | ❌        | ✅      | ✅       |
| API Access         | ❌        | ❌      | ✅       |
| Support            | Community | Email   | Priority |

#### Implementation Example

```brightscript
' Check if user can access feature
function canAccessFeature(featureName as string) as boolean
    userTier = m.global.subscriptionStatus.tier

    if featureName = "hd_streaming" then
        return (userTier = "premium" or userTier = "pro")
    else if featureName = "4k_streaming" then
        return (userTier = "pro")
    else if featureName = "api_access" then
        return (userTier = "pro")
    end if

    return true  ' Free features available to all
end function

' Get storage limit based on tier
function getStorageLimit() as longinteger
    userTier = m.global.subscriptionStatus.tier

    if userTier = "pro" then
        return 200 * 1024 * 1024 * 1024  ' 200GB
    else if userTier = "premium" then
        return 50 * 1024 * 1024 * 1024   ' 50GB
    else
        return 5 * 1024 * 1024 * 1024    ' 5GB
    end if
end function
```

---

## 🧪 Phase 5: Testing Strategy

### 5.1: Test Channel Setup

Roku provides **Test Products** that allow you to:

- Simulate purchases without real money
- Test all subscription states
- Verify purchase flows
- Test cancellation/refunds

#### Setting Up Test Products

1. In Roku Developer Dashboard
2. Go to your channel → Monetization
3. Enable "Test Mode"
4. Create test versions of your products
5. Use test products during development

### 5.2: Test Scenarios Checklist

#### Purchase Flow Testing

- [ ] User initiates purchase
- [ ] Roku Pay dialog appears correctly
- [ ] User confirms purchase
- [ ] Success callback received
- [ ] Entitlements updated immediately
- [ ] Premium features unlock
- [ ] User cancels purchase
- [ ] Cancel callback handled gracefully

#### Subscription State Testing

- [ ] **New Subscription (Free Trial)**
  - Trial starts immediately
  - Trial countdown displayed
  - Premium features available during trial
  - Trial expiry warning shown
- [ ] **Active Subscription**
  - All premium features accessible
  - Subscription status shows "Active"
  - Renewal date displayed correctly
- [ ] **Expired Subscription**
  - Premium features locked
  - Graceful downgrade message shown
  - "Renew" option presented
  - Free tier features still work
- [ ] **Cancelled Subscription**
  - Access until end of billing period
  - No auto-renewal
  - "Resubscribe" option available
- [ ] **Refunded Subscription**
  - Immediate access revocation
  - Appropriate message displayed

#### Edge Cases Testing

- [ ] **Network Error During Purchase**
  - App doesn't crash
  - User informed of error
  - Retry option provided
- [ ] **App Restart During Purchase**
  - Purchase completes properly
  - State restored on restart
- [ ] **Subscription Expires During Session**
  - User notified gracefully
  - Features locked after expiry
  - No data loss
- [ ] **Multiple Devices Same Account**
  - Subscription status syncs
  - No conflicts between devices
- [ ] **Upgrade/Downgrade Between Tiers**
  - Proper prorating
  - Immediate tier change
  - Billing adjusted correctly

---

## 📝 Phase 6: Implementation Checklist

### Backend Preparation

- [ ] Ensure Seedr API supports subscription tiers
- [ ] Add endpoint to validate Roku receipts
- [ ] Store subscription status in user database
- [ ] Create API to return tier-appropriate content
- [ ] Set up webhook for subscription events (optional)
- [ ] Implement rate limiting per tier
- [ ] Add analytics for subscription events

### Roku Developer Portal

- [ ] Create Roku developer account (if not exists)
- [ ] Access your channel in dashboard
- [ ] Enable In-Channel Purchasing
- [ ] Create product catalog
- [ ] Configure pricing for each tier
- [ ] Set up test products
- [ ] Add product descriptions
- [ ] Upload product images (if required)
- [ ] Configure trial periods
- [ ] Set up tax settings

### Code Implementation - New Components

- [ ] **PurchaseHandler Component**
  - Create ChannelStore node
  - Implement GetCatalog()
  - Implement GetPurchases()
  - Implement DoOrder()
  - Add observers for all callbacks
  - Error handling
- [ ] **SubscriptionScreen UI**
  - Design layout XML
  - Create product cards
  - Add benefit comparison
  - Implement focus management
  - Add purchase buttons
  - "Restore Purchases" button
- [ ] **Entitlement Functions** (`source/entitlements.brs`)
  - `checkSubscriptionStatus()`
  - `isPremiumUser()`
  - `canAccessFeature()`
  - `getStorageLimit()`
  - `shouldShowAds()`

### Code Implementation - Existing Files

- [ ] **HeroMainScene.brs/xml**
  - Add SubscriptionScreen node
  - Add observer for subscription changes
  - Add routing to subscription screen
  - Add purchase result handling
- [ ] **SeedrHomeScene.brs/xml**
  - Add "Upgrade" button to UI
  - Add premium badges on content
  - Implement feature gating
  - Show storage usage with limit
- [ ] **AuthScreen.brs/xml**
  - Add subscription CTA
  - Highlight premium benefits
  - Link to subscription screen
- [ ] **API Integration** (`source/api.brs`)
  - Add function to sync subscription to backend
  - Add function to get tier-specific content
  - Add function to validate receipts

### UI Updates

- [ ] Add "Upgrade" buttons in strategic locations
- [ ] Add "Premium" badges on premium content
- [ ] Update AuthScreen with subscription CTA
- [ ] Add subscription management in settings
- [ ] Show current plan in user profile
- [ ] Add storage usage indicator
- [ ] Display subscription renewal date
- [ ] Add "Cancel Subscription" option

### Testing Phase

- [ ] Unit test all purchase functions
- [ ] Test all subscription states
- [ ] Test feature gating logic
- [ ] Test error handling
- [ ] Test on multiple Roku devices
- [ ] Test network failure scenarios
- [ ] Verify analytics tracking
- [ ] Performance testing with purchases

### Documentation

- [ ] Update user documentation
- [ ] Create support FAQ for subscriptions
- [ ] Document cancellation process
- [ ] Add troubleshooting guide
- [ ] Update privacy policy
- [ ] Update terms of service

---

## 🚀 Phase 7: Deployment Strategy

### Rollout Plan

#### Step 1: Soft Launch (Beta) - Week 1-2

**Objectives:**

- Test with limited audience
- Identify any issues
- Gather initial feedback

**Actions:**

- Enable for beta testers only (100-500 users)
- Monitor purchase analytics closely
- Have support team ready
- Fix any critical issues immediately

**Success Metrics:**

- Zero critical bugs
- < 5% purchase failure rate
- Positive user feedback

---

#### Step 2: Limited Release - Week 3-4

**Objectives:**

- Expand to larger audience
- Validate pricing strategy
- Optimize conversion flow

**Actions:**

- Enable for 25% of user base
- Run A/B tests on pricing (if applicable)
- Monitor conversion rates
- Gather more feedback

**Success Metrics:**

- > 2% free-to-paid conversion rate
- < 10% trial cancellation rate
- Positive revenue trend

---

#### Step 3: Full Launch - Week 5+

**Objectives:**

- Enable for all users
- Maximize conversions
- Establish steady revenue stream

**Actions:**

- Enable for 100% of users
- Announce via email/notifications
- Promote premium features
- Monitor first 48 hours closely

**Success Metrics:**

- Stable conversion rates
- Low churn rate (< 5% monthly)
- Growing MRR

---

#### Step 4: Optimization - Ongoing

**Actions:**

- Analyze conversion funnels
- A/B test upgrade prompts
- Optimize feature gating
- Adjust pricing if needed
- Add new premium features

---

## 📊 Phase 8: Analytics & Monitoring

### Metrics to Track

#### 1. Conversion Metrics

| Metric                    | Formula                                | Target   |
| ------------------------- | -------------------------------------- | -------- |
| Free → Premium Conversion | (Premium Users / Total Users) × 100    | > 2%     |
| Trial → Paid Conversion   | (Paid After Trial / Trial Users) × 100 | > 40%    |
| Time to First Purchase    | Average days from signup to purchase   | < 7 days |
| Purchase Funnel Drop-off  | % users at each funnel step            | Minimize |

#### 2. Revenue Metrics

| Metric        | Description                  | Target   |
| ------------- | ---------------------------- | -------- |
| MRR           | Monthly Recurring Revenue    | Growing  |
| ARR           | Annual Recurring Revenue     | Growing  |
| ARPU          | Average Revenue Per User     | > $1.00  |
| LTV           | Customer Lifetime Value      | > $50    |
| Churn Rate    | % users cancelling per month | < 5%     |
| Revenue Churn | $ lost from cancellations    | < 3% MRR |

#### 3. User Behavior Metrics

- Features driving most upgrades
- Drop-off points in purchase flow
- Most popular subscription tier
- Device types with highest conversion
- Time of day for most purchases
- Seasonal trends

### Implementation

```brightscript
' Track subscription events
sub trackSubscriptionEvent(eventName as string, properties as object)
    analyticsData = {
        event: eventName,
        timestamp: CreateObject("roDateTime").AsSeconds(),
        userId: m.global.userId,
        tier: m.global.subscriptionStatus.tier,
        properties: properties
    }

    ' Send to your analytics service
    sendAnalytics(analyticsData)
end sub

' Example usage:
' trackSubscriptionEvent("subscription_screen_viewed", {})
' trackSubscriptionEvent("upgrade_button_clicked", {plan: "premium_monthly"})
' trackSubscriptionEvent("purchase_completed", {plan: "premium_monthly", price: 3.99})
' trackSubscriptionEvent("purchase_failed", {plan: "premium_monthly", error: "user_cancelled"})
```

---

## 🔒 Phase 9: Security Considerations

### 1. Receipt Validation

**Critical: Always validate purchases on your backend**

```
Flow:
1. Roku completes purchase
2. App receives purchase token
3. App sends token to YOUR server
4. YOUR server validates with Roku API
5. YOUR server updates database
6. YOUR server responds to app
7. App unlocks features
```

**Why?**

- Prevents fake/tampered purchases
- Ensures database consistency
- Provides audit trail

### 2. Entitlement Storage

**On Device:**

- Store encrypted subscription data
- Don't store sensitive payment info
- Cache for offline access

**On Server:**

- Primary source of truth
- Regular sync from Roku
- Handle offline edge cases

### 3. Anti-Fraud Measures

- [ ] Log all purchase attempts
- [ ] Monitor for suspicious patterns
- [ ] Implement rate limiting (max purchases per hour)
- [ ] Detect/block account sharing
- [ ] Flag unusual behavior
- [ ] Regular audit of active subscriptions

### 4. Privacy & Compliance

- [ ] Update privacy policy for billing
- [ ] Disclose data collection
- [ ] Follow GDPR/CCPA if applicable
- [ ] Secure storage of purchase data
- [ ] Allow data deletion requests
- [ ] Provide purchase history to users

### 5. Error Handling Best Practices

```brightscript
' Never expose internal errors to users
sub handlePurchaseError(error as object)
    ' Log detailed error internally
    logError("Purchase failed: " + error.code + " - " + error.message)

    ' Show user-friendly message
    if error.code = "network_error" then
        showMessage("Network error. Please check your connection and try again.")
    else if error.code = "payment_declined" then
        showMessage("Payment could not be processed. Please check your payment method.")
    else
        showMessage("Purchase could not be completed. Please try again later.")
    end if
end sub
```

---

## 💰 Phase 10: Pricing Strategy

### Recommended Pricing Models

#### Option A: Simple Two-Tier ⭐ **Best for Launch**

```
┌─────────────────────────────────────────┐
│ FREE                                    │
│ • 5GB storage                           │
│ • Basic features                        │
│ • Ads                                   │
│                                         │
│ $0/month                                │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ PREMIUM  👑                             │
│ • 50GB storage                          │
│ • All features                          │
│ • No ads                                │
│ • HD quality                            │
│                                         │
│ $4.99/month or $49.99/year              │
│ (Save $10 annually!)                    │
└─────────────────────────────────────────┘
```

**Pros:**

- Simple choice for users
- Easy to communicate value
- Lower barrier to entry
- Good for initial launch

---

#### Option B: Three-Tier ⭐⭐ **Recommended Long-term**

```
┌──────────────────┬──────────────────┬──────────────────┐
│ FREE             │ PREMIUM          │ PRO              │
├──────────────────┼──────────────────┼──────────────────┤
│ • 5GB            │ • 50GB  ⭐       │ • 200GB          │
│ • SD quality     │ • HD quality     │ • 4K quality     │
│ • 1 device       │ • 3 devices      │ • 5 devices      │
│ • Ads            │ • No ads         │ • No ads         │
│ • Basic support  │ • Email support  │ • Priority       │
│                  │ • Fast speed     │ • API access     │
│                  │                  │ • Custom domain  │
├──────────────────┼──────────────────┼──────────────────┤
│ $0               │ $3.99/month      │ $7.99/month      │
│                  │ $39.99/year      │ $79.99/year      │
└──────────────────┴──────────────────┴──────────────────┘
```

**Pros:**

- Provides "middle option" (most popular)
- Captures power users with Pro tier
- Better revenue optimization
- Clearer value ladder

---

### Psychological Pricing Tactics

1. **Use .99 Endings**

   - $3.99 feels significantly cheaper than $4.00
   - Industry standard for subscriptions

2. **Show Annual Savings**

   - "$39.99/year (Save 17%!)"
   - "Only $3.33/month when billed annually"

3. **Highlight Most Popular**

   - Badge middle tier as "Most Popular"
   - Social proof increases conversions

4. **Limited-Time Offers**

   - "50% off first month!"
   - "7-day free trial - cancel anytime"
   - Creates urgency

5. **Comparison Table**
   - Side-by-side feature comparison
   - Checkmarks ✓ vs crosses ✗
   - Makes value clear

### Free Trial Strategy

**Recommended: 7-Day Free Trial for Monthly Plans**

**Benefits:**

- Low commitment for users
- Users experience premium features
- Higher conversion after trial
- Industry standard

**Implementation:**

```brightscript
' Product configuration
{
    productId: "seedr_premium_monthly",
    freeTrialType: "time",
    freeTrialQuantity: 7  ' days
}
```

**Best Practices:**

- Clearly state "Cancel anytime"
- Send reminder 2 days before trial ends
- One-click cancellation
- No charges during trial

---

## 📚 Resources & Next Steps

### Required Documentation

- [ ] **Roku Pay SDK Documentation**
  - URL: https://developer.roku.com/docs/developer-program/roku-pay
  - Topics: ChannelStore API, Purchase Flow
- [ ] **ChannelStore API Reference**
  - URL: https://developer.roku.com/docs/references/scenegraph/control-nodes/channelstore.md
  - Methods: GetCatalog, GetPurchases, DoOrder
- [ ] **Roku Billing Best Practices**
  - URL: https://developer.roku.com/docs/developer-program/roku-pay/implementation/best-practices.md
  - Topics: UX patterns, Error handling
- [ ] **Roku Certification Requirements**
  - URL: https://developer.roku.com/docs/developer-program/certification
  - Important for submission approval

### Assets Needed

#### Graphics/Design

- [ ] Product images for store listing (1920x1080)
- [ ] Subscription plan comparison cards
- [ ] Premium badge icon (for content)
- [ ] Upgrade button designs
- [ ] Success/Error dialog graphics
- [ ] "Most Popular" badge
- [ ] Tier icons (Free/Premium/Pro)

#### Legal/Documentation

- [ ] Updated privacy policy (billing section)
- [ ] Updated terms of service (subscriptions)
- [ ] Refund policy document
- [ ] User-facing subscription FAQ
- [ ] Cancellation instructions
- [ ] Support contact information

---

## ⚠️ Important Considerations

### Financial

| Item                   | Details                                 |
| ---------------------- | --------------------------------------- |
| **Roku Commission**    | 20% of all transactions                 |
| **Payment Processing** | Handled by Roku                         |
| **Payout Schedule**    | Monthly (NET 30 days)                   |
| **Minimum Payout**     | $50 threshold                           |
| **Tax Handling**       | Roku collects but verify local laws     |
| **Refunds**            | Roku handles, deducted from your payout |

### Technical

- **Certification Required** - Must pass Roku review before going live
- **Testing Period** - Allow 2-4 weeks for thorough testing
- **Review Time** - Roku certification takes 3-7 business days
- **Version Updates** - Subscriptions must work across updates

### Legal

- **Refund Policy** - Must follow Roku guidelines (typically 30 days)
- **Auto-Renewal** - Must clearly communicate to users
- **Cancellation** - Must be easy (max 3 clicks)
- **Privacy** - Update policy before launch
- **Tax Compliance** - Consult tax professional if needed

### User Experience

- **Clear Pricing** - No hidden fees or surprises
- **Easy Cancellation** - Don't hide the cancel button
- **Trial Transparency** - Clear when trial ends and charging begins
- **Feature Access** - Immediate upon purchase
- **Support** - Have team ready for billing questions

---

## 🎬 Next Steps - Immediate Actions

### Priority 1: Planning & Setup (This Week)

1. **Review This Plan**

   - [ ] Read through entire document
   - [ ] Clarify any questions
   - [ ] Get stakeholder approval

2. **Make Key Decisions**

   - [ ] Choose pricing tier structure (2-tier vs 3-tier)
   - [ ] Decide on specific prices
   - [ ] Determine free trial duration (0, 7, 14 days?)
   - [ ] Define premium features list

3. **Access Roku Developer Dashboard**
   - [ ] Log in to developer account
   - [ ] Navigate to your channel
   - [ ] Familiarize with monetization section

### Priority 2: Backend Preparation (Week 1-2)

4. **Check Seedr API Readiness**

   - [ ] Confirm API supports subscription tiers
   - [ ] Verify storage limits can be enforced
   - [ ] Test tier-based content filtering

5. **Set Up Product Catalog**
   - [ ] Create products in Roku dashboard
   - [ ] Configure test products
   - [ ] Document product IDs

### Priority 3: Implementation (Week 2-4)

6. **Start with Phase 1**

   - [ ] Create PurchaseHandler component
   - [ ] Implement basic GetCatalog() call
   - [ ] Test in development environment

7. **Build Subscription Screen**
   - [ ] Design UI layout
   - [ ] Implement basic functionality
   - [ ] Add focus management

### Priority 4: Testing & Launch (Week 4-6)

8. **Thorough Testing**

   - [ ] Test all purchase flows
   - [ ] Test subscription states
   - [ ] Perform security audit

9. **Soft Launch**
   - [ ] Enable for beta users
   - [ ] Monitor closely
   - [ ] Gather feedback

---

## ❓ Questions to Answer Before Implementation

### Business Questions

1. **Pricing Tiers**

   - How many tiers? (Recommended: 2 for launch, expand to 3 later)
   - What price points? (Suggested: Free, $3.99/mo, $7.99/mo)

2. **Free Trial**

   - Offer free trial? (Recommended: Yes)
   - How long? (Recommended: 7 days)
   - For which tiers? (All paid tiers)

3. **Features**

   - What features are premium-only?
   - Storage limits per tier?
   - Quality restrictions per tier?

4. **Timing**
   - Launch alongside existing channel or new version?
   - Any promotional pricing for launch?

### Technical Questions

5. **Backend**

   - Is Seedr API ready for tier-based access?
   - Can you validate Roku receipts server-side?
   - Is database schema prepared?

6. **Testing**
   - Test environment ready?
   - Beta testers available?
   - How long for testing phase?

---

## 📞 Support & Questions

If you have questions during implementation:

1. **Roku Developer Forums**

   - https://community.roku.com/
   - Active community, fast responses

2. **Roku Developer Support**

   - developer@roku.com
   - For technical/account issues

3. **This Documentation**
   - Keep updated as you implement
   - Document any gotchas/learnings

---

## 📝 Version History

| Version | Date       | Changes              |
| ------- | ---------- | -------------------- |
| 1.0     | 2025-01-03 | Initial plan created |

---

**Ready to get started? Begin with Phase 1: Roku Developer Portal Setup!**

Good luck with your Roku Pay integration! 🚀


Quick sketch of the secure flow

Sign in → call getUserData (RFI) → get {email}. 
Roku

Show either:

Password field, or

“Send code to {email}” → user enters OTP in-app.

Your server verifies and returns your access/refresh (or Roku-scoped JWT).

On each launch, validate session → proceed.

