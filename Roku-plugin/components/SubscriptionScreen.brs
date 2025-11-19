' ********** Account Screen Component **********
'
' Displays user account information and logout functionality

sub init()
    print "[SubscriptionScreen] Initializing..."

    ' Get UI references
    m.background = m.top.findNode("background")
    m.userInfoView = m.top.findNode("userInfoView")
    m.userEmail = m.top.findNode("userEmail")
    m.premiumBadge = m.top.findNode("premiumBadge")
    m.premiumStatusLabel = m.top.findNode("premiumStatusLabel")
    m.storageUsed = m.top.findNode("storageUsed")
    m.storageLimit = m.top.findNode("storageLimit")
    m.storageBarFill = m.top.findNode("storageBarFill")
    m.maxTorrents = m.top.findNode("maxTorrents")
    m.activeTorrents = m.top.findNode("activeTorrents")
    m.concurrentDownloads = m.top.findNode("concurrentDownloads")
    m.logoutButton = m.top.findNode("logoutButton")
    m.loadingLabel = m.top.findNode("loadingLabel")

    ' Set default values immediately
    if m.userEmail <> invalid then m.userEmail.text = "Loading..."
    if m.premiumStatusLabel <> invalid then m.premiumStatusLabel.text = "Free"
    if m.premiumBadge <> invalid then m.premiumBadge.color = "0x888888FF"
    if m.storageUsed <> invalid then m.storageUsed.text = "Used: 0 GB"
    if m.storageLimit <> invalid then m.storageLimit.text = "Total: 0 GB"
    if m.storageBarFill <> invalid then m.storageBarFill.width = 0
    if m.maxTorrents <> invalid then m.maxTorrents.text = "Max Torrents: 0"
    if m.activeTorrents <> invalid then m.activeTorrents.text = "Active Torrents: 0"
    if m.concurrentDownloads <> invalid then m.concurrentDownloads.text = "Concurrent Downloads: unlimited"

    ' Show account view
    if m.userInfoView <> invalid then m.userInfoView.visible = true
    if m.loadingLabel <> invalid then m.loadingLabel.visible = false
    if m.background <> invalid then m.background.visible = true

    ' Observe fields
    m.top.observeField("visible", "onVisibilityChange")

    ' Load user data
    loadUserData()

    print "[SubscriptionScreen] Initialization complete"
end sub


' Load user data from Seedr API
sub loadUserData()
    print "[SubscriptionScreen] Loading user data from Seedr API..."

    ' Create URL transfer task
    m.userDataTask = CreateObject("roSGNode", "ContentNode")
    m.userDataTask.addField("response", "string", false)

    ' Get auth token from registry
    authToken = getAuthToken()

    if authToken = invalid or authToken = "" then
        print "[SubscriptionScreen] ERROR: No auth token found"

        ' Set default values when not logged in
        if m.userEmail <> invalid then m.userEmail.text = "Not logged in"
        if m.premiumStatusLabel <> invalid then m.premiumStatusLabel.text = "Free"
        if m.premiumBadge <> invalid then m.premiumBadge.color = "0x888888FF"
        if m.storageUsed <> invalid then m.storageUsed.text = "Used: 0 GB"
        if m.storageLimit <> invalid then m.storageLimit.text = "Total: 0 GB"
        if m.storageBarFill <> invalid then m.storageBarFill.width = 0
        if m.maxTorrents <> invalid then m.maxTorrents.text = "Max Torrents: 0"
        if m.activeTorrents <> invalid then m.activeTorrents.text = "Active Torrents: 0"
        if m.concurrentDownloads <> invalid then m.concurrentDownloads.text = "Concurrent Downloads: unlimited"

        if m.viewPlansButton <> invalid then
            buttonText = m.viewPlansButton.findNode("viewPlansButtonText")
            if buttonText <> invalid then buttonText.text = "Get Premium"
        end if

        return
    end if

    ' Create URL transfer
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl("https://v2.seedr.cc/api/v0.1/p/user")
    urlTransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    urlTransfer.InitClientCertificates()
    urlTransfer.AddHeader("Authorization", "Bearer " + authToken)
    urlTransfer.AddHeader("Content-Type", "application/json")

    port = CreateObject("roMessagePort")
    urlTransfer.SetPort(port)

    if urlTransfer.AsyncGetToString() then
        print "[SubscriptionScreen] User data request sent"

        ' Wait for response (with timeout)
        timeout = 5000 ' 5 seconds
        msg = wait(timeout, port)

        if msg <> invalid then
            if type(msg) = "roUrlEvent" then
                if msg.GetResponseCode() = 200 then
                    responseString = msg.GetString()
                    print "[SubscriptionScreen] User data received"
                    parseUserData(responseString)
                else
                    print "[SubscriptionScreen] ERROR: API returned code " + str(msg.GetResponseCode())
                    showDefaultUserInfo("Error loading subscription data")
                end if
            end if
        else
            print "[SubscriptionScreen] ERROR: Request timed out"
            showDefaultUserInfo("Request timed out")
        end if
    else
        print "[SubscriptionScreen] ERROR: Failed to send request"
        showDefaultUserInfo("Failed to connect")
    end if
