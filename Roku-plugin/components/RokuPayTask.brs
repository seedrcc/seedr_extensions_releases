' ********** Roku Pay Task Component **********
'
' Handles Roku Pay operations on the Task thread

sub init()
    print "[RokuPayTask] Initializing..."

    m.top.functionName = "runTask"
    m.channelStore = invalid
    m.catalog = invalid
    m.port = CreateObject("roMessagePort")

    print "[RokuPayTask] Initialization complete"
end sub

' Main task loop
sub runTask()
    print "[RokuPayTask] Task started"

    ' Initialize Roku Pay
    initRokuPay()

    ' Monitor for commands and messages
    while true
        msg = wait(100, m.port)

        if msg <> invalid then
            handleMessage(msg)
        end if

        ' Check for commands
        if m.top.command <> "" then
            handleCommand(m.top.command)
            m.top.command = ""
        end if
    end while
end sub

' Initialize Roku Pay
sub initRokuPay()
    print "[RokuPayTask] Initializing roChannelStore..."

    m.channelStore = CreateObject("roChannelStore")

    if m.channelStore <> invalid then
        m.channelStore.SetMessagePort(m.port)
        m.channelStore.GetCatalog()
        print "[RokuPayTask] Catalog request sent"
    else
        print "[RokuPayTask] ERROR: Failed to create roChannelStore"
        m.top.errorMessage = "Failed to initialize Roku Pay"
    end if
end sub

' Handle commands from UI
sub handleCommand(command as string)
    print "[RokuPayTask] Received command: " + command

    if command = "getCatalog" then
        if m.channelStore <> invalid then
            m.channelStore.GetCatalog()
        end if

    else if command = "getPurchases" then
        if m.channelStore <> invalid then
            m.channelStore.GetPurchases()
        end if

    else if command = "purchase" then
        executePurchase()

    end if
end sub

' Execute purchase
sub executePurchase()
    productId = m.top.productId

    if productId = "" or productId = invalid then
        print "[RokuPayTask] ERROR: No product ID specified"
        m.top.errorMessage = "No product ID specified"
        return
    end if

    print "[RokuPayTask] ==================== EXECUTING PURCHASE ===================="
    print "[RokuPayTask] Product ID: " + productId

    channelStoreValid = "false"
    if m.channelStore <> invalid then channelStoreValid = "true"
    print "[RokuPayTask] Channel Store valid: " + channelStoreValid

    if m.channelStore <> invalid then
        ' Validate product exists in catalog
        productExists = validateProductInCatalog(productId)

        if not productExists then
            print "[RokuPayTask] ❌ ERROR: Product '" + productId + "' NOT FOUND in catalog!"
            print "[RokuPayTask] This product needs to be configured in Roku Developer Portal"
            print "[RokuPayTask] Steps to fix:"
            print "[RokuPayTask]   1. Go to https://developer.roku.com/"
            print "[RokuPayTask]   2. Select your channel"
            print "[RokuPayTask]   3. Go to 'Monetization' > 'In-Channel Products'"
            print "[RokuPayTask]   4. Add product with code: " + productId
            print "[RokuPayTask] ============================================================="

            m.top.errorMessage = "Product not found: " + productId
            m.top.purchaseResult = {
                success: false
                error: "Product '" + productId + "' not found in catalog. Please configure it in Roku Developer Portal."
                timestamp: CreateObject("roDateTime").AsSeconds()
            }
            return
        end if

        print "[RokuPayTask] ✅ Product validated - exists in catalog"
        print "[RokuPayTask] Calling SetOrder() to trigger Roku purchase dialog..."

        ' SetOrder() takes just the product code string
        ' This should show the Roku purchase confirmation dialog to the user
        m.channelStore.SetOrder(productId)

        print "[RokuPayTask] ✅ SetOrder() called successfully"
        print "[RokuPayTask] 📱 Roku purchase dialog should now be visible to the user"
        print "[RokuPayTask] ⏳ Waiting for user to complete or cancel the purchase..."
        print "[RokuPayTask] ============================================================="
    else
        print "[RokuPayTask] ❌ ERROR: Channel store not initialized"
        m.top.errorMessage = "Channel store not initialized"

        ' Set purchase result as failed
        m.top.purchaseResult = {
            success: false
            error: "Channel store not initialized"
            timestamp: CreateObject("roDateTime").AsSeconds()
        }
    end if
end sub

