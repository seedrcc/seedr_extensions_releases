' ********** Roku Pay Purchase Handler Component **********
'
' This component handles all Roku Pay interactions including:
' - Product catalog retrieval
' - Purchase management
' - Subscription entitlement checking
' - Order processing

sub init()
    print "[PurchaseHandler] Initializing Roku Pay system..."

    ' Get reference to ChannelStore node
    m.channelStore = m.top.findNode("channelStore")

    ' Initialize data structures
    m.catalog = {}
    m.purchases = {}
    m.catalogReady = false
    m.purchasesReady = false

    ' Set up ChannelStore observers
    m.channelStore.observeField("catalog", "onCatalogReceived")
    m.channelStore.observeField("purchases", "onPurchasesReceived")
    m.channelStore.observeField("orderStatus", "onOrderStatus")

    ' Set up interface observers
    m.top.observeField("initPurchaseSystem", "onInitPurchaseSystem")
    m.top.observeField("getCatalog", "onGetCatalogRequest")
    m.top.observeField("getPurchases", "onGetPurchasesRequest")
    m.top.observeField("orderProduct", "onOrderProduct")

    print "[PurchaseHandler] Initialization complete"
end sub

' Initialize purchase system - get catalog and purchases
sub onInitPurchaseSystem()
    print "[PurchaseHandler] Starting purchase system initialization..."

    ' Reset ready flags
    m.catalogReady = false
    m.purchasesReady = false
    m.top.catalogReady = false
    m.top.purchasesReady = false

    ' Request catalog and purchases
    print "[PurchaseHandler] Requesting product catalog..."
    m.channelStore.command = "getCatalog"

    print "[PurchaseHandler] Requesting user purchases..."
    m.channelStore.command = "getAllPurchases"
end sub

' Handle catalog request
sub onGetCatalogRequest()
    print "[PurchaseHandler] Catalog request received"
    m.channelStore.command = "getCatalog"
end sub

' Handle purchases request
sub onGetPurchasesRequest()
    print "[PurchaseHandler] Purchases request received"
    m.channelStore.command = "getAllPurchases"
end sub

' Catalog received from Roku
sub onCatalogReceived()
    print "[PurchaseHandler] Product catalog received"

    ' Clear existing catalog
    m.catalog = {}

    ' Process catalog items
    if m.channelStore.catalog <> invalid then
        catalogCount = m.channelStore.catalog.getChildCount()
        print "[PurchaseHandler] Processing " + str(catalogCount) + " catalog items..."

        for i = 0 to catalogCount - 1
            item = m.channelStore.catalog.getChild(i)
            if item <> invalid and item.code <> invalid then
                m.catalog[item.code] = item
                print "[PurchaseHandler] Product: " + item.code + " - " + item.name + " (" + item.cost + ")"
            end if
        end for
    end if

    ' Mark catalog as ready
    m.catalogReady = true
    m.top.catalogReady = true
    m.top.catalogData = m.catalog

    print "[PurchaseHandler] Catalog ready with " + str(m.catalog.count()) + " products"

    ' Update subscription status
    updateSubscriptionStatus()
end sub

' Purchases received from Roku
sub onPurchasesReceived()
    print "[PurchaseHandler] User purchases received"

    ' Clear existing purchases
    m.purchases = {}

    ' Process purchase items
    if m.channelStore.purchases <> invalid then
        purchaseCount = m.channelStore.purchases.getChildCount()
        print "[PurchaseHandler] Processing " + str(purchaseCount) + " purchase items..."

        for i = 0 to purchaseCount - 1
            item = m.channelStore.purchases.getChild(i)
            if item <> invalid and item.code <> invalid then
                m.purchases[item.code] = item

                ' Log purchase details
                statusText = "UNKNOWN"
                if item.status <> invalid then statusText = item.status

                print "[PurchaseHandler] Purchase: " + item.code + " - Status: " + statusText

                if item.expirationDate <> invalid and item.expirationDate <> "" then
                    print "  Expires: " + item.expirationDate
                end if

                if item.renewalDate <> invalid and item.renewalDate <> "" then
                    print "  Renews: " + item.renewalDate
                end if
            end if
        end for
    end if

    ' Mark purchases as ready
    m.purchasesReady = true
    m.top.purchasesReady = true
    m.top.purchasesData = m.purchases

    print "[PurchaseHandler] Purchases ready with " + str(m.purchases.count()) + " items"

    ' Update subscription status
    updateSubscriptionStatus()
