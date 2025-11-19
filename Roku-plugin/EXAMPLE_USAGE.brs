' ********** Example Usage **********
'
' This file demonstrates how to integrate the Subscription Screen into your Roku app

' ===== IN YOUR MAIN SCENE (e.g., MainScene.xml) =====
'
' Add the SubscriptionScreen component to your scene:
'
' <component name="MainScene" extends="Scene">
'     <children>
'         <!-- Your existing content -->
'         <ContentNode id="mainContent" />
'
'         <!-- Add Subscription Screen (hidden by default) -->
'         <SubscriptionScreen
'             id="subscriptionScreen"
'             visible="false" />
'     </children>
' </component>


' ===== IN YOUR MAIN SCENE LOGIC (e.g., MainScene.brs) =====

sub init()
    ' Get reference to subscription screen
    m.subscriptionScreen = m.top.findNode("subscriptionScreen")

    ' Observe when user goes back
    m.subscriptionScreen.observeField("backPressed", "onSubscriptionBackPressed")

    ' Observe when user selects a plan
    m.subscriptionScreen.observeField("productSelected", "onProductSelected")
end sub

' Show subscription screen (e.g., from menu button press)
sub showSubscriptionScreen()
    print "[MainScene] Showing subscription screen..."
    m.subscriptionScreen.visible = true
end sub

' Handle back button from subscription screen
sub onSubscriptionBackPressed()
    print "[MainScene] User closed subscription screen"
    m.subscriptionScreen.visible = false
    ' Return focus to your main content
    m.mainContent.setFocus(true)
end sub

' Handle plan selection
sub onProductSelected(event as object)
    productId = event.getData()
    print "[MainScene] User selected product: " + productId

    ' The purchase is handled automatically by SubscriptionScreen
    ' You can add additional logic here if needed, such as:
    ' - Tracking analytics
    ' - Updating UI
    ' - Notifying your backend server
end sub


' ===== EXAMPLE: TRIGGER FROM MENU =====

' When user selects "Upgrade" or "Subscriptions" from menu
sub onMenuItemSelected(menuItem as string)
    if menuItem = "subscriptions" or menuItem = "upgrade" then
        showSubscriptionScreen()
    end if
end sub


' ===== EXAMPLE: CHECK USER SUBSCRIPTION STATUS =====

' Check if user has active subscription
function hasActiveSubscription() as boolean
    ' Initialize Roku Pay Handler
    rokuPay = RokuPayHandler_init()

    ' Get user purchases
    rokuPay.getPurchases()

    ' Wait for response (in real app, do this asynchronously)
    ' ... handle in event loop

    ' Check if user owns any plan
    plans = ["seedr_basic_monthly", "seedr_pro_monthly", "seedr_master_monthly"]
    for each planId in plans
        if rokuPay.isProductOwned(planId) then
            return true
        end if
    end for

    return false
end function


' ===== EXAMPLE: UNLOCK PREMIUM FEATURES =====

' Check user's subscription tier and unlock features
sub unlockFeaturesBasedOnSubscription()
    rokuPay = RokuPayHandler_init()
    rokuPay.getPurchases()

    ' Check what user owns
    if rokuPay.isProductOwned("seedr_master_monthly") or rokuPay.isProductOwned("seedr_master_yearly") then
        print "[MainScene] User has Master subscription"
        m.maxStorage = 1000 ' 1TB
        m.maxTasks = 25
        m.enable4K = true

    else if rokuPay.isProductOwned("seedr_pro_monthly") or rokuPay.isProductOwned("seedr_pro_yearly") then
        print "[MainScene] User has Pro subscription"
        m.maxStorage = 150 ' 150GB
        m.maxTasks = 8
        m.enableHD = true

    else if rokuPay.isProductOwned("seedr_basic_monthly") or rokuPay.isProductOwned("seedr_basic_yearly") then
        print "[MainScene] User has Basic subscription"
        m.maxStorage = 50 ' 50GB
        m.maxTasks = 2

    else
        print "[MainScene] User is free tier"
        m.maxStorage = 5 ' 5GB
        m.maxTasks = 1
    end if
end sub


' ===== EXAMPLE: PROMPT USER TO UPGRADE =====

' Show upgrade prompt when user hits free tier limits
sub promptUpgrade()
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Upgrade to Premium"
    dialog.message = "You've reached your storage limit. Upgrade to get more space and faster speeds!"
    dialog.buttons = ["View Plans", "Not Now"]
    dialog.observeField("buttonSelected", "onUpgradePromptResult")

    m.top.getScene().dialog = dialog
end sub

sub onUpgradePromptResult(event as object)
    dialog = event.getRoSGNode()
    buttonIndex = dialog.buttonSelected

    m.top.getScene().dialog = invalid

    if buttonIndex = 0 then ' View Plans
        showSubscriptionScreen()
    end if
end sub


' ===== EXAMPLE: INTEGRATE WITH YOUR API =====