' Validate product exists in catalog
function validateProductInCatalog(productId as string) as boolean
    if m.catalog = invalid then
        print "[RokuPayTask] ⚠️ WARNING: Catalog not loaded yet, skipping validation"
        return true ' Assume it exists if catalog not loaded
    end if

    if m.catalog.Count() = 0 then
        print "[RokuPayTask] ⚠️ WARNING: Catalog is empty"
        return false
    end if

    ' Check if product exists in catalog
    for each product in m.catalog
        if product <> invalid and product.code <> invalid then
            if product.code = productId then
                print "[RokuPayTask] Product found: " + product.code + " - " + product.name
                return true
            end if
        end if
    end for

    return false
end function

' Handle messages from Roku Pay
sub handleMessage(msg as object)
    msgType = type(msg)
    print "[RokuPayTask] handleMessage called, message type: " + msgType

    if msgType = "roChannelStoreEvent" then
        print "[RokuPayTask] ========== CHANNEL STORE EVENT =========="
        print "[RokuPayTask] Received roChannelStoreEvent"

        if msg.isRequestSucceeded() then
            print "[RokuPayTask] ✅ Request SUCCEEDED"

            ' Check what type of request succeeded
            response = msg.GetResponse()
            if response <> invalid then
                responseType = type(response)
                print "[RokuPayTask] Response type: " + responseType

                ' Catalog response (array of products)
                if responseType = "roArray" then
                    catalogCount = stri(response.Count())
                    print "[RokuPayTask] ==================== CATALOG RECEIVED ===================="
                    print "[RokuPayTask] Total products in catalog: " + catalogCount

                    ' Store catalog for validation
                    m.catalog = response

                    ' Log all product IDs in catalog
                    if response.Count() > 0 then
                        print "[RokuPayTask] Available products:"
                        for i = 0 to response.Count() - 1
                            product = response[i]
                            if product <> invalid and product.code <> invalid then
                                print "[RokuPayTask]   - " + product.code + " (" + product.name + ")"
                            end if
                        end for
                    else
                        print "[RokuPayTask] ⚠️ WARNING: Catalog is EMPTY! No products configured!"
                        print "[RokuPayTask] You need to add products in Roku Developer Portal"
                    end if

                    print "[RokuPayTask] ============================================================"
                    m.top.catalogReady = true

                    ' Purchase response (associative array)
                else if responseType = "roAssociativeArray" then
                    print "[RokuPayTask] Response is associative array"

                    if response.DoesExist("transactionId") then
                        print "[RokuPayTask] ✅✅✅ PURCHASE SUCCESSFUL! ✅✅✅"
                        print "[RokuPayTask] Transaction ID: " + response.transactionId

                        ' Set purchase result with timestamp to force observer trigger
                        m.top.purchaseResult = {
                            success: true
                            transactionId: response.transactionId
                            timestamp: CreateObject("roDateTime").AsSeconds()
                        }

                        print "[RokuPayTask] Purchase result field set"
                    else
                        print "[RokuPayTask] Purchases list received (not a new purchase)"
                    end if
                end if
            else
                print "[RokuPayTask] WARNING: Response is invalid"
            end if

        else if msg.isRequestFailed() then
            print "[RokuPayTask] ❌ Request FAILED"

            errorMsg = "Request failed"
            status = msg.GetStatus()
            if status <> invalid then
                statusStr = stri(status)
                errorMsg = errorMsg + " (Status: " + statusStr + ")"
                print "[RokuPayTask] Failure status: " + statusStr
            end if

            print "[RokuPayTask] Error: " + errorMsg
            m.top.errorMessage = errorMsg

            ' Set purchase result as failed with timestamp
            m.top.purchaseResult = {
                success: false
                error: errorMsg
                timestamp: CreateObject("roDateTime").AsSeconds()
            }

            print "[RokuPayTask] Purchase result (failure) field set"

        else if msg.isRequestInterrupted() then
            print "[RokuPayTask] ⚠️ Request INTERRUPTED (user cancelled)"

            m.top.purchaseResult = {
                success: false
                cancelled: true
                timestamp: CreateObject("roDateTime").AsSeconds()
            }

            print "[RokuPayTask] Purchase result (cancelled) field set"

        else
            print "[RokuPayTask] Unknown request status"
        end if

        print "[RokuPayTask] ========================================"
    else
        print "[RokuPayTask] Non-ChannelStore message received: " + msgType
    end if
end sub