end sub

' Get auth token from registry
function getAuthToken() as string
    registry = CreateObject("roRegistrySection", "seedr")
    if registry.Exists("access_token") then
        return registry.Read("access_token")
    end if
    return ""
end function

' Parse user data response
sub parseUserData(responseString as string)
    json = ParseJson(responseString)

    if json <> invalid then
        m.userData = json
        print "[SubscriptionScreen] User data parsed successfully"
        displayUserInfo()
    else
        print "[SubscriptionScreen] ERROR: Failed to parse JSON"
        showDefaultUserInfo("Invalid response from server")
    end if
end sub

' Display user information
sub displayUserInfo()
    print "[SubscriptionScreen] Displaying user info..."

    if m.userData = invalid then
        return
    end if

    ' Display email
    if m.userData.profile <> invalid and m.userData.profile.email <> invalid then
        if m.userEmail <> invalid then m.userEmail.text = "Account: " + m.userData.profile.email
    end if

    ' Display premium status
    isPremium = false
    if m.userData.account <> invalid and m.userData.account.is_premium <> invalid then
        isPremium = m.userData.account.is_premium
    end if

    if isPremium then
        if m.premiumStatusLabel <> invalid then m.premiumStatusLabel.text = "Premium"
        if m.premiumBadge <> invalid then m.premiumBadge.color = "0x1DB954FF"
        if m.viewPlansButton <> invalid then
            buttonText = m.viewPlansButton.findNode("viewPlansButtonText")
            if buttonText <> invalid then buttonText.text = "Upgrade Plan"
        end if
    else
        if m.premiumStatusLabel <> invalid then m.premiumStatusLabel.text = "Free"
        if m.premiumBadge <> invalid then m.premiumBadge.color = "0x888888FF"
        if m.viewPlansButton <> invalid then
            buttonText = m.viewPlansButton.findNode("viewPlansButtonText")
            if buttonText <> invalid then buttonText.text = "Get Premium"
        end if
    end if

    ' Display storage info
    if m.userData.account <> invalid and m.userData.account.storage <> invalid then
        storage = m.userData.account.storage

        usedGB = formatBytes(storage.used)
        limitGB = formatBytes(storage.limit)

        if m.storageUsed <> invalid then m.storageUsed.text = "Used: " + usedGB
        if m.storageLimit <> invalid then m.storageLimit.text = "Total: " + limitGB

        ' Update progress bar
        if storage.limit > 0 and m.storageBarFill <> invalid then
            percentage = (storage.used / storage.limit)
            barWidth = int(1000 * percentage)
            if barWidth > 1000 then barWidth = 1000
            m.storageBarFill.width = barWidth

            ' Change color based on usage
            if percentage > 0.9 then
                m.storageBarFill.color = "0xFF0000FF" ' Red
            else if percentage > 0.7 then
                m.storageBarFill.color = "0xFFA500FF" ' Orange
            else
                m.storageBarFill.color = "0x1DB954FF" ' Green
            end if
        end if
    end if

    ' Display features
    if m.userData.account <> invalid and m.userData.account.features <> invalid then
        features = m.userData.account.features

        if features.max_torrents <> invalid and m.maxTorrents <> invalid then
            m.maxTorrents.text = "Max Torrents: " + str(features.max_torrents)
        end if

        if features.active_torrents <> invalid and m.activeTorrents <> invalid then
            m.activeTorrents.text = "Active Torrents: " + str(features.active_torrents)
        end if

        if features.concurrent_downloads <> invalid and m.concurrentDownloads <> invalid then
            m.concurrentDownloads.text = "Concurrent Downloads: " + str(features.concurrent_downloads)
        end if
    end if

    print "[SubscriptionScreen] User info displayed successfully"