' After successful purchase, notify your backend
sub notifyBackendOfPurchase(productId as string, transactionId as string)
    ' Your API endpoint
    apiUrl = "https://api.seedr.cc/roku/subscription/activate"

    ' Create request
    request = CreateObject("roUrlTransfer")
    request.SetUrl(apiUrl)
    request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/json")

    ' Build payload
    payload = {
        productId: productId
        transactionId: transactionId
        deviceId: getDeviceId()
        timestamp: getCurrentTimestamp()
    }

    ' Send request
    request.AsyncPostFromString(FormatJson(payload))

    print "[API] Notified backend of purchase"
end sub

function getDeviceId() as string
    device = CreateObject("roDeviceInfo")
    return device.GetChannelClientId()
end function

function getCurrentTimestamp() as string
    dateTime = CreateObject("roDateTime")
    return dateTime.ToISOString()
end function


' ===== EXAMPLE: HANDLE SUBSCRIPTION EXPIRY =====

' Check if subscription has expired
sub checkSubscriptionExpiry()
    rokuPay = RokuPayHandler_init()
    rokuPay.getPurchases()

    ' Wait for response...
    ' Then check entitlement
    entitlement = rokuPay.validateEntitlement("seedr_pro_monthly")

    if entitlement.hasAccess = false then
        if entitlement.status = "Expired" then
            ' Show renewal prompt
            showRenewalPrompt()
        else
            ' User doesn't have subscription
            ' Revert to free tier
            revertToFreeTier()
        end if
    end if
end sub

sub showRenewalPrompt()
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Subscription Expired"
    dialog.message = "Your Pro subscription has expired. Renew now to continue enjoying premium features!"
    dialog.buttons = ["Renew", "Maybe Later"]
    dialog.observeField("buttonSelected", "onRenewalPromptResult")

    m.top.getScene().dialog = dialog
end sub


' ===== TIPS & BEST PRACTICES =====

' 1. Always check subscription status on app launch
' 2. Cache subscription status to avoid repeated API calls
' 3. Handle subscription changes (upgrades/downgrades/cancellations)
' 4. Notify your backend server of all purchases for verification
' 5. Test thoroughly with Roku test users before going live
' 6. Implement proper error handling for network issues
' 7. Show clear messaging about subscription benefits
' 8. Make it easy to manage/cancel subscriptions
' 9. Follow Roku's UI guidelines for payment flows
' 10. Monitor analytics to optimize conversion rates


' ===== COMPLETE INTEGRATION EXAMPLE =====

sub mainInit()
    ' Initialize subscription manager on app start
    initSubscriptionManager()

    ' Check user's subscription status
    checkAndUpdateSubscriptionStatus()

    ' Set up subscription screen
    setupSubscriptionScreen()
end sub

sub initSubscriptionManager()
    ' Create global subscription manager
    m.global.subscriptionManager = {
        rokuPay: RokuPayHandler_init()
        currentTier: "free"
        hasActiveSubscription: false
        expiryDate: invalid
    }

    ' Get catalog on launch
    m.global.subscriptionManager.rokuPay.getCatalog()
    m.global.subscriptionManager.rokuPay.getPurchases()
end sub

sub checkAndUpdateSubscriptionStatus()
    ' This should be done asynchronously in production
    ' Check all possible subscriptions
    plans = GetPlanConfigs()

    for each planKey in plans
        plan = plans[planKey]

        ' Check monthly
        if m.global.subscriptionManager.rokuPay.isProductOwned(plan.monthlyPlanId) then
            m.global.subscriptionManager.currentTier = planKey
            m.global.subscriptionManager.hasActiveSubscription = true
            unlockFeaturesForTier(planKey)
            return
        end if

        ' Check yearly
        if m.global.subscriptionManager.rokuPay.isProductOwned(plan.yearlyPlanId) then
            m.global.subscriptionManager.currentTier = planKey
            m.global.subscriptionManager.hasActiveSubscription = true
            unlockFeaturesForTier(planKey)
            return
        end if
    end for

    ' No subscription found - free tier
    m.global.subscriptionManager.currentTier = "free"
    m.global.subscriptionManager.hasActiveSubscription = false
end sub

sub unlockFeaturesForTier(tier as string)
    print "[App] Unlocking features for tier: " + tier

    ' Update global app state based on subscription tier
    m.global.userFeatures = {
        tier: tier
        storage: getStorageForTier(tier)
        tasks: getTasksForTier(tier)
        canStream4K: (tier = "master" or tier.inStr("gold") > -1)
        hasWebDAV: (tier = "master" or tier.inStr("gold") > -1)
        hasPriority: (tier = "master" or tier.inStr("gold") > -1)
    }
end sub

' ===== END OF EXAMPLES =====
'
' For more details, see:
' - ROKU_PAY_SETUP_GUIDE.md
' - IMPLEMENTATION_SUMMARY.md
' - README_ROKU_INTEGRATION.md














