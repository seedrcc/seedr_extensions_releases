' ********** Roku Pay Handler **********
'
' Handles all Roku Pay/Channel Store interactions
' Including: Catalog retrieval, purchases, subscriptions, and entitlements

' Initialize Roku Pay Handler
function RokuPayHandler_init() as object
    handler = {
        channelStore: CreateObject("roChannelStore")
        port: CreateObject("roMessagePort")
        catalog: invalid
        purchases: invalid
        pendingRequest: invalid

        ' Public methods
        getCatalog: RokuPayHandler_getCatalog
        getPurchases: RokuPayHandler_getPurchases
        makePurchase: RokuPayHandler_makePurchase
        checkMessages: RokuPayHandler_checkMessages
        isProductOwned: RokuPayHandler_isProductOwned
        validateEntitlement: RokuPayHandler_validateEntitlement

        ' Private methods
        processMessage: RokuPayHandler_processMessage
        handleCatalogResponse: RokuPayHandler_handleCatalogResponse
        handlePurchaseResponse: RokuPayHandler_handlePurchaseResponse
        handlePurchasesResponse: RokuPayHandler_handlePurchasesResponse
    }

    ' Set message port
    handler.channelStore.SetMessagePort(handler.port)

    return handler
end function

' Get product catalog from Roku
sub RokuPayHandler_getCatalog()
    print "[RokuPay] Requesting product catalog..."
    m.channelStore.GetCatalog()
    m.pendingRequest = "catalog"
end sub

' Get user's purchases
sub RokuPayHandler_getPurchases()
    print "[RokuPay] Requesting user purchases..."
    m.channelStore.GetPurchases()
    m.pendingRequest = "purchases"
end sub

' Make a purchase
' @param productId - The Roku product code to purchase
' @param quantity - Number of items (usually 1)
function RokuPayHandler_makePurchase(productId as string, quantity as integer) as boolean
    print "[RokuPay] Initiating purchase for: " + productId

    if m.channelStore = invalid then
        print "[RokuPay] ERROR: Channel store not initialized"
        return false
    end if

    ' Create order
    order = CreateObject("roAssociativeArray")
    order.code = productId
    order.qty = quantity

    ' Submit order
    m.channelStore.DoOrder(order)
    m.pendingRequest = "purchase"

    return true
end function

' Check for messages from Roku Pay
' Returns: { type: "catalog|purchase|purchases|none", success: true|false, data: {} }
function RokuPayHandler_checkMessages() as object
    result = {
        type: "none"
        success: false
        data: invalid
        errorCode: 0
        errorMessage: ""
    }

    if m.port = invalid then return result

    msg = m.port.GetMessage()

    if msg <> invalid and type(msg) = "roChannelStoreEvent" then
        result = m.processMessage(msg)
    end if

    return result
end function

' Process channel store message
function RokuPayHandler_processMessage(msg as object) as object
    result = {
        type: m.pendingRequest
        success: false
        data: invalid
        errorCode: 0
        errorMessage: ""
    }

    if msg.isRequestSucceeded() then
        result.success = true

        if m.pendingRequest = "catalog" then
            result = m.handleCatalogResponse(msg)
        else if m.pendingRequest = "purchase" then
            result = m.handlePurchaseResponse(msg)
        else if m.pendingRequest = "purchases" then
            result = m.handlePurchasesResponse(msg)
        end if

    else if msg.isRequestFailed() then
        result.success = false
        result.errorCode = msg.GetStatus()
        result.errorMessage = msg.GetStatusMessage()

        print "[RokuPay] Request failed - Code: " + str(result.errorCode)
        print "[RokuPay] Error message: " + result.errorMessage
    end if

    return result
end function

' Handle catalog response
function RokuPayHandler_handleCatalogResponse(msg as object) as object
    print "[RokuPay] Catalog received"

    m.catalog = msg.GetCatalog()

    result = {
        type: "catalog"
        success: true
        data: m.catalog
        errorCode: 0
        errorMessage: ""
    }

    ' Log catalog items
    if m.catalog <> invalid and m.catalog.count() > 0 then
        print "[RokuPay] Catalog contains " + str(m.catalog.count()) + " products"
        for each product in m.catalog
            if product.code <> invalid then
                print "  - Product: " + product.code + " | Name: " + str(product.name) + " | Price: " + str(product.price)
            end if
        end for
    else
        print "[RokuPay] WARNING: Catalog is empty"
    end if

    return result
end function

' Handle purchase response
function RokuPayHandler_handlePurchaseResponse(msg as object) as object
    print "[RokuPay] Purchase completed successfully"

    purchaseInfo = msg.GetResponse()

    result = {
        type: "purchase"
        success: true
        data: purchaseInfo
        errorCode: 0
        errorMessage: ""
    }

    ' Log purchase details
    if purchaseInfo <> invalid then
        print "[RokuPay] Transaction ID: " + str(purchaseInfo.transactionId)
        print "[RokuPay] Product: " + str(purchaseInfo.code)
    end if

    ' Refresh purchases list
    m.getPurchases()

    return result
end function

' Handle purchases list response
function RokuPayHandler_handlePurchasesResponse(msg as object) as object
    print "[RokuPay] Purchases list received"

    m.purchases = msg.GetPurchases()

    result = {
        type: "purchases"
        success: true
        data: m.purchases
        errorCode: 0
        errorMessage: ""
    }

    ' Log purchases
    if m.purchases <> invalid and m.purchases.count() > 0 then
        print "[RokuPay] User has " + str(m.purchases.count()) + " purchases"
        for each purchase in m.purchases
            if purchase.code <> invalid then
                print "  - Product: " + purchase.code + " | Status: " + str(purchase.status)
            end if
        end for
    else
        print "[RokuPay] User has no purchases"
    end if

    return result
end function

' Check if user owns a specific product
function RokuPayHandler_isProductOwned(productId as string) as boolean
    if m.purchases = invalid or m.purchases.count() = 0 then
        return false
    end if

    for each purchase in m.purchases
        if purchase.code = productId then
            ' Check if purchase is valid (not expired/cancelled)
            if purchase.status <> invalid then
                if purchase.status = "Valid" or purchase.status = "active" then
                    return true
                end if
            end if
        end if
    end for

    return false
end function

' Validate user entitlement for a product
' Returns: { hasAccess: true|false, expiryDate: "", status: "" }
function RokuPayHandler_validateEntitlement(productId as string) as object
    result = {
        hasAccess: false
        expiryDate: ""
        status: "none"
        purchaseDate: ""
    }

    if m.purchases = invalid or m.purchases.count() = 0 then
        return result
    end if

    for each purchase in m.purchases
        if purchase.code = productId then
            result.status = purchase.status

            if purchase.status = "Valid" or purchase.status = "active" then
                result.hasAccess = true
            end if

            if purchase.expirationDate <> invalid then
                result.expiryDate = purchase.expirationDate
            end if

            if purchase.purchaseDate <> invalid then
                result.purchaseDate = purchase.purchaseDate
            end if

            return result
        end if
    end for

    return result
end function


