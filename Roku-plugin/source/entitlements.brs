' ********** Entitlements and Subscription Management **********
'
' This file contains utility functions for checking user subscription
' status and managing feature access based on subscription tier

' Initialize global subscription state
sub initGlobalSubscriptionState()
    print "[Entitlements] Initializing global subscription state..."

    if m.global <> invalid then
        ' Add subscription status field if it doesn't exist
        if m.global.subscriptionStatus = invalid then
            m.global.addFields({
                subscriptionStatus: {
                    tier: "free"
                    isActive: false
                    isPremium: false
                    expiryDate: ""
                    productId: ""
                    purchaseDate: ""
                    isTrial: false
                    trialEndDate: ""
                    autoRenew: false
                    renewalDate: ""
                }
            })
            print "[Entitlements] Created subscription status field"
        else
            print "[Entitlements] Subscription status field already exists"
        end if
    else
        print "[Entitlements] WARNING: m.global is invalid"
    end if
end sub

' Check if user is premium (any paid tier)
function isPremiumUser() as boolean
    if m.global = invalid then return false
    if m.global.subscriptionStatus = invalid then return false

    status = m.global.subscriptionStatus
    return status.isPremium = true and status.isActive = true
end function

' Check if user is on specific tier
function isUserTier(tierName as string) as boolean
    if m.global = invalid then return false
    if m.global.subscriptionStatus = invalid then return false

    status = m.global.subscriptionStatus
    return LCase(status.tier) = LCase(tierName)
end function

' Check if user can access specific feature
function canAccessFeature(featureName as string) as boolean
    if m.global = invalid then return false
    if m.global.subscriptionStatus = invalid then return true ' Fail open

    status = m.global.subscriptionStatus
    tier = LCase(status.tier)
    feature = LCase(featureName)

    ' Define feature access rules

    ' Features available to all users
    if feature = "basic_streaming" then return true
    if feature = "file_browsing" then return true
    if feature = "sd_quality" then return true

    ' Premium features (Premium and Pro tiers)
    if feature = "hd_streaming" then
        return tier = "premium" or tier = "pro"
    end if

    if feature = "no_ads" then
        return tier = "premium" or tier = "pro"
    end if

    if feature = "fast_speed" then
        return tier = "premium" or tier = "pro"
    end if

    if feature = "multiple_devices" then
        return tier = "premium" or tier = "pro"
    end if

    ' Pro-only features
    if feature = "4k_streaming" then
        return tier = "pro"
    end if

    if feature = "api_access" then
        return tier = "pro"
    end if

    if feature = "priority_support" then
        return tier = "pro"
    end if

    if feature = "custom_domain" then
        return tier = "pro"
    end if

    ' Unknown features - default to requiring premium
    print "[Entitlements] WARNING: Unknown feature requested: " + featureName
    return status.isPremium = true
end function

' Get storage limit in bytes based on tier
function getStorageLimit() as longinteger
    if m.global = invalid then return 5368709120& ' 5GB default
    if m.global.subscriptionStatus = invalid then return 5368709120&

    status = m.global.subscriptionStatus
    tier = LCase(status.tier)

    if tier = "pro" then
        return 214748364800& ' 200GB in bytes
    else if tier = "premium" then
        return 53687091200& ' 50GB in bytes
    else
        return 5368709120& ' 5GB in bytes (free tier)
    end if
end function

' Get storage limit in GB (for display)
function getStorageLimitGB() as integer
    if m.global = invalid then return 5
    if m.global.subscriptionStatus = invalid then return 5

    status = m.global.subscriptionStatus
    tier = LCase(status.tier)

    if tier = "pro" then
        return 200
    else if tier = "premium" then
        return 50
    else
        return 5
    end if
end function

' Get device limit based on tier
function getDeviceLimit() as integer
    if m.global = invalid then return 1
    if m.global.subscriptionStatus = invalid then return 1

    status = m.global.subscriptionStatus
    tier = LCase(status.tier)

    if tier = "pro" then
        return 5
    else if tier = "premium" then
        return 3
    else
        return 1
    end if
end function

' Check if user should see ads
function shouldShowAds() as boolean
    ' Premium and Pro users don't see ads
    return not isPremiumUser()
end function

' Get max video quality based on tier
function getMaxVideoQuality() as string
    if m.global = invalid then return "SD"
    if m.global.subscriptionStatus = invalid then return "SD"

    status = m.global.subscriptionStatus
    tier = LCase(status.tier)

    if tier = "pro" then
        return "4K"
    else if tier = "premium" then
        return "HD"
    else
        return "SD"
    end if
end function

' Check if subscription is in trial period
function isInTrialPeriod() as boolean
    if m.global = invalid then return false
    if m.global.subscriptionStatus = invalid then return false

    status = m.global.subscriptionStatus
    return status.isTrial = true and status.isActive = true
end function