end sub

' Handle order status changes
sub onOrderStatus()
    print "[PurchaseHandler] Order status changed"

    if m.channelStore.orderStatus <> invalid then
        orderStatus = m.channelStore.orderStatus

        ' Extract order information
        statusCode = -1
        if orderStatus.status <> invalid then
            statusCode = orderStatus.status
        end if

        print "[PurchaseHandler] Order status code: " + str(statusCode)

        ' Status codes:
        ' 0 = Order failed
        ' 1 = Order success
        ' 2 = Order cancelled by user

        result = {
            success: false
            cancelled: false
            error: ""
        }

        if statusCode = 1 then
            ' Order successful
            print "[PurchaseHandler] ✓ Order completed successfully!"
            result.success = true

            ' Refresh purchases to get updated entitlements
            m.channelStore.command = "getAllPurchases"
            m.channelStore.command = "getCatalog"

        else if statusCode = 2 then
            ' Order cancelled by user
            print "[PurchaseHandler] Order cancelled by user"
            result.cancelled = true
            result.error = "Purchase cancelled"

        else
            ' Order failed
            print "[PurchaseHandler] ✗ Order failed"
            result.error = "Purchase failed. Please try again."

            ' Try to get more detailed error info
            if orderStatus.errorCode <> invalid then
                print "[PurchaseHandler] Error code: " + str(orderStatus.errorCode)
                result.error = result.error + " (Error " + str(orderStatus.errorCode) + ")"
            end if

            if orderStatus.errorMessage <> invalid then
                print "[PurchaseHandler] Error message: " + orderStatus.errorMessage
            end if
        end if

        ' Notify parent component
        m.top.orderComplete = result
    else
        print "[PurchaseHandler] ERROR: orderStatus is invalid"
        m.top.orderComplete = {
            success: false
            cancelled: false
            error: "Unknown error occurred"
        }
    end if
end sub

' Process order request
sub onOrderProduct()
    productCode = m.top.orderProduct

    if productCode = invalid or productCode = "" then
        print "[PurchaseHandler] ERROR: Invalid product code"
        m.top.error = "Invalid product code"
        return
    end if

    print "[PurchaseHandler] Initiating purchase for product: " + productCode

    ' Check if product exists in catalog
    if not m.catalog.doesExist(productCode) then
        print "[PurchaseHandler] ERROR: Product not found in catalog: " + productCode
        m.top.error = "Product not found: " + productCode
        return
    end if

    ' Create order node
    orderNode = CreateObject("roSGNode", "ContentNode")
    item = orderNode.createChild("ContentNode")
    item.addFields({
        "code": productCode
        "qty": 1
    })

    ' Submit order to Roku
    print "[PurchaseHandler] Submitting order to Roku Pay..."
    m.channelStore.order = orderNode
    m.channelStore.command = "doOrder"

    print "[PurchaseHandler] Order submitted, waiting for Roku Pay dialog..."
end sub