end sub

' Display default user info (for errors or not logged in)
sub showDefaultUserInfo(errorMessage as string)
    print "[SubscriptionScreen] Showing default user info: " + errorMessage

    m.userEmail.text = errorMessage
    m.premiumStatusLabel.text = "Free"
    m.premiumBadge.color = "0x888888FF"
    m.storageUsed.text = "Used: 0 GB"
    m.storageLimit.text = "Total: 0 GB"
    m.storageBarFill.width = 0
    m.storageBarFill.color = "0x888888FF"
    m.maxTorrents.text = "Max Torrents: 0"
    m.activeTorrents.text = "Active Torrents: 0"
    m.concurrentDownloads.text = "Concurrent Downloads: unlimited"

end sub

' Format bytes to human readable
function formatBytes(bytes as longinteger) as string
    if bytes < 1024 then
        return str(bytes) + " B"
    else if bytes < 1048576 then ' 1024 * 1024
        return str(int(bytes / 1024)) + " KB"
    else if bytes < 1073741824 then ' 1024 * 1024 * 1024
        mb = bytes / 1048576
        return str(int(mb * 100) / 100) + " MB"
    else
        gb = bytes / 1073741824
        return str(int(gb * 100) / 100) + " GB"
    end if
end function


' Handle visibility changes
sub onVisibilityChange()
    isVisible = m.top.visible

    if isVisible then
        print "[SubscriptionScreen] Account screen visible"
        
        if m.background <> invalid then m.background.visible = true
        if m.userInfoView <> invalid then m.userInfoView.visible = true
        if m.loadingLabel <> invalid then m.loadingLabel.visible = false

        m.top.setFocus(true)
        
        print "[SubscriptionScreen] Account view shown"
    else
        print "[SubscriptionScreen] Screen hidden"
        if m.background <> invalid then m.background.visible = false
        if m.userInfoView <> invalid then m.userInfoView.visible = false
        if m.loadingLabel <> invalid then m.loadingLabel.visible = false
    end if
end sub

' Handle logout
sub handleLogout()
    print "[SubscriptionScreen] Logging out..."
    
    ' Show confirmation dialog
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Logout"
    dialog.message = ["Are you sure you want to logout?"]
    dialog.buttons = ["Yes", "Cancel"]
    dialog.observeField("buttonSelected", "onLogoutConfirm")
    
    ' Show dialog
    m.top.getScene().dialog = dialog
end sub

' Handle logout confirmation
sub onLogoutConfirm(event as object)
    dialog = event.getRoSGNode()
    buttonIndex = dialog.buttonSelected
    
    ' Close dialog
    m.top.getScene().dialog = invalid
    
    if buttonIndex = 0 then ' Yes button
        print "[SubscriptionScreen] User confirmed logout"
        
        ' Clear credentials
        clearCredentials()
        
        ' Show success message
        successDialog = CreateObject("roSGNode", "StandardMessageDialog")
        successDialog.title = "Logged Out"
        successDialog.message = ["You have been logged out successfully."]
        successDialog.buttons = ["OK"]
        successDialog.observeField("buttonSelected", "onLogoutComplete")
        m.top.getScene().dialog = successDialog
    else
        print "[SubscriptionScreen] Logout cancelled"
    end if
end sub

' Handle logout completion
sub onLogoutComplete()
    ' Close dialog
    m.top.getScene().dialog = invalid
    
    ' Restart the app by going back to auth screen
    m.top.backPressed = true
    m.top.visible = false
    
    ' Signal parent to show auth screen
    scene = m.top.getScene()
    if scene <> invalid then
        scene.showAuthScreen = true
    end if
end sub

' Handle key events
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    handled = false

    if key = "OK" then
        ' Logout button pressed
        print "[SubscriptionScreen] Logout button pressed"
        handleLogout()
        handled = true

    else if key = "back" then
        ' Return to previous screen
        print "[SubscriptionScreen] Back button pressed"
        m.top.backPressed = true
        m.top.visible = false
        handled = true
    end if

    return handled
end function