' Get days remaining in trial
function getTrialDaysRemaining() as integer
    if not isInTrialPeriod() then return 0

    if m.global.subscriptionStatus.trialEndDate = "" then return 0

    ' Calculate days remaining
    ' This is simplified - implement proper date parsing
    return 7 ' Placeholder
end function

' Get subscription tier display name
function getTierDisplayName() as string
    if m.global = invalid then return "Free"
    if m.global.subscriptionStatus = invalid then return "Free"

    status = m.global.subscriptionStatus
    tier = LCase(status.tier)

    if tier = "pro" then
        return "Pro"
    else if tier = "premium" then
        return "Premium"
    else
        return "Free"
    end if
end function

' Get subscription status text for display
function getSubscriptionStatusText() as string
    if m.global = invalid then return "Free Account"
    if m.global.subscriptionStatus = invalid then return "Free Account"

    status = m.global.subscriptionStatus

    if not status.isActive then
        return "Free Account"
    end if

    tierName = getTierDisplayName()

    if status.isTrial then
        return tierName + " Trial"
    else
        return tierName + " Subscriber"
    end if
end function

' Get renewal/expiry information
function getSubscriptionExpiryInfo() as string
    if m.global = invalid then return ""
    if m.global.subscriptionStatus = invalid then return ""

    status = m.global.subscriptionStatus

    if not status.isActive then
        return ""
    end if

    if status.renewalDate <> "" and status.autoRenew then
        return "Renews: " + formatDate(status.renewalDate)
    else if status.expiryDate <> "" then
        return "Expires: " + formatDate(status.expiryDate)
    end if

    return ""
end function

' Format date for display
function formatDate(dateString as string) as string
    ' Simple date formatting - enhance as needed
    if dateString = "" then return ""

    ' Assuming ISO format: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS
    if len(dateString) >= 10 then
        return left(dateString, 10)
    end if

    return dateString
end function

' Check if user has specific product entitlement
function hasProductEntitlement(productId as string) as boolean
    if m.global = invalid then return false
    if m.global.subscriptionStatus = invalid then return false

    status = m.global.subscriptionStatus
    return status.productId = productId and status.isActive = true
end function

' Get list of premium features for marketing
function getPremiumFeatures() as object
    return [
        {
            name: "Increased Storage"
            description: "Get 50GB or 200GB based on your plan"
            icon: "💾"
        }
        {
            name: "HD & 4K Streaming"
            description: "Watch in crystal clear quality"
            icon: "🎬"
        }
        {
            name: "No Advertisements"
            description: "Enjoy uninterrupted viewing"
            icon: "⭐"
        }
        {
            name: "Fast Downloads"
            description: "Priority speed for all transfers"
            icon: "⚡"
        }
        {
            name: "Multiple Devices"
            description: "Use Seedr on up to 5 devices"
            icon: "📱"
        }
        {
            name: "Priority Support"
            description: "Get help faster with Pro tier"
            icon: "🎧"
        }
    ]
end function

' Check if feature should show upgrade prompt
function shouldShowUpgradePrompt(featureName as string) as boolean
    ' Don't show prompts to premium users
    if isPremiumUser() then return false

    ' Show prompts for premium features
    return not canAccessFeature(featureName)
end function

' Get upgrade CTA text based on feature
function getUpgradeCTAText(featureName as string) as string
    feature = LCase(featureName)

    if feature = "hd_streaming" or feature = "4k_streaming" then
        return "Upgrade to Premium for HD/4K quality"
    else if feature = "no_ads" then
        return "Remove ads with Premium"
    else if feature = "fast_speed" then
        return "Get faster speeds with Premium"
    else if feature = "api_access" then
        return "Unlock API access with Pro"
    else
        return "Upgrade to Premium for this feature"
    end if
end function

' Log subscription status (for debugging)
sub logSubscriptionStatus()
    if m.global = invalid then
        print "[Entitlements] m.global is invalid"
        return
    end if

    if m.global.subscriptionStatus = invalid then
        print "[Entitlements] subscriptionStatus is invalid"
        return
    end if

    status = m.global.subscriptionStatus

    print "[Entitlements] === Subscription Status ==="
    print "  Tier: " + status.tier

    ' Convert booleans to strings for display
    activeStr = "false"
    if status.isActive = true then activeStr = "true"
    print "  Active: " + activeStr

    premiumStr = "false"
    if status.isPremium = true then premiumStr = "true"
    print "  Premium: " + premiumStr

    print "  Product ID: " + status.productId

    trialStr = "false"
    if status.isTrial = true then trialStr = "true"
    print "  Trial: " + trialStr

    autoRenewStr = "false"
    if status.autoRenew = true then autoRenewStr = "true"
    print "  Auto-Renew: " + autoRenewStr

    print "  Storage Limit: " + str(getStorageLimitGB()) + " GB"
    print "  Device Limit: " + str(getDeviceLimit())
    print "  Max Quality: " + getMaxVideoQuality()

    adsStr = "false"
    if shouldShowAds() = true then adsStr = "true"
    print "  Show Ads: " + adsStr

    print "[Entitlements] =========================="
end sub