' Update subscription status based on purchases
sub updateSubscriptionStatus()
    print "[PurchaseHandler] Updating subscription status..."

    ' Only update if both catalog and purchases are ready
    if not (m.catalogReady and m.purchasesReady) then
        print "[PurchaseHandler] Waiting for catalog and purchases to load..."
        return
    end if

    ' Default status: free tier
    status = {
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

    ' Check for active subscriptions
    ' Priority: Check premium products in order of preference
    activePurchase = invalid

    ' List of product IDs to check (customize based on your products)
    productIdsToCheck = [
        "seedr_premium_yearly"
        "seedr_premium_monthly"
        "seedr_pro_yearly"
        "seedr_pro_monthly"
    ]

    ' Find first active subscription
    for each productId in productIdsToCheck
        if m.purchases.doesExist(productId) then
            purchase = m.purchases[productId]

            ' Check if purchase is valid
            if purchase.status <> invalid and purchase.status = "Valid" then
                activePurchase = purchase
                status.productId = productId

                ' Determine tier from product ID
                if inStr(1, LCase(productId), "pro") > 0 then
                    status.tier = "pro"
                else if inStr(1, LCase(productId), "premium") > 0 then
                    status.tier = "premium"
                end if

                exit for ' Found active subscription
            end if
        end if
    end for

    ' Process active subscription details
    if activePurchase <> invalid then
        status.isActive = true
        status.isPremium = true

        ' Extract purchase details
        if activePurchase.purchaseDate <> invalid then
            status.purchaseDate = activePurchase.purchaseDate
        end if

        if activePurchase.expirationDate <> invalid then
            status.expiryDate = activePurchase.expirationDate
        end if

        if activePurchase.renewalDate <> invalid then
            status.renewalDate = activePurchase.renewalDate
            status.autoRenew = true
        end if

        ' Check if in trial period
        if activePurchase.freeTrialQuantity <> invalid and activePurchase.freeTrialQuantity > 0 then
            ' Calculate trial end date based on purchase date and trial length
            if status.purchaseDate <> "" then
                status.isTrial = checkIfInTrial(status.purchaseDate, activePurchase.freeTrialQuantity)
                if status.isTrial then
                    status.trialEndDate = calculateTrialEndDate(status.purchaseDate, activePurchase.freeTrialQuantity)
                end if
            end if
        end if

        print "[PurchaseHandler] ✓ Active subscription found:"
        print "  Tier: " + status.tier
        print "  Product: " + status.productId
        print "  Expires: " + status.expiryDate

        ' Convert boolean to string for display
        trialStr = "false"
        if status.isTrial = true then trialStr = "true"
        print "  Trial: " + trialStr
    else
        print "[PurchaseHandler] No active subscriptions - user is on free tier"
    end if

    ' Store in global state for app-wide access
    if m.global <> invalid then
        m.global.addFields({ subscriptionStatus: status })
    end if

    ' Notify parent component
    m.top.subscriptionStatus = status

    print "[PurchaseHandler] Subscription status update complete"
end sub

' Check if user is currently in trial period
function checkIfInTrial(purchaseDate as string, trialDays as integer) as boolean
    if purchaseDate = "" or trialDays <= 0 then
        return false
    end if

    ' Parse purchase date and calculate trial end
    ' This is simplified - you may need more robust date parsing
    currentDate = CreateObject("roDateTime")

    ' For now, assume trial is active if purchase is recent
    ' In production, implement proper date comparison
    return false ' Update this with proper date logic
end function

' Calculate trial end date
function calculateTrialEndDate(purchaseDate as string, trialDays as integer) as string
    ' Implement date calculation logic
    ' For now, return empty string
    ' In production, add trialDays to purchaseDate
    return ""
end function

' Check if user has specific entitlement
function isEntitled(productCode as string) as boolean
    if m.purchases.doesExist(productCode) then
        purchase = m.purchases[productCode]
        if purchase <> invalid and purchase.status <> invalid then
            return (purchase.status = "Valid")
        end if
    end if
    return false
end function

' Check if user is premium (any premium subscription)
function isPremiumUser() as boolean
    ' Check all premium/pro products
    premiumProducts = [
        "seedr_premium_monthly"
        "seedr_premium_yearly"
        "seedr_pro_monthly"
        "seedr_pro_yearly"
    ]

    for each productId in premiumProducts
        if isEntitled(productId) then
            return true
        end if
    end for

    return false
end function

' Get catalog data for UI
function getCatalogData() as object
    return m.catalog
end function

' Get purchases data for UI
function getPurchasesData() as object
    return m.purchases
end function
