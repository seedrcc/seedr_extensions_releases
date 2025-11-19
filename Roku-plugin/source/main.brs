' ********** Seedr for Roku - Main Entry Point **********

' Main function - entry point for the application
sub Main()
    ' Initialize global audio manager
    m.globalAudio = {
        player: CreateObject("roAudioPlayer")
        port: CreateObject("roMessagePort")
        playlist: []
        currentIndex: -1
        isPlaying: false
        isPaused: false
        currentTrack: invalid
        accessToken: ""
        folderPath: ""
    }

    ' Set up audio player message port
    if m.globalAudio.player <> invalid then
        m.globalAudio.player.SetMessagePort(m.globalAudio.port)
    end if

    ' Try to create SceneGraph screen first
    screen = CreateObject("roSGScreen")

    ' Check if SceneGraph is supported
    if screen <> invalid then
        ' SceneGraph is supported - use modern approach
        m.port = CreateObject("roMessagePort")
        screen.setMessagePort(m.port)

        ' Create and show the scene
        scene = screen.CreateScene("HeroMainScene")
        screen.show()

        ' Message loop
        while(true)
            msg = wait(0, m.port)
            msgType = type(msg)

            if msgType = "roSGScreenEvent"
                if msg.isScreenClosed() then return
            end if
        end while
    else
        ' SceneGraph not supported - use legacy approach
        print "SceneGraph not supported, using legacy screen approach"

        ' Create legacy screen
        screen = CreateObject("roScreen", true, 1280, 720)
        m.port = CreateObject("roMessagePort")
        screen.setMessagePort(m.port)

        ' Create compositor for rendering
        compositor = CreateObject("roCompositor")
        compositor.setDrawTo(screen, &h000000FF)

        ' Create a full-screen region to display app info
        region = CreateObject("roRegion", screen, 0, 0, 1280, 720)

        ' Draw background rectangle manually since setBackgroundColor doesn't exist
        region.drawRect(0, 0, 1280, 720, &h333333FF)

        ' Add some text
        font = CreateObject("roFontRegistry").getDefaultFont(24, false, false)
        if font <> invalid then
            region.drawText("Seedr for Roku", 50, 50, &hFFFFFFFF, font)
            region.drawText("Checking authentication...", 50, 100, &hFFFF00FF, font)
        else
            ' Fallback if font is not available
            region.drawText("Seedr for Roku", 50, 50, &hFFFFFFFF)
            region.drawText("Checking authentication...", 50, 100, &hFFFF00FF)
        end if

        ' Swap buffers to display the content
        screen.swapBuffers()

        ' Check authentication and start process if needed
        handleAuthentication(screen, region, font, m.globalAudio)

        ' Message loop for legacy screen
        while(true)
            msg = wait(0, m.port)
            if msg <> invalid
                msgType = type(msg)
                if msgType = "roUniversalControlEvent"
                    ' Handle remote control events
                    if msg.GetInt() = 0 then return ' Back button
                end if
            end if
        end while
    end if
end sub

' Handle Seedr authentication process
sub handleAuthentication(screen as object, region as object, font as object, globalAudio as object)
    print "[AUTH] Starting handleAuthentication()"

    ' Check if user already has valid credentials
    print "[AUTH] Checking for existing valid token..."
    if hasValidToken() then
        print "[AUTH] Valid token found - user already authenticated"
        ' User is already authenticated
        showKodiStyleAuthScreen(screen, region, font, "Already Authenticated", "Welcome back! Your Seedr account is connected.", "", "AUTHENTICATED")
        sleep(3000)
        print "[AUTH] Authentication check complete - proceeding to file browser"

        ' Load and display user's root folders
        print "[AUTH] Loading user's Seedr root folders..."
        showSeedrRootFolders(screen, region, font, globalAudio)
        return
    end if

    print "[AUTH] No valid token found - starting authentication process for first-time user"

    ' First time user - start authentication process
    showKodiStyleAuthScreen(screen, region, font, "Initializing", "Starting Seedr authentication process...", "", "INITIALIZING")
    sleep(1000)

    ' Request device code
    print "[AUTH] Requesting device code from Seedr API..."
    showKodiStyleAuthScreen(screen, region, font, "Connecting", "Requesting device code from Seedr...", "", "CONNECTING")

    deviceCodeResponse = requestDeviceCode()
    print "[AUTH] Device code response received:"
    if deviceCodeResponse <> invalid then
        print "[AUTH] Device code response is valid"
        if deviceCodeResponse.user_code <> invalid then
            print "[AUTH] User code: " + deviceCodeResponse.user_code
            if deviceCodeResponse.device_code <> invalid then
                print "[AUTH] Device code received (length: " + Str(Len(deviceCodeResponse.device_code)) + ")"
            end if
        end if
    else
        print "[AUTH] ERROR: Device code response is invalid"
    end if

    if deviceCodeResponse <> invalid and deviceCodeResponse.user_code <> invalid then
        ' Display authentication instructions in Kodi style
        print "[AUTH] Displaying authentication instructions to user"

        ' authUrl = "https://www.seedr.cc/devices"
        API_URL = "https://v2.seedr.cc"
        BASE_URL = API_URL + "/api/v0.1/p"
        DEVICE_CODE_URL = API_URL + "/api/v0.1/p/oauth/device/code"
        authUrl = API_URL + "/api/v0.1/p/oauth/device/verify"
        TOKEN_URL = API_URL + "/api/v0.1/p/oauth/device/token"
        userCode = deviceCodeResponse.user_code
        fullAuthUrl = authUrl + "?code=" + userCode

        print "[AUTH] User instructions displayed - Auth URL: " + authUrl
        print "[AUTH] User code: " + userCode
        print "[AUTH] Full URL: " + fullAuthUrl

        ' Display the URL for user access (simplified like working examples)
        print "[AUTH] Displaying auth URL for user browser access"
        showKodiStyleAuthScreen(screen, region, font, "Seedr Authentication Required", "Please visit this URL in your web browser:", fullAuthUrl, "PLEASE_VISIT")

        ' Give user 30 seconds to see and access the URL
        sleep(30000)

        print "[AUTH] Starting clean polling process (based on seeds.sh/main.py patterns)..."
        showKodiStyleAuthScreen(screen, region, font, "Waiting for Authorization", "Please complete authorization in your browser...", "This may take up to 2 minutes", "POLLING")

        ' Clean polling logic based on working examples
        deviceCode = deviceCodeResponse.device_code
        maxAttempts = 30 ' Like main.py - 30 attempts max
        attempts = 0
        currentInterval = 5 ' Start with 5 seconds like seeds.sh

        ' Calculate timeout (2 minutes total like seeds.sh)
        startTime = CreateObject("roDateTime").AsSeconds()
        maxPollingTime = 120 ' 2 minutes in seconds
        endTime = startTime + maxPollingTime

        print "[AUTH] Starting polling - will continue for 2 minutes maximum"
        print "[AUTH] Verification URL: " + fullAuthUrl

        while attempts < maxAttempts
            ' Check for timeout (like seeds.sh)
            currentTime = CreateObject("roDateTime").AsSeconds()
            if currentTime >= endTime then
                print "[AUTH] Polling timed out after 2 minutes"
                exit while
            end if

            attempts = attempts + 1
            timeRemaining = endTime - currentTime
            ' print "[AUTH] Polling attempt " + Str(attempts) + "/" + Str(maxAttempts) + " - " + Str(timeRemaining) + " seconds remaining"

            ' Update UI with progress
            showKodiStyleAuthScreen(screen, region, font, "Checking Authorization", "Attempt " + Str(attempts) + " of " + Str(maxAttempts), Str(timeRemaining) + " seconds remaining", "POLLING")

            tokenResponse = pollForToken(deviceCode)
            print "[AUTH] Poll response received"

            if tokenResponse <> invalid then
                print "[AUTH] Token response is valid"
                if tokenResponse.access_token <> invalid then
                    print "[AUTH] SUCCESS: Access token received!"
                    print "[AUTH] Saving credentials to registry..."

                    ' Authentication successful!
                    saveCredentials(tokenResponse.access_token, tokenResponse.refresh_token)
                    print "[AUTH] Credentials saved successfully"

                    showKodiStyleAuthScreen(screen, region, font, "Success!", "Authentication completed successfully!", "Your Seedr account is now connected.", "SUCCESS")
                    sleep(3000)
                    print "[AUTH] Authentication process completed successfully"

                    ' Proceed to show user's Seedr folders
                    print "[AUTH] Loading user's Seedr root folders..."
                    showSeedrRootFolders(screen, region, font, globalAudio)
                    return
                else if tokenResponse.error <> invalid then
                    print "[AUTH] Error in token response: " + tokenResponse.error
                    if tokenResponse.error = "authorization_pending" then
                        print "[AUTH] Authorization still pending - continuing to poll"
                        ' Continue polling - this is normal

                    else if tokenResponse.error = "slow_down" then
                        print "[AUTH] Rate limit hit - increasing polling interval"
                        currentInterval = currentInterval + 5 ' Increase interval like seeds.sh
                        showKodiStyleAuthScreen(screen, region, font, "Please Wait", "Slowing down requests as requested", "", "WAITING")

                    else if tokenResponse.error = "expired_token" or tokenResponse.error = "access_denied" then
                        ' Terminal errors (like seeds.sh) - stop polling
                        print "[AUTH] TERMINAL ERROR: " + tokenResponse.error
                        showKodiStyleAuthScreen(screen, region, font, "Authentication Failed", "Error: " + tokenResponse.error, "Please restart and try again", "ERROR")
                        sleep(5000)
                        return

                    else
                        ' Other unexpected OAuth error
                        print "[AUTH] Unexpected OAuth error: " + tokenResponse.error
                        showKodiStyleAuthScreen(screen, region, font, "Authentication Error", "Error: " + tokenResponse.error, "Retrying...", "ERROR")
                    end if
                else
                    print "[AUTH] WARNING: Token response valid but no access_token or error field"
                end if
            else
                print "[AUTH] WARNING: Token response is invalid - network issue?"
            end if

            ' Wait before next attempt (using current interval like seeds.sh)
            print "[AUTH] Waiting " + Str(currentInterval) + " seconds before next attempt..."
            sleep(currentInterval * 1000)
        end while

        ' Handle timeout/max attempts reached (like working examples)
        print "[AUTH] Authentication timed out after " + Str(attempts) + " attempts"
        showKodiStyleAuthScreen(screen, region, font, "Authentication Timeout", "Failed to complete authorization in 2 minutes", "Please restart the app and try again", "TIMEOUT")
        sleep(5000)
    else
        print "[AUTH] FATAL ERROR: Could not get device code from Seedr API"
        showKodiStyleAuthScreen(screen, region, font, "Connection Error", "Could not connect to Seedr API", "Please check your internet connection", "ERROR")
        sleep(5000)
    end if

    print "[AUTH] handleAuthentication() completed"
end sub

' Kodi-style authentication display
sub showKodiStyleAuthScreen(screen as object, region as object, font as object, title as string, message as string, url as string, status as string)
    print "[DISPLAY] Updating display - Title: " + title + ", Status: " + status

    ' Clear the entire screen with Kodi pure black background
    region.drawRect(0, 0, 1280, 720, &h000000FF)

    ' Define dialog dimensions (centered on screen)
    dialogWidth = 800
    dialogHeight = 400
    dialogX = (1280 - dialogWidth) / 2 ' Center horizontally
    dialogY = (720 - dialogHeight) / 2 ' Center vertically

    ' Draw Kodi-style dialog with shadow and background
    region.drawRect(dialogX + 5, dialogY + 5, dialogWidth, dialogHeight, &h80000000) ' Drop shadow
    region.drawRect(dialogX, dialogY, dialogWidth, dialogHeight, &h1a1a1aFF) ' Dark charcoal background

    ' Define Kodi-style colors based on status
    titleColor = &hFFFFFFFF ' Pure white
    messageColor = &hCCCCCCFF ' Light gray
    urlColor = &h00ADEFFF ' Kodi blue
    statusColor = &h00ADEFFF ' Kodi blue

    if status = "ERROR" then
        titleColor = &hFF4444FF ' Red
        statusColor = &hFF4444FF
    else if status = "SUCCESS" then
        titleColor = &h00FF00FF ' Bright green
        statusColor = &h00FF00FF
    else if status = "AUTHENTICATED" then
        titleColor = &h00FF00FF ' Bright green
        statusColor = &h00FF00FF
    end if

    ' Get font sizes
    if font <> invalid then
        titleFont = CreateObject("roFontRegistry").getDefaultFont(32, true, false) ' Larger title
        messageFont = CreateObject("roFontRegistry").getDefaultFont(24, false, false)
        urlFont = CreateObject("roFontRegistry").getDefaultFont(20, false, false)
        statusFont = CreateObject("roFontRegistry").getDefaultFont(18, false, false)
        if titleFont = invalid then titleFont = font
        if messageFont = invalid then messageFont = font
        if urlFont = invalid then urlFont = font
        if statusFont = invalid then statusFont = font
    else
        titleFont = invalid
        messageFont = invalid
        urlFont = invalid
        statusFont = invalid
    end if

    ' Calculate text positions relative to dialog
    textX = dialogX + 40
    titleY = dialogY + 50
    messageY = dialogY + 120
    urlY = dialogY + 180

    ' Draw title (larger, colored based on status)
    if titleFont <> invalid then
        region.drawText(title, textX, titleY, titleColor, titleFont)
    else
        region.drawText(title, textX, titleY, titleColor)
    end if

    ' Draw main message
    if messageFont <> invalid then
        region.drawText(message, textX, messageY, messageColor, messageFont)
    else
        region.drawText(message, textX, messageY, messageColor)
    end if

    ' Draw URL if provided (in cyan, like Kodi)
    if url <> "" then
        if urlFont <> invalid then
            region.drawText(url, textX, urlY, urlColor, urlFont)
        else
            region.drawText(url, textX, urlY, urlColor)
        end if
    end if

    ' Draw loading animation for LOADING status
    if status = "LOADING" then
        drawLoadingAnimation(region, dialogX + dialogWidth / 2, dialogY + 200, statusFont)
    end if

    ' Draw status indicator at bottom
    statusY = dialogY + 280
    statusText = ""
    if status = "WAITING" then
        statusText = "Waiting for authorization..."
    else if status = "CONNECTING" then
        statusText = "Connecting to Seedr..."
    else if status = "SUCCESS" then
        statusText = "Success!"
    else if status = "ERROR" then
        statusText = "Error occurred"
    else if status = "AUTHENTICATED" then
        statusText = "Already connected"
    else if status = "INITIALIZING" then
        statusText = "Initializing..."
    else if status = "PLEASE_VISIT" then
        statusText = "Please visit the URL above in your web browser"
    else if status = "CHECKING" then
        statusText = "Checking your authorization status..."
    else if status = "LOADING" then
        statusText = "Loading..."
    else if Left(status, 15) = "TIME_REMAINING:" then
        timeRemaining = Mid(status, 16)
        statusText = "Time remaining: " + timeRemaining
    end if

    if statusText <> "" then
        if statusFont <> invalid then
            region.drawText(statusText, textX, statusY, statusColor, statusFont)
        else
            region.drawText(statusText, textX, statusY, statusColor)
        end if
    end if

    ' Draw authentic Kodi dialog border
    borderThickness = 2
    ' Top border - Kodi blue
    region.drawRect(dialogX, dialogY, dialogWidth, borderThickness, &h0078d4FF)
    ' Bottom border
    region.drawRect(dialogX, dialogY + dialogHeight - borderThickness, dialogWidth, borderThickness, &h0078d4FF)
    ' Left border
    region.drawRect(dialogX, dialogY, borderThickness, dialogHeight, &h0078d4FF)
    ' Right border
    region.drawRect(dialogX + dialogWidth - borderThickness, dialogY, borderThickness, dialogHeight, &h0078d4FF)

    ' Add inner glow for depth
    region.drawRect(dialogX + 2, dialogY + 2, dialogWidth - 4, 1, &h40FFFFFF) ' Top inner highlight

    ' Update the display
    screen.swapBuffers()
    print "[DISPLAY] Display updated successfully"
end sub

' Draw beautiful loading animation (inspired by loader.png)
sub drawLoadingAnimation(region as object, centerX as integer, centerY as integer, font as object)
    ' Get current time for animation
    currentTime = CreateObject("roDateTime").AsSeconds()
    animationFrame = currentTime mod 8 ' 8-frame animation

    ' Beautiful teal loading spinner
    spinnerSize = 40
    spinnerX = centerX - spinnerSize / 2
    spinnerY = centerY - spinnerSize / 2

    ' Draw animated loading rings (like loader.png concept)
    for ring = 0 to 2
        ringRadius = 15 + (ring * 8)
        ringOpacity = &h80 - (ring * &h20) ' Fade outer rings

        ' Calculate ring color with opacity
        ringColor = &h00E5D6FF ' Cyan base
        if ring = 1 then ringColor = &h17A2B8FF ' Teal
        if ring = 2 then ringColor = &h2C6E7AFF ' Light teal

        ' Draw ring segments with animation
        for segment = 0 to 7
            segmentAngle = (segment + animationFrame) mod 8
            if segmentAngle < 4 then ' Only show half the segments for spinning effect
                segmentX = centerX + (ringRadius * (segment mod 3 - 1)) / 3
                segmentY = centerY + (ringRadius * (segment \ 3 - 1)) / 3
                region.drawRect(segmentX - 2, segmentY - 2, 4, 4, ringColor)
            end if
        end for
    end for

    ' Draw central loading dot
    region.drawRect(centerX - 3, centerY - 3, 6, 6, &h00E5D6FF)

    ' Draw loading text below spinner
    if animationFrame mod 4 = 0 then
        loadingText = "Loading."
    else if animationFrame mod 4 = 1 then
        loadingText = "Loading.."
    else if animationFrame mod 4 = 2 then
        loadingText = "Loading..."
    else
        loadingText = "Loading"
    end if

    ' Center the loading text
    textWidth = Len(loadingText) * 8 ' Approximate character width
    textX = centerX - textWidth / 2
    if font <> invalid then
        region.drawText(loadingText, textX, centerY + 30, &h00E5D6FF, font)
    else
        ' Skip text if no font available
        print "[DISPLAY] No font available for loading text"
    end if
end sub

' Helper function to update the display (legacy - kept for compatibility)
sub updateDisplay(screen as object, region as object, font as object, line1 as string, line2 as string)
    showKodiStyleAuthScreen(screen, region, font, line1, line2, "", "")
end sub

' Display Seedr root folders and files
sub showSeedrRootFolders(screen as object, region as object, font as object, globalAudio as object)
    print "[FOLDERS] Starting showSeedrRootFolders()"

    ' Show loading screen
    showKodiStyleAuthScreen(screen, region, font, "Loading Your Files", "Fetching your Seedr files and folders...", "", "LOADING")

    ' Get user credentials
    credentials = loadCredentials()
    if credentials = invalid then
        print "[FOLDERS] ERROR: No credentials found"
        showKodiStyleAuthScreen(screen, region, font, "Error", "Authentication required", "Please restart the app", "ERROR")
        sleep(5000)
        return
    end if

    ' Fetch root folder contents
    print "[FOLDERS] Fetching root folder contents with access token"
    rootContents = getRootFolderContents(credentials.accessToken)

    if rootContents = invalid then
        print "[FOLDERS] ERROR: Failed to fetch root contents"
        showKodiStyleAuthScreen(screen, region, font, "Connection Error", "Could not load your files", "Please check your internet connection", "ERROR")
        sleep(5000)
        return
    end if

    print "[FOLDERS] Root contents received successfully"

    ' Display the folder/file browser
    showFolderBrowserWithNavigation(screen, region, font, rootContents, "Home", credentials.accessToken, globalAudio)
end sub

' Display folder browser with files and folders
sub showFolderBrowser(screen as object, region as object, font as object, contents as object, currentPath as string)
    print "[FOLDERS] Displaying folder browser for path: " + currentPath

    ' Clear screen with dark background
    region.drawRect(0, 0, 1280, 720, &h000000FF)

    ' Get fonts
    if font <> invalid then
        titleFont = CreateObject("roFontRegistry").getDefaultFont(28, true, false)
        itemFont = CreateObject("roFontRegistry").getDefaultFont(20, false, false)
        pathFont = CreateObject("roFontRegistry").getDefaultFont(16, false, false)
        if titleFont = invalid then titleFont = font
        if itemFont = invalid then itemFont = font
        if pathFont = invalid then pathFont = font
    else
        titleFont = invalid
        itemFont = invalid
        pathFont = invalid
    end if

    ' Colors
    titleColor = &hFFFFFFFF
    pathColor = &hCCCCCCFF
    folderColor = &h4A90E2FF ' Blue for folders
    fileColor = &hFFFFFFFF ' White for files
    selectedColor = &hFFFF00FF ' Yellow for selection

    ' Draw header
    if titleFont <> invalid then
        region.drawText("Seedr Files", 40, 30, titleColor, titleFont)
    else
        region.drawText("Seedr Files", 40, 30, titleColor)
    end if

    ' Draw current path
    if pathFont <> invalid then
        region.drawText("Current: " + currentPath, 40, 70, pathColor, pathFont)
    else
        region.drawText("Current: " + currentPath, 40, 70, pathColor)
    end if

    ' Draw separator line
    region.drawRect(40, 100, 1200, 2, &h333333FF)

    ' Process and display contents
    if contents <> invalid and contents.files <> invalid then
        print "[FOLDERS] Processing " + Str(contents.files.count()) + " items"

        itemY = 120
        itemHeight = 35
        maxItems = 15 ' Limit to 15 items visible

        for i = 0 to contents.files.count() - 1
            if i >= maxItems then exit for

            item = contents.files[i]
            itemName = ""
            itemType = ""

            if item.name <> invalid then
                itemName = item.name
            end if

            ' Determine item type
            if item.folder_file_id <> invalid then
                itemType = "folder"
                itemColor = folderColor
                itemPrefix = "📁 "
            else
                itemType = "file"
                itemColor = fileColor
                itemPrefix = "📄 "

                ' Add file size if available
                if item.size <> invalid then
                    itemName = itemName + " (" + formatFileSize(item.size) + ")"
                end if
            end if

            ' Draw item
            displayText = itemPrefix + itemName
            if itemFont <> invalid then
                region.drawText(displayText, 60, itemY, itemColor, itemFont)
            else
                region.drawText(displayText, 60, itemY, itemColor)
            end if

            itemY = itemY + itemHeight
            print "[FOLDERS] Item " + Str(i + 1) + ": " + itemType + " - " + itemName
        end for

        if contents.files.count() > maxItems then
            moreText = "... and " + Str(contents.files.count() - maxItems) + " more items"
            if pathFont <> invalid then
                region.drawText(moreText, 60, itemY + 20, pathColor, pathFont)
            else
                region.drawText(moreText, 60, itemY + 20, pathColor)
            end if
        end if
    else
        print "[FOLDERS] No contents to display"
        if itemFont <> invalid then
            region.drawText("No files or folders found", 60, 150, &h888888FF, itemFont)
        else
            region.drawText("No files or folders found", 60, 150, &h888888FF)
        end if
    end if

    ' Draw instructions
    instructionsY = 600
    if pathFont <> invalid then
        region.drawText("Press BACK button to exit", 40, instructionsY, pathColor, pathFont)
        region.drawText("Navigate with UP/DOWN arrows (future feature)", 40, instructionsY + 25, pathColor, pathFont)
    else
        region.drawText("Press BACK button to exit", 40, instructionsY, pathColor)
        region.drawText("Navigate with UP/DOWN arrows (future feature)", 40, instructionsY + 25, pathColor)
    end if

    ' Update display
    screen.swapBuffers()
    print "[FOLDERS] Folder browser display updated"
end sub

' Interactive folder browser with navigation and playback
sub showFolderBrowserWithNavigation(screen as object, region as object, font as object, contents as object, currentPath as string, accessToken as string, globalAudio as object)
    print "[FOLDERS] Starting interactive folder browser for path: " + currentPath

    if contents = invalid then
        print "[FOLDERS] No contents to display"
        showKodiStyleAuthScreen(screen, region, font, "Empty Folder", "No contents found", "Press BACK to return", "EMPTY")
        return
    end if

    ' Combine folders and files into a single list for unified browsing (like main.py)
    allItems = []

    ' Add folders first (like in main.py)
    if contents.folders <> invalid then
        print "[FOLDERS] Found " + Str(contents.folders.count()) + " folders"
        for each folder in contents.folders
            if folder <> invalid then
                folder.itemType = "folder"
                allItems.push(folder)
            end if
        end for
    end if

    ' Add files after folders (like in main.py)
    if contents.files <> invalid then
        print "[FOLDERS] Found " + Str(contents.files.count()) + " files"
        for each file in contents.files
            if file <> invalid then
                file.itemType = "file"
                allItems.push(file)
            end if
        end for
    end if

    if allItems.count() = 0 then
        print "[FOLDERS] No items to display"
        showKodiStyleAuthScreen(screen, region, font, "Empty Folder", "No files or folders found", "Press BACK to return", "EMPTY")
        return
    end if

    selectedIndex = 0
    itemsPerPage = 11
    currentPage = 0
    totalItems = allItems.count()

    print "[FOLDERS] Total items to display: " + Str(totalItems)

    ' Main navigation loop
    while true
        ' Check for global audio events first
        checkGlobalAudioEvents(globalAudio)
        ' Display current page
        drawFolderPage(screen, region, font, allItems, selectedIndex, currentPath, currentPage, itemsPerPage, globalAudio)

        ' Wait for user input
        msg = wait(0, screen.GetMessagePort())
        if msg <> invalid then
            msgType = type(msg)
            if msgType = "roUniversalControlEvent" then
                key = msg.GetInt()
                print "[FOLDERS] Key pressed: " + Str(key)

                if key = 2 then ' Up arrow
                    if selectedIndex > 0 then
                        selectedIndex = selectedIndex - 1
                        if selectedIndex < currentPage * itemsPerPage then
                            currentPage = currentPage - 1
                        end if
                    end if

                else if key = 3 then ' Down arrow
                    if selectedIndex < totalItems - 1 then
                        selectedIndex = selectedIndex + 1
                        if selectedIndex >= (currentPage + 1) * itemsPerPage then
                            currentPage = currentPage + 1
                        end if
                    end if

                else if key = 6 then ' OK/Select button
                    selectedItem = allItems[selectedIndex]

                    ' Safely get item name for logging
                    itemDisplayName = "Unknown Item"
                    if selectedItem.name <> invalid then
                        itemDisplayName = selectedItem.name
                    else if selectedItem.path <> invalid then
                        itemDisplayName = selectedItem.path
                    end if

                    print "[FOLDERS] Selected item: " + itemDisplayName
                    print "[FOLDERS] Selected item data: " + FormatJson(selectedItem)

                    if selectedItem.itemType = "folder" then
                        ' It's a folder - navigate into it
                        print "[FOLDERS] Opening folder: " + itemDisplayName

                        ' Show animated loading screen
                        for animFrame = 0 to 5 ' Show animation for about 1.5 seconds
                            showKodiStyleAuthScreen(screen, region, font, "Loading Folder", "Opening " + itemDisplayName + "...", "", "LOADING")
                            sleep(300) ' 300ms per frame
                        end for

                        ' Load folder contents using folder ID
                        folderId = FormatJson(selectedItem.id)
                        print "[FOLDERS] Loading folder ID: " + folderId
                        folderContents = getFolderContents(folderId, accessToken)

                        if folderContents <> invalid then
                            ' Recursively navigate into the folder
                            newPath = currentPath + " > " + itemDisplayName
                            showFolderBrowserWithNavigation(screen, region, font, folderContents, newPath, accessToken, globalAudio)
                        else
                            print "[FOLDERS] ERROR: Failed to load folder contents"
                            showKodiStyleAuthScreen(screen, region, font, "Error", "Could not load folder: " + itemDisplayName, "Press OK to continue", "ERROR")
                            wait(3000, screen.GetMessagePort())
                        end if

                    else if selectedItem.id <> invalid then
                        ' It's a file - check if playable
                        fileName = itemDisplayName
                        print "[FOLDERS] File ID: " + FormatJson(selectedItem.id)
                        print "[FOLDERS] Raw File ID value: " + FormatJson(selectedItem.id)

                        if isVideoFile(fileName) then
                            print "[FOLDERS] Playing video file: " + fileName
                            playVideoFile(screen, region, font, selectedItem, accessToken)
                        else if isAudioFile(fileName) then
                            print "[FOLDERS] Playing audio file: " + fileName
                            playGlobalAudioFile(screen, region, font, selectedItem, accessToken, globalAudio, allItems, selectedIndex, currentPath)
                        else
                            print "[FOLDERS] File not playable: " + fileName
                            showKodiStyleAuthScreen(screen, region, font, "Cannot Play File", "File type not supported: " + fileName, "Press OK to continue", "INFO")
                            wait(3000, screen.GetMessagePort())
                        end if
                    else
                        print "[FOLDERS] ERROR: Could not determine item type - no folder_file_id or id found"
                        showKodiStyleAuthScreen(screen, region, font, "Item Error", "Could not determine if item is file or folder", "Press OK to continue", "ERROR")
                        wait(3000, screen.GetMessagePort())
                    end if

                else if key = 0 then ' Back button
                    print "[FOLDERS] Back button pressed - exiting folder browser"
                    return

                    ' Global audio controls
                else if key = 13 then ' Play/Pause (OK when not on item)
                    if selectedIndex < 0 or selectedIndex >= totalItems then
                        toggleGlobalAudioPlayPause(globalAudio)
                    end if

                else if key = 8 then ' Replay/Previous (usually *)
                    playPreviousTrack(globalAudio)

                else if key = 9 then ' Fast Forward/Next (usually #)
                    playNextTrack(globalAudio)

                end if
            end if
        end if
    end while
end sub

' Draw a beautiful Kodi-style two-panel interface
sub drawFolderPage(screen as object, region as object, font as object, allItems as object, selectedIndex as integer, currentPath as string, currentPage as integer, itemsPerPage as integer, globalAudio as object)
    ' Clear screen with authentic Kodi-style black background
    region.drawRect(0, 0, 1280, 720, &h000000FF) ' Pure black background like Kodi

    ' Draw Kodi-style gradient background overlay for depth
    region.drawRect(0, 0, 1280, 100, &h2a2a2aFF) ' Dark gray header area
    region.drawRect(0, 100, 1280, 620, &h1a1a1aFF) ' Charcoal main area

    ' Add subtle ambient lighting effect
    region.drawRect(0, 0, 1280, 720, &h10000000) ' Subtle dark overlay for depth

    ' Get fonts with proper hierarchy
    if font <> invalid then
        headerFont = CreateObject("roFontRegistry").getDefaultFont(36, true, false)
        titleFont = CreateObject("roFontRegistry").getDefaultFont(28, true, false)
        itemFont = CreateObject("roFontRegistry").getDefaultFont(24, false, false)
        detailFont = CreateObject("roFontRegistry").getDefaultFont(20, false, false)
        infoFont = CreateObject("roFontRegistry").getDefaultFont(18, false, false)
        smallFont = CreateObject("roFontRegistry").getDefaultFont(16, false, false)
        if headerFont = invalid then headerFont = font
        if titleFont = invalid then titleFont = font
        if itemFont = invalid then itemFont = font
        if detailFont = invalid then detailFont = font
        if infoFont = invalid then infoFont = font
        if smallFont = invalid then smallFont = font
    else
        headerFont = invalid
        titleFont = invalid
        itemFont = invalid
        detailFont = invalid
        infoFont = invalid
        smallFont = invalid
    end if

    ' Authentic Kodi dark theme color palette
    primaryText = &hFFFFFFFF ' Pure white
    secondaryText = &hCCCCCCFF ' Light gray
    accentText = &h00ADEFFF ' Bright blue accent
    folderColor = &h0078d4FF ' Kodi blue folders
    videoColor = &hFF6B6BFF ' Coral videos
    audioColor = &h20C997FF ' Emerald audio
    imageColor = &hFFC107FF ' Amber images
    textColor = &hCCCCCCFF ' Light gray text files
    selectedBg = &h0078d4FF ' Kodi blue selection
    selectedText = &hFFFFFFFF ' Pure white on blue
    panelBorder = &h333333FF ' Dark gray panel borders
    panelBg = &h1a1a1aFF ' Dark charcoal panel background

    ' === HEADER SECTION ===
    ' Draw main title with Kodi-style styling
    if headerFont <> invalid then
        region.drawText("Seedr", 40, 25, accentText, headerFont)
        region.drawText("Files", 180, 25, primaryText, headerFont)
    else
        region.drawText("Seedr Files", 40, 25, primaryText)
    end if

    ' Draw breadcrumb path with modern styling
    if infoFont <> invalid then
        region.drawText("📁 " + currentPath + " • " + Str(allItems.count()) + " items", 40, 65, secondaryText, infoFont)
    else
        region.drawText("📁 " + currentPath + " (" + Str(allItems.count()) + " items)", 40, 65, secondaryText)
    end if

    ' Draw audio status if playing
    drawAudioStatus(region, globalAudio, infoFont, primaryText, accentText, secondaryText)

    ' Draw header separator with gradient effect
    region.drawRect(0, 95, 1280, 3, panelBorder)
    region.drawRect(0, 98, 1280, 1, &h555555FF) ' Highlight

    ' === TWO-PANEL LAYOUT ===
    ' Define panel dimensions
    previewPanelX = 40
    previewPanelY = 120
    previewPanelW = 420
    previewPanelH = 480

    listPanelX = 480
    listPanelY = 120
    listPanelW = 760
    listPanelH = 480

    ' Draw panel shadows first (Kodi-style drop shadows)
    region.drawRect(previewPanelX + 3, previewPanelY + 5, previewPanelW + 4, previewPanelH + 4, &h80000000) ' Shadow
    region.drawRect(listPanelX + 3, listPanelY + 5, listPanelW + 4, listPanelH + 4, &h80000000) ' Shadow

    ' Draw panel borders with authentic Kodi-style depth
    region.drawRect(previewPanelX - 2, previewPanelY - 2, previewPanelW + 4, previewPanelH + 4, panelBorder)
    region.drawRect(previewPanelX, previewPanelY, previewPanelW, previewPanelH, panelBg)

    region.drawRect(listPanelX - 2, listPanelY - 2, listPanelW + 4, listPanelH + 4, panelBorder)
    region.drawRect(listPanelX, listPanelY, listPanelW, listPanelH, panelBg)

    ' Add Kodi-style inner highlights for depth
    region.drawRect(previewPanelX + 1, previewPanelY + 1, previewPanelW - 2, 1, &h19555555) ' Subtle white highlight
    region.drawRect(listPanelX + 1, listPanelY + 1, listPanelW - 2, 1, &h19555555) ' Subtle white highlight

    ' === PREVIEW PANEL CONTENT ===
    ' Get currently selected item for preview
    selectedItem = invalid
    if selectedIndex >= 0 and selectedIndex < allItems.count() then
        selectedItem = allItems[selectedIndex]
    end if

    ' Draw preview content
    drawPreviewPanel(region, selectedItem, previewPanelX, previewPanelY, previewPanelW, previewPanelH, titleFont, itemFont, detailFont, infoFont, primaryText, secondaryText, accentText)

    ' === FILE LIST PANEL ===
    ' Calculate page bounds for file list
    startIndex = currentPage * itemsPerPage
    endIndex = startIndex + itemsPerPage - 1
    if endIndex >= allItems.count() then endIndex = allItems.count() - 1

    ' Draw file list with modern styling
    itemY = listPanelY + 20
    itemHeight = 40
    itemsVisible = 0
    maxItemY = listPanelY + listPanelH - 10 ' Reduced safety margin from panel bottom

    for i = startIndex to endIndex
        if itemsVisible >= itemsPerPage then exit for
        if itemY + itemHeight > maxItemY then exit for ' Prevent overlap

        item = allItems[i]

        ' Safely get item name with fallback
        if item.name <> invalid then
            itemName = item.name
        else if item.path <> invalid then
            itemName = item.path
        else
            itemName = "Unknown Item"
        end if

        ' Determine item type, color, and icon
        itemColor = textColor
        itemIcon = "📄"
        typeLabel = "FILE"

        if item.itemType = "folder" then
            itemColor = folderColor
            itemIcon = "📁"
            typeLabel = "FOLDER"
        else if isVideoFile(itemName) then
            itemColor = &hFF6B6BFF ' Coral videos
            itemIcon = "🎬"
            typeLabel = "VIDEO"
        else if isAudioFile(itemName) then
            itemColor = &h20C997FF ' Emerald audio
            itemIcon = "🎵"
            typeLabel = "AUDIO"
        else if isImageFile(itemName) then
            itemColor = &hFFC107FF ' Amber images
            itemIcon = "🖼️"
            typeLabel = "IMAGE"
        end if

        ' Calculate item rectangle for selection highlight
        itemRect = {
            x: listPanelX + 10
            y: itemY - 8
            w: listPanelW - 20
            h: itemHeight - 2
        }

        ' Draw selection highlight with authentic Kodi-style glow
        if i = selectedIndex then
            ' Outer blue glow effect (Kodi signature)
            region.drawRect(itemRect.x - 3, itemRect.y - 3, itemRect.w + 6, itemRect.h + 6, &h400078d4) ' Blue glow
            region.drawRect(itemRect.x - 1, itemRect.y - 1, itemRect.w + 2, itemRect.h + 2, &h800078d4) ' Stronger inner glow
            ' Main Kodi blue selection background
            region.drawRect(itemRect.x, itemRect.y, itemRect.w, itemRect.h, selectedBg)
            textColor = selectedText
            iconColor = selectedText
        else
            textColor = itemColor
            iconColor = itemColor
        end if

        ' Draw item icon
        if itemFont <> invalid then
            region.drawText(itemIcon, itemRect.x + 15, itemY, iconColor, itemFont)
        else
            region.drawText(itemIcon, itemRect.x + 15, itemY, iconColor)
        end if

        ' Draw item name (truncated if too long)
        nameX = itemRect.x + 60
        maxNameWidth = 400
        displayName = itemName
        if Len(displayName) > 45 then displayName = Left(displayName, 42) + "..."

        if itemFont <> invalid then
            region.drawText(displayName, nameX, itemY, textColor, itemFont)
        else
            region.drawText(displayName, nameX, itemY, textColor)
        end if

        ' Draw file size/type info
        infoX = itemRect.x + itemRect.w - 120
        infoText = ""
        if item.itemType = "file" and item.size <> invalid then
            infoText = formatFileSize(item.size)
        else if item.itemType = "folder" then
            infoText = typeLabel
        end if

        if infoText <> "" and smallFont <> invalid then
            region.drawText(infoText, infoX, itemY + 2, secondaryText, smallFont)
        else if infoText <> "" then
            region.drawText(infoText, infoX, itemY + 2, secondaryText)
        end if

        itemY = itemY + itemHeight
        itemsVisible = itemsVisible + 1
    end for

    ' === FOOTER SECTION ===
    footerY = 620

    ' Draw footer background with Kodi dark styling
    region.drawRect(0, footerY - 10, 1280, 70, &h2a2a2aFF)
    region.drawRect(0, footerY - 12, 1280, 2, panelBorder)
    region.drawRect(0, footerY - 10, 1280, 1, &h0078d4FF) ' Blue highlight line

    ' Draw page indicator with modern styling (fix decimal issue)
    if allItems.count() > itemsPerPage then
        totalPages = Int((allItems.count() + itemsPerPage - 1) / itemsPerPage)
        pageInfo = "Page " + Str(currentPage + 1) + " of " + Str(totalPages) + " • " + Str(allItems.count()) + " total items"
        if infoFont <> invalid then
            region.drawText("📄 " + pageInfo, 40, footerY, secondaryText, infoFont)
        else
            region.drawText("📄 " + pageInfo, 40, footerY, secondaryText)
        end if
    end if

    ' Draw modern control instructions
    controls = "⬆⬇ Navigate • ⚪ Select • ⬅ Back • Seedr for Roku"
    if infoFont <> invalid then
        region.drawText(controls, 40, footerY + 25, accentText, infoFont)
    else
        region.drawText(controls, 40, footerY + 25, accentText)
    end if

    ' Update display
    screen.swapBuffers()
end sub

' Draw the preview panel with thumbnails and file information
sub drawPreviewPanel(region as object, item as object, panelX as integer, panelY as integer, panelW as integer, panelH as integer, titleFont as object, itemFont as object, detailFont as object, infoFont as object, primaryText as integer, secondaryText as integer, accentText as integer)
    if item = invalid then
        ' No item selected - show welcome message
        drawWelcomePreview(region, panelX, panelY, panelW, panelH, titleFont, itemFont, primaryText, secondaryText, accentText)
        return
    end if

    ' Get item information
    itemName = "Unknown Item"
    if item.name <> invalid then
        itemName = item.name
    else if item.path <> invalid then
        itemName = item.path
    end if

    ' Determine content type for preview
    if item.itemType = "folder" then
        drawFolderPreview(region, item, itemName, panelX, panelY, panelW, panelH, titleFont, itemFont, detailFont, infoFont, primaryText, secondaryText, accentText)
    else if isVideoFile(itemName) then
        drawVideoPreview(region, item, itemName, panelX, panelY, panelW, panelH, titleFont, itemFont, detailFont, infoFont, primaryText, secondaryText, accentText)
    else if isAudioFile(itemName) then
        drawAudioPreview(region, item, itemName, panelX, panelY, panelW, panelH, titleFont, itemFont, detailFont, infoFont, primaryText, secondaryText, accentText)
    else if isImageFile(itemName) then
        drawImagePreview(region, item, itemName, panelX, panelY, panelW, panelH, titleFont, itemFont, detailFont, infoFont, primaryText, secondaryText, accentText)
    else
        drawFilePreview(region, item, itemName, panelX, panelY, panelW, panelH, titleFont, itemFont, detailFont, infoFont, primaryText, secondaryText, accentText)
    end if
end sub

' Draw welcome message when no item is selected
sub drawWelcomePreview(region as object, panelX as integer, panelY as integer, panelW as integer, panelH as integer, titleFont as object, itemFont as object, primaryText as integer, secondaryText as integer, accentText as integer)
    centerX = panelX + panelW / 2
    centerY = panelY + panelH / 2

    ' Draw welcome background with authentic Kodi styling
    region.drawRect(panelX + 20, panelY + 60, panelW - 40, panelH - 120, &h1a1a1aFF)
    region.drawRect(panelX + 22, panelY + 62, panelW - 44, 2, &h0078d4FF) ' Top blue highlight
    region.drawRect(panelX + 22, panelY + panelH - 62, panelW - 44, 2, &h333333FF) ' Bottom gray highlight

    ' Draw welcome icon with glow effect
    if titleFont <> invalid then
        region.drawText("🌱", centerX - 30, centerY - 80, accentText, titleFont)
        ' Add Kodi-style blue glow effect
        region.drawText("🌱", centerX - 31, centerY - 81, &h400078d4, titleFont)
    end if

    ' Draw welcome text with better styling
    if itemFont <> invalid then
        region.drawText("Welcome to Seedr", centerX - 100, centerY - 40, primaryText, itemFont)
        region.drawText("Select a file to preview", centerX - 110, centerY - 10, secondaryText, itemFont)
        region.drawText("Beautiful media browsing", centerX - 120, centerY + 20, accentText, itemFont)
    else
        region.drawText("Welcome to Seedr", centerX - 100, centerY - 40, primaryText)
        region.drawText("Select a file to preview", centerX - 110, centerY - 10, secondaryText)
    end if
end sub

' Draw folder preview
sub drawFolderPreview(region as object, item as object, itemName as string, panelX as integer, panelY as integer, panelW as integer, panelH as integer, titleFont as object, itemFont as object, detailFont as object, infoFont as object, primaryText as integer, secondaryText as integer, accentText as integer)
    ' Draw large folder icon
    iconX = panelX + 150
    iconY = panelY + 80

    ' Draw folder graphic using Kodi blue colors
    region.drawRect(iconX, iconY, 120, 100, &h0078d4FF) ' Main folder - Kodi blue
    region.drawRect(iconX + 10, iconY - 15, 40, 15, &h0078d4FF) ' Folder tab
    region.drawRect(iconX + 5, iconY + 5, 110, 90, &h4A90E2FF) ' Inner folder - lighter blue

    ' Draw folder details
    textY = iconY + 120
    if titleFont <> invalid then
        region.drawText("📁 FOLDER", panelX + 20, textY, accentText, titleFont)
    end if

    textY = textY + 40
    if itemFont <> invalid then
        ' Truncate long folder names
        displayName = itemName
        if Len(displayName) > 25 then displayName = Left(displayName, 22) + "..."
        region.drawText(displayName, panelX + 20, textY, primaryText, itemFont)
    end if

    textY = textY + 40
    if detailFont <> invalid then
        if item.size <> invalid then
            region.drawText("Size: " + formatFileSize(item.size), panelX + 20, textY, secondaryText, detailFont)
        end if

        if item.last_update <> invalid then
            region.drawText("Modified: " + Left(item.last_update, 10), panelX + 20, textY + 25, secondaryText, detailFont)
        end if
    end if
end sub

' Draw video preview with movie poster if available
sub drawVideoPreview(region as object, item as object, itemName as string, panelX as integer, panelY as integer, panelW as integer, panelH as integer, titleFont as object, itemFont as object, detailFont as object, infoFont as object, primaryText as integer, secondaryText as integer, accentText as integer)
    ' Check for thumbnail from Seedr API
    thumbnailUrl = ""
    if item.presentation_urls <> invalid and item.presentation_urls.image <> invalid then
        imageUrls = item.presentation_urls.image
        if imageUrls["720"] <> invalid then
            thumbnailUrl = imageUrls["720"]
        else if imageUrls["220"] <> invalid then
            thumbnailUrl = imageUrls["220"]
        else if imageUrls["64"] <> invalid then
            thumbnailUrl = imageUrls["64"]
        end if
    end if

    ' Draw poster area
    posterX = panelX + 50
    posterY = panelY + 50
    posterW = 200
    posterH = 280

    if thumbnailUrl <> "" then
        ' Load actual thumbnail with fallback
        loadedImage = loadImageWithFallback(thumbnailUrl)
        if loadedImage <> invalid then
            ' Draw the loaded image
            region.drawRect(posterX, posterY, posterW, posterH, &h000000FF) ' Black background
            ' TODO: Draw actual bitmap when image loading is fully implemented
            if infoFont <> invalid then
                region.drawText("🖼️ LOADED", posterX + 60, posterY + 120, accentText, infoFont)
                region.drawText("THUMBNAIL", posterX + 50, posterY + 140, secondaryText, infoFont)
                region.drawText("READY", posterX + 75, posterY + 160, accentText, infoFont)
            end if
        else
            ' Show loader.png fallback
            drawLoaderFallback(region, posterX, posterY, posterW, posterH, infoFont, accentText, secondaryText)
        end if
    else
        ' Draw video icon placeholder with Kodi styling
        region.drawRect(posterX, posterY, posterW, posterH, &h1a1a1aFF) ' Dark charcoal background
        region.drawRect(posterX + 5, posterY + 5, posterW - 10, posterH - 10, &h333333FF) ' Gray inner frame
        if titleFont <> invalid then
            region.drawText("🎬", posterX + 80, posterY + 120, &hFF6B6BFF, titleFont)
        end if
        if infoFont <> invalid then
            region.drawText("NO POSTER", posterX + 50, posterY + 160, &hCCCCCCFF, infoFont)
        end if
    end if

    ' Draw video details
    textY = posterY + posterH + 20
    if titleFont <> invalid then
        region.drawText("🎬 VIDEO", panelX + 20, textY, &hFF6B6BFF, titleFont)
    end if

    textY = textY + 40
    if itemFont <> invalid then
        ' Truncate long video names
        displayName = itemName
        if Len(displayName) > 20 then displayName = Left(displayName, 17) + "..."
        region.drawText(displayName, panelX + 20, textY, primaryText, itemFont)
    end if

    textY = textY + 40
    if detailFont <> invalid then
        if item.size <> invalid then
            region.drawText("Size: " + formatFileSize(item.size), panelX + 20, textY, secondaryText, detailFont)
        end if

        ' Show video quality info if available
        if InStr(1, itemName, "720p") > 0 then
            region.drawText("Quality: 720p HD", panelX + 20, textY + 25, accentText, detailFont)
        else if InStr(1, itemName, "1080p") > 0 then
            region.drawText("Quality: 1080p FHD", panelX + 20, textY + 25, accentText, detailFont)
        else if InStr(1, itemName, "480p") > 0 then
            region.drawText("Quality: 480p SD", panelX + 20, textY + 25, secondaryText, detailFont)
        end if
    end if
end sub

' Draw audio preview with album art placeholder
sub drawAudioPreview(region as object, item as object, itemName as string, panelX as integer, panelY as integer, panelW as integer, panelH as integer, titleFont as object, itemFont as object, detailFont as object, infoFont as object, primaryText as integer, secondaryText as integer, accentText as integer)
    ' Draw album art area
    artX = panelX + 90
    artY = panelY + 60
    artSize = 200

    region.drawRect(artX, artY, artSize, artSize, &h333333FF)

    ' Draw music note icon
    noteX = artX + artSize / 2 - 20
    noteY = artY + artSize / 2 - 30
    region.drawRect(noteX, noteY, 8, 40, &h4ECDC4FF)
    region.drawRect(noteX + 8, noteY, 20, 15, &h4ECDC4FF)
    region.drawRect(noteX + 28, noteY + 15, 8, 25, &h4ECDC4FF)
    region.drawRect(noteX + 20, noteY + 25, 16, 8, &h4ECDC4FF)

    ' Draw audio details
    textY = artY + artSize + 30
    if titleFont <> invalid then
        region.drawText("🎵 AUDIO", panelX + 20, textY, &h4ECDC4FF, titleFont)
    end if

    textY = textY + 40
    if itemFont <> invalid then
        displayName = itemName
        if Len(displayName) > 22 then displayName = Left(displayName, 19) + "..."
        region.drawText(displayName, panelX + 20, textY, primaryText, itemFont)
    end if

    textY = textY + 40
    if detailFont <> invalid then
        if item.size <> invalid then
            region.drawText("Size: " + formatFileSize(item.size), panelX + 20, textY, secondaryText, detailFont)
        end if

        ' Show audio format
        if Right(LCase(itemName), 4) = ".mp3" then
            region.drawText("Format: MP3", panelX + 20, textY + 25, accentText, detailFont)
        else if Right(LCase(itemName), 5) = ".flac" then
            region.drawText("Format: FLAC Lossless", panelX + 20, textY + 25, accentText, detailFont)
        end if
    end if
end sub

' Draw image preview
sub drawImagePreview(region as object, item as object, itemName as string, panelX as integer, panelY as integer, panelW as integer, panelH as integer, titleFont as object, itemFont as object, detailFont as object, infoFont as object, primaryText as integer, secondaryText as integer, accentText as integer)
    ' Draw image preview area
    imgX = panelX + 60
    imgY = panelY + 50
    imgW = 280
    imgH = 200

    region.drawRect(imgX, imgY, imgW, imgH, &h333333FF)

    ' Draw image icon
    if titleFont <> invalid then
        region.drawText("🖼️", imgX + imgW / 2 - 20, imgY + imgH / 2 - 20, &hFFB347FF, titleFont)
    end if

    ' Draw image details
    textY = imgY + imgH + 30
    if titleFont <> invalid then
        region.drawText("🖼️ IMAGE", panelX + 20, textY, &hFFB347FF, titleFont)
    end if

    textY = textY + 40
    if itemFont <> invalid then
        displayName = itemName
        if Len(displayName) > 22 then displayName = Left(displayName, 19) + "..."
        region.drawText(displayName, panelX + 20, textY, primaryText, itemFont)
    end if

    textY = textY + 40
    if detailFont <> invalid then
        if item.size <> invalid then
            region.drawText("Size: " + formatFileSize(item.size), panelX + 20, textY, secondaryText, detailFont)
        end if

        ' Show image format
        extension = Right(LCase(itemName), 4)
        if extension = ".jpg" or extension = "jpeg" then
            region.drawText("Format: JPEG", panelX + 20, textY + 25, accentText, detailFont)
        else if extension = ".png" then
            region.drawText("Format: PNG", panelX + 20, textY + 25, accentText, detailFont)
        end if
    end if
end sub

' Draw generic file preview
sub drawFilePreview(region as object, item as object, itemName as string, panelX as integer, panelY as integer, panelW as integer, panelH as integer, titleFont as object, itemFont as object, detailFont as object, infoFont as object, primaryText as integer, secondaryText as integer, accentText as integer)
    ' Draw file icon
    iconX = panelX + 150
    iconY = panelY + 100

    region.drawRect(iconX, iconY, 80, 100, &hBBBBBBFF)
    region.drawRect(iconX + 60, iconY, 20, 20, &hBBBBBBFF)

    if titleFont <> invalid then
        region.drawText("📄", iconX + 25, iconY + 130, &hBBBBBBFF, titleFont)
    end if

    ' Draw file details
    textY = iconY + 150
    if titleFont <> invalid then
        region.drawText("📄 FILE", panelX + 20, textY, &hBBBBBBFF, titleFont)
    end if

    textY = textY + 40
    if itemFont <> invalid then
        displayName = itemName
        if Len(displayName) > 22 then displayName = Left(displayName, 19) + "..."
        region.drawText(displayName, panelX + 20, textY, primaryText, itemFont)
    end if

    textY = textY + 40
    if detailFont <> invalid then
        if item.size <> invalid then
            region.drawText("Size: " + formatFileSize(item.size), panelX + 20, textY, secondaryText, detailFont)
        end if
    end if
end sub

' Play video file using Roku's built-in video player
sub playVideoFile(screen as object, region as object, font as object, fileItem as object, accessToken as string)
    print "[PLAYER] Starting video playback for: " + fileItem.name

    ' Show loading screen
    showKodiStyleAuthScreen(screen, region, font, "Loading Video", "Getting video stream for " + fileItem.name, "", "LOADING")

    ' Get video streaming URL from Seedr using HLS endpoint
    fileIdValue = invalid
    if fileItem.id <> invalid then
        fileIdValue = fileItem.id
    else if fileItem.file_id <> invalid then
        fileIdValue = fileItem.file_id
    else
        print "[PLAYER] ERROR: No file ID found in fileItem for video"
        showKodiStyleAuthScreen(screen, region, font, "Playback Error", "No file ID found", "Press OK to continue", "ERROR")
        wait(3000, screen.GetMessagePort())
        return
    end if

    ' Convert using FormatJson to preserve precision for large integers
    fileId = FormatJson(fileIdValue)

    print "[PLAYER] Video File ID: " + fileId
    streamUrl = getVideoStreamUrl(fileId, accessToken)

    if streamUrl = "" then
        print "[PLAYER] ERROR: Could not get video stream URL"
        print "[PLAYER] Trying to get file details for debugging..."
        fileDetails = getFileDetails(fileId, accessToken)
        if fileDetails <> invalid then
            print "[PLAYER] File details: " + FormatJson(fileDetails)
        end if
        showKodiStyleAuthScreen(screen, region, font, "Playback Error", "Could not get video stream URL", "Press OK to continue", "ERROR")
        wait(3000, screen.GetMessagePort())
        return
    end if

    print "[PLAYER] Video stream URL obtained: " + Left(streamUrl, 50) + "..."

    ' Create video player
    videoPlayer = CreateObject("roVideoScreen")
    if videoPlayer = invalid then
        ' Simulator fallback - show mock video player
        print "[PLAYER] Video player not available in simulator - showing mock player"
        showMockVideoPlayer(screen, region, font, fileItem, streamUrl)
        return
    end if

    port = CreateObject("roMessagePort")
    videoPlayer.SetMessagePort(port)

    ' Set video content
    videoContent = {
        Stream: { url: streamUrl }
        Title: fileItem.name
        Description: "Playing from Seedr"
        StreamFormat: "hls"
    }

    print "[PLAYER] Starting video playback..."
    videoPlayer.SetContent(videoContent)
    videoPlayer.Show()

    ' Handle video player events
    while true
        msg = wait(0, port)
        if msg <> invalid then
            if type(msg) = "roVideoScreenEvent" then
                print "[PLAYER] Video event: " + Str(msg.GetType())
                if msg.isScreenClosed() then
                    print "[PLAYER] Video player closed"
                    exit while
                end if
            end if
        end if
    end while

    ' Close video player
    videoPlayer.Close()
    print "[PLAYER] Video playback completed"
end sub

' Play audio file using Roku's built-in audio player
sub playAudioFile(screen as object, region as object, font as object, fileItem as object, accessToken as string)
    print "[PLAYER] Starting audio playback for: " + fileItem.name

    ' Show loading screen
    showKodiStyleAuthScreen(screen, region, font, "Loading Audio", "Getting audio stream for " + fileItem.name, "", "LOADING")

    ' Use the download API endpoint like in Kodi example
    ' API endpoint: /api/v0.1/p/download/file/{file_id}/url
    fileIdValue = invalid
    if fileItem.id <> invalid then
        fileIdValue = fileItem.id
    else if fileItem.file_id <> invalid then
        fileIdValue = fileItem.file_id
    else
        print "[PLAYER] ERROR: No file ID found in fileItem"
        showKodiStyleAuthScreen(screen, region, font, "Playback Error", "No file ID found", "Press OK to continue", "ERROR")
        wait(3000, screen.GetMessagePort())
        return
    end if

    ' Convert using FormatJson to preserve precision for large integers
    fileId = FormatJson(fileIdValue)

    downloadEndpoint = "/api/v0.1/p/download/file/" + fileId + "/url"
    print "[PLAYER] Using download API endpoint: " + downloadEndpoint
    print "[PLAYER] File ID: " + fileId

    audioUrlResponse = makeApiRequest(downloadEndpoint, accessToken, "GET")

    if audioUrlResponse = invalid or audioUrlResponse.url = invalid then
        print "[PLAYER] ERROR: Could not get audio download URL from API"
        print "[PLAYER] API Response: " + FormatJson(audioUrlResponse)
        showKodiStyleAuthScreen(screen, region, font, "Playback Error", "Could not get audio stream URL", "Press OK to continue", "ERROR")
        wait(3000, screen.GetMessagePort())
        return
    end if

    streamUrl = audioUrlResponse.url
    print "[PLAYER] Audio download URL obtained: " + Left(streamUrl, 50) + "..."

    ' Create audio player
    audioPlayer = CreateObject("roAudioPlayer")
    port = CreateObject("roMessagePort")
    audioPlayer.SetMessagePort(port)

    ' Set audio content - roAudioPlayer uses SetContentList with an array
    audioContent = {
        url: streamUrl
        Title: fileItem.name
        Artist: "Seedr"
        Album: "My Files"
        StreamFormat: "mp3" ' Add stream format for better compatibility
    }

    print "[PLAYER] Starting audio playback..."
    print "[PLAYER] Audio content: " + FormatJson(audioContent)
    audioPlayer.SetContentList([audioContent]) ' SetContentList expects an array
    audioPlayer.Play()

    ' Show audio player UI using SceneGraph component
    showSceneGraphAudioPlayer(screen, region, font, fileItem, streamUrl, audioPlayer, port)

    ' Stop and close audio player
    audioPlayer.Stop()
    print "[PLAYER] Audio playback completed"
end sub

' Show SceneGraph-based audio player with album art support
sub showSceneGraphAudioPlayer(screen as object, region as object, font as object, fileItem as object, streamUrl as string, audioPlayer as object, port as object)
    print "[PLAYER] Starting SceneGraph audio player"

    ' Create SceneGraph screen if it doesn't exist
    sgScreen = CreateObject("roSGScreen")
    if sgScreen = invalid then
        print "[PLAYER] SceneGraph not available, falling back to legacy UI"
        showAudioPlayerUI(screen, region, font, fileItem.name, audioPlayer, port)
        return
    end if

    ' Set up SceneGraph
    sgScreen.show()
    scene = sgScreen.CreateScene("AudioPlayer")
    sgScreen.SetScene(scene)

    ' Set basic track information
    scene.fileName = fileItem.name
    scene.artist = "Seedr"
    scene.album = "My Files"
    scene.duration = 248 ' Default duration, could be extracted from metadata
    scene.isPlaying = true

    ' Try to get album art from file metadata or API
    albumArtUrl = getAlbumArt(fileItem, streamUrl)
    if albumArtUrl <> invalid and albumArtUrl <> "" then
        print "[PLAYER] Setting album art: " + albumArtUrl
        scene.albumArt = albumArtUrl
    else
        print "[PLAYER] No album art available"
        scene.albumArt = ""
    end if

    ' Set up message port for SceneGraph
    sgPort = CreateObject("roMessagePort")
    sgScreen.setMessagePort(sgPort)

    ' Main event loop
    while true
        msg = wait(100, sgPort)
        if msg <> invalid then
            msgType = type(msg)
            if msgType = "roSGScreenEvent" then
                if msg.isScreenClosed() then
                    print "[PLAYER] Screen closed"
                    exit while
                end if
            end if
        end if

        ' Check if back button was pressed in the component
        if scene.onBackPressed then
            print "[PLAYER] Back button pressed in audio player"
            exit while
        end if

        ' Check for audio player events from the legacy audio player
        audioMsg = wait(0, port)
        if audioMsg <> invalid then
            audioMsgType = type(audioMsg)
            if audioMsgType = "roAudioPlayerEvent" then
                print "[PLAYER] Audio player event received"
                ' Handle audio events here if needed
            end if
        end if
    end while

    ' Clean up
    sgScreen.close()
    print "[PLAYER] SceneGraph audio player closed"
end sub

' Get album art from file metadata or API
function getAlbumArt(fileItem as object, streamUrl as string) as string
    print "[PLAYER] Attempting to get album art for: " + fileItem.name

    ' Check if the API provides album art URL
    if fileItem.DoesExist("album_art") and fileItem.album_art <> invalid and fileItem.album_art <> "" then
        print "[PLAYER] Album art found in file metadata: " + fileItem.album_art
        return fileItem.album_art
    end if

    ' Check for presentation_urls that might contain album art
    if fileItem.DoesExist("presentation_urls") and fileItem.presentation_urls <> invalid then
        if Type(fileItem.presentation_urls) = "roArray" and fileItem.presentation_urls.Count() > 0 then
            for each url in fileItem.presentation_urls
                if Type(url) = "roString" then
                    ' Check if URL looks like an image
                    urlLower = LCase(url)
                    if urlLower.InStr(".jpg") > -1 or urlLower.InStr(".jpeg") > -1 or urlLower.InStr(".png") > -1 or urlLower.InStr("thumb") > -1 or urlLower.InStr("cover") > -1 then
                        print "[PLAYER] Found potential album art in presentation_urls: " + url
                        return url
                    end if
                end if
            end for
        end if
    end if

    ' Try to extract album art from the audio stream URL (some services provide it)
    if streamUrl <> invalid and streamUrl <> "" then
        ' Look for album art in the stream URL parameters
        if streamUrl.InStr("cover") > -1 or streamUrl.InStr("thumb") > -1 or streamUrl.InStr("art") > -1 then
            print "[PLAYER] Stream URL might contain album art reference"
            ' Could potentially construct album art URL from stream URL
        end if
    end if

    ' Check if there's a folder-level album art (common for albums)
    if fileItem.DoesExist("folder_id") and fileItem.folder_id <> invalid then
        ' Could make API call to get folder metadata which might have album art
        print "[PLAYER] Could check folder " + Str(fileItem.folder_id) + " for album art"
    end if

    ' Default: no album art found
    print "[PLAYER] No album art found for this track"
    return ""
end function

' Show audio player UI with controls
sub showAudioPlayerUI(screen as object, region as object, font as object, fileName as string, audioPlayer as object, port as object)
    print "[PLAYER] Showing audio player UI"

    ' Validate required parameters for legacy UI
    if screen = invalid or region = invalid then
        print "[PLAYER] ERROR: Invalid screen or region parameters - cannot show legacy UI"
        print "[PLAYER] This likely means the simulator doesn't support the legacy screen approach either"
        print "[PLAYER] Audio will play in background without visual UI"

        ' Just wait for audio to finish or user input without UI
        while true
            audioMsg = wait(1000, port)
            if audioMsg <> invalid then
                audioMsgType = type(audioMsg)
                if audioMsgType = "roAudioPlayerEvent" then
                    print "[PLAYER] Audio player event received"
                    ' Audio finished or other event - exit
                    return
                end if
            end if
        end while
        return
    end if

    ' Initialize playback timer for progress simulation
    startTime = CreateObject("roDateTime").AsSeconds()
    totalDuration = 248 ' 4:08 for demo (could be extracted from file metadata)

    while true
        ' Calculate elapsed time for progress bar
        currentTime = CreateObject("roDateTime").AsSeconds()
        elapsed = currentTime - startTime
        if elapsed > totalDuration then elapsed = totalDuration

        ' Draw authentic Kodi-style audio player UI
        region.drawRect(0, 0, 1280, 720, &h000000FF) ' Pure black background like Kodi

        ' Draw Kodi-style gradient background overlay for depth
        region.drawRect(0, 0, 1280, 400, &h1a1a1aFF)

        ' Get fonts for different UI elements
        if font <> invalid then
            bigTitleFont = CreateObject("roFontRegistry").getDefaultFont(42, true, false)
            titleFont = CreateObject("roFontRegistry").getDefaultFont(28, true, false)
            infoFont = CreateObject("roFontRegistry").getDefaultFont(22, false, false)
            smallFont = CreateObject("roFontRegistry").getDefaultFont(18, false, false)
            if bigTitleFont = invalid then bigTitleFont = font
            if titleFont = invalid then titleFont = font
            if infoFont = invalid then infoFont = font
            if smallFont = invalid then smallFont = font
        else
            bigTitleFont = invalid
            titleFont = invalid
            infoFont = invalid
            smallFont = invalid
        end if

        ' Draw "Now playing..." header (top left)
        if smallFont <> invalid then
            region.drawText("Now playing...", 50, 30, &hBBBBBBFF, smallFont)
            region.drawText("Track 1 / 1", 50, 55, &h888888FF, smallFont)
        end if

        ' Draw album art placeholder (left side)
        artX = 80
        artY = 120
        artSize = 200
        region.drawRect(artX, artY, artSize, artSize, &h333333FF) ' Dark gray placeholder

        ' Draw music note icon in album art
        ' Simple music note using rectangles
        noteX = artX + artSize / 2 - 20
        noteY = artY + artSize / 2 - 30
        region.drawRect(noteX, noteY, 8, 40, &hFFFFFFFF) ' Vertical line
        region.drawRect(noteX + 8, noteY, 20, 15, &hFFFFFFFF) ' Note head
        region.drawRect(noteX + 28, noteY + 15, 8, 25, &hFFFFFFFF) ' Second line
        region.drawRect(noteX + 20, noteY + 25, 16, 8, &hFFFFFFFF) ' Connecting beam

        ' Track title (right of album art)
        trackX = artX + artSize + 40
        trackY = artY + 20

        if titleFont <> invalid then
            region.drawText(fileName, trackX, trackY, &hFFFFFFFF, titleFont)
        else
            region.drawText(fileName, trackX, trackY, &hFFFFFFFF)
        end if

        ' Artist and source info
        if infoFont <> invalid then
            region.drawText("Seedr", trackX, trackY + 45, &hBBBBBBFF, infoFont)
            region.drawText("My Files", trackX, trackY + 75, &h888888FF, infoFont)
        end if

        ' Star rating placeholder (like Kodi)
        starY = trackY + 110
        for i = 0 to 4
            starX = trackX + (i * 25)
            ' Draw simple star outline
            region.drawRect(starX, starY, 20, 20, &h444444FF)
            region.drawText("★", starX + 2, starY - 2, &h666666FF, infoFont)
        end for

        ' Progress bar (bottom area)
        progressY = 520
        progressBarX = 80
        progressBarWidth = 1120
        progressBarHeight = 8

        ' Background of progress bar
        region.drawRect(progressBarX, progressY, progressBarWidth, progressBarHeight, &h444444FF)

        ' Progress fill with Kodi blue
        progressPercent = elapsed / totalDuration
        if progressPercent > 1 then progressPercent = 1
        progressFillWidth = progressBarWidth * progressPercent
        region.drawRect(progressBarX, progressY, progressFillWidth, progressBarHeight, &h0078d4FF) ' Kodi blue progress

        ' Time display
        timeY = progressY + 25
        if smallFont <> invalid then
            ' Format elapsed time
            elapsedMin = elapsed / 60
            elapsedSec = elapsed - (elapsedMin * 60)
            elapsedStr = Right("0" + Str(elapsedMin), 2) + ":" + Right("0" + Str(elapsedSec), 2)

            ' Format total time
            totalMin = totalDuration / 60
            totalSec = totalDuration - (totalMin * 60)
            totalStr = Right("0" + Str(totalMin), 2) + ":" + Right("0" + Str(totalSec), 2)

            region.drawText(elapsedStr + " / " + totalStr, progressBarX, timeY, &hBBBBBBFF, smallFont)
        end if

        ' Control instructions (bottom right)
        controlsX = 850
        controlsY = 580
        if smallFont <> invalid then
            region.drawText("⏯ Play/Pause    ⏪⏩ Seek    ⏹ Stop    ⚙ Settings", controlsX, controlsY, &h888888FF, smallFont)
        end if

        ' Update display
        screen.swapBuffers()

        ' Wait for user input
        msg = wait(1000, port) ' 1 second timeout to allow UI updates
        if msg <> invalid then
            msgType = type(msg)
            if msgType = "roUniversalControlEvent" then
                key = msg.GetInt()
                print "[PLAYER] Audio control key: " + Str(key)

                if key = 13 then ' Play/Pause
                    if audioPlayer.GetState() = "playing" then
                        audioPlayer.Pause()
                        print "[PLAYER] Audio paused"
                    else
                        audioPlayer.Resume()
                        print "[PLAYER] Audio resumed"
                    end if

                else if key = 4 then ' Left arrow (rewind)
                    audioPlayer.Seek(-10000) ' Seek back 10 seconds
                    print "[PLAYER] Audio seek backward"

                else if key = 5 then ' Right arrow (fast forward)
                    audioPlayer.Seek(10000) ' Seek forward 10 seconds
                    print "[PLAYER] Audio seek forward"

                else if key = 0 then ' Back button
                    print "[PLAYER] Back button pressed - stopping audio"
                    return
                end if

            else if msgType = "roAudioPlayerEvent" then
                ' Audio player event received - just log it
                print "[PLAYER] Audio player event received"
                ' Note: In brs-desktop simulator, most audio player methods are not available
                ' On real Roku devices, you could check audioPlayer.GetState() here
                ' For now, just continue the UI loop
            end if
        end if
    end while
end sub

' Show mock video player for simulator testing
sub showMockVideoPlayer(screen as object, region as object, font as object, fileItem as object, streamUrl as string)
    print "[MOCK PLAYER] Starting mock video player for: " + fileItem.name
    print "[MOCK PLAYER] Stream URL: " + streamUrl

    ' Create mock playback timer
    totalDuration = 3600 ' 1 hour mock duration
    startTime = CreateObject("roDateTime").AsSeconds()
    isPaused = false
    currentPosition = 0

    while true
        ' Calculate mock playback progress
        if not isPaused then
            currentTime = CreateObject("roDateTime").AsSeconds()
            currentPosition = (currentTime - startTime) * 10 ' 10x speed for demo
            if currentPosition > totalDuration then currentPosition = totalDuration
        end if

        ' Draw authentic Kodi-style video player interface
        region.drawRect(0, 0, 1280, 720, &h000000FF) ' Pure black background like Kodi

        ' Get fonts
        if font <> invalid then
            titleFont = CreateObject("roFontRegistry").getDefaultFont(32, true, false)
            timeFont = CreateObject("roFontRegistry").getDefaultFont(24, false, false)
            infoFont = CreateObject("roFontRegistry").getDefaultFont(20, false, false)
            if titleFont = invalid then titleFont = font
            if timeFont = invalid then timeFont = font
            if infoFont = invalid then infoFont = font
        else
            titleFont = invalid
            timeFont = invalid
            infoFont = invalid
        end if

        ' Draw video thumbnail/poster area (center of screen)
        posterX = 440
        posterY = 160
        posterWidth = 400
        posterHeight = 300
        region.drawRect(posterX, posterY, posterWidth, posterHeight, &h333333FF)

        ' Draw play icon in center
        if isPaused then
            ' Draw pause symbol (two vertical bars)
            region.drawRect(posterX + 180, posterY + 120, 15, 60, &hFFFFFFFF)
            region.drawRect(posterX + 205, posterY + 120, 15, 60, &hFFFFFFFF)
        else
            ' Draw play triangle
            ' Simple triangle using rectangles
            centerX = posterX + 200
            centerY = posterY + 150
            region.drawRect(centerX - 20, centerY - 30, 15, 60, &hFFFFFFFF)
            region.drawRect(centerX - 5, centerY - 20, 15, 40, &hFFFFFFFF)
            region.drawRect(centerX + 10, centerY - 10, 15, 20, &hFFFFFFFF)
        end if

        ' Draw mock poster text
        if titleFont <> invalid then
            region.drawText("📺 MOCK PLAYER", posterX + 50, posterY + 50, &hFFFF00FF, titleFont)
            region.drawText("SIMULATOR MODE", posterX + 50, posterY + 85, &hCCCCCCFF, infoFont)
        end if

        ' Draw video title at top
        if titleFont <> invalid then
            region.drawText("▶ " + fileItem.name, 40, 40, &hFFFFFFFF, titleFont)
        else
            region.drawText("▶ " + fileItem.name, 40, 40, &hFFFFFFFF)
        end if

        ' Draw mock video info
        infoY = 100
        if infoFont <> invalid then
            region.drawText("Resolution: 1080p (Mock)", 40, infoY, &hBBBBBBFF, infoFont)
            region.drawText("Codec: H.264 (Simulated)", 40, infoY + 25, &hBBBBBBFF, infoFont)
            region.drawText("Audio: Stereo (Mock)", 40, infoY + 50, &hBBBBBBFF, infoFont)
        end if

        ' Draw progress bar at bottom
        progressY = 580
        progressBarX = 40
        progressBarWidth = 1200
        progressBarHeight = 12

        ' Background of progress bar
        region.drawRect(progressBarX, progressY, progressBarWidth, progressBarHeight, &h444444FF)

        ' Progress fill with Kodi blue
        progressPercent = currentPosition / totalDuration
        if progressPercent > 1 then progressPercent = 1
        progressFillWidth = progressBarWidth * progressPercent
        region.drawRect(progressBarX, progressY, progressFillWidth, progressBarHeight, &h0078d4FF)

        ' Time display
        timeY = progressY + 25
        if timeFont <> invalid then
            ' Format current time
            currentMin = currentPosition / 60
            currentSec = currentPosition - (currentMin * 60)
            currentStr = Right("0" + Str(currentMin), 2) + ":" + Right("0" + Str(currentSec), 2)

            ' Format total time
            totalMin = totalDuration / 60
            totalSec = totalDuration - (totalMin * 60)
            totalStr = Right("0" + Str(totalMin), 2) + ":" + Right("0" + Str(totalSec), 2)

            region.drawText(currentStr + " / " + totalStr, progressBarX, timeY, &hFFFFFFFF, timeFont)
        end if

        ' Control instructions
        controlsY = 650
        if infoFont <> invalid then
            statusText = ""
            if isPaused then
                statusText = "⏸ PAUSED - "
            else
                statusText = "▶ PLAYING - "
            end if

            region.drawText(statusText + "OK: Play/Pause | ←→: Seek | BACK: Exit | (SIMULATOR)", 40, controlsY, &hFFFF00FF, infoFont)
        end if

        ' Draw stream URL info (for debugging)
        if infoFont <> invalid then
            region.drawText("Stream: " + Left(streamUrl, 80) + "...", 40, 680, &h888888FF, infoFont)
        end if

        ' Update display
        screen.swapBuffers()

        ' Handle user input
        msg = wait(1000, screen.GetMessagePort()) ' 1 second timeout for smooth progress updates
        if msg <> invalid then
            msgType = type(msg)
            if msgType = "roUniversalControlEvent" then
                key = msg.GetInt()
                print "[MOCK PLAYER] Key pressed: " + Str(key)

                if key = 13 or key = 6 then ' Play/Pause (OK button)
                    isPaused = not isPaused
                    if isPaused then
                        print "[MOCK PLAYER] Video paused"
                    else
                        print "[MOCK PLAYER] Video resumed"
                        startTime = CreateObject("roDateTime").AsSeconds() - currentPosition / 10
                    end if

                else if key = 4 then ' Left arrow (rewind)
                    currentPosition = currentPosition - 30
                    if currentPosition < 0 then currentPosition = 0
                    startTime = CreateObject("roDateTime").AsSeconds() - currentPosition / 10
                    print "[MOCK PLAYER] Rewound 30 seconds"

                else if key = 5 then ' Right arrow (fast forward)
                    currentPosition = currentPosition + 30
                    if currentPosition > totalDuration then currentPosition = totalDuration
                    startTime = CreateObject("roDateTime").AsSeconds() - currentPosition / 10
                    print "[MOCK PLAYER] Fast forwarded 30 seconds"

                else if key = 0 then ' Back button
                    print "[MOCK PLAYER] Video playback stopped"
                    return
                end if
            end if
        end if
    end while
end sub

' Load image with fallback to loader.png
function loadImageWithFallback(imageUrl as string) as object
    print "[IMAGE] Attempting to load: " + Left(imageUrl, 60) + "..."

    ' For now, simulate image loading (in real implementation, use roUrlTransfer + roBitmap)
    ' This would download the image and convert to bitmap

    ' Simulate loading delay and success/failure
    loadSuccess = (Rnd(100) > 20) ' 80% success rate simulation

    if loadSuccess then
        print "[IMAGE] Successfully loaded thumbnail"
        return "loaded" ' Placeholder for actual bitmap
    else
        print "[IMAGE] Failed to load thumbnail, using fallback"
        return invalid
    end if
end function

' Draw loader.png fallback when image loading fails
sub drawLoaderFallback(region as object, x as integer, y as integer, w as integer, h as integer, font as object, accentColor as integer, textColor as integer)
    ' Draw fallback area with Kodi loading animation style
    region.drawRect(x, y, w, h, &h333333FF) ' Dark gray background
    region.drawRect(x + 5, y + 5, w - 10, h - 10, &h1a1a1aFF) ' Dark charcoal inner area

    ' Draw loading spinner effect using rectangles
    centerX = x + w / 2
    centerY = y + h / 2

    ' Draw rotating spinner bars
    for i = 0 to 7
        angle = i * 45 ' 8 bars at 45-degree intervals
        barLength = 20
        barX = centerX + (barLength * (i mod 3 - 1)) / 3
        barY = centerY + (barLength * (i \ 3 - 1)) / 3

        ' Fade effect for animation
        opacity = &h40 + (i * &h20)
        region.drawRect(barX, barY, 8, 3, accentColor)
    end for

    ' Draw loader text
    if font <> invalid then
        region.drawText("⏳ LOADING", x + 40, centerY - 20, accentColor, font)
        region.drawText("POSTER...", x + 45, centerY + 5, textColor, font)
    end if
end sub

' ********** GLOBAL AUDIO MANAGEMENT FUNCTIONS **********

' Play audio file using global audio manager with playlist support
sub playGlobalAudioFile(screen as object, region as object, font as object, fileItem as object, accessToken as string, globalAudio as object, allItems as object, selectedIndex as integer, currentPath as string)
    print "[GLOBAL AUDIO] Starting global audio playback for: " + fileItem.name

    ' Show loading screen
    showKodiStyleAuthScreen(screen, region, font, "Loading Audio", "Setting up playlist and starting " + fileItem.name, "", "LOADING")

    ' Build playlist from current folder's audio files
    buildAudioPlaylist(globalAudio, allItems, selectedIndex, accessToken, currentPath)

    ' Start playing the selected track
    if globalAudio.playlist.count() > 0 and globalAudio.currentIndex >= 0 then
        playCurrentTrack(globalAudio)

        ' Show brief success message
        showKodiStyleAuthScreen(screen, region, font, "Now Playing", globalAudio.currentTrack.name, "Track " + Str(globalAudio.currentIndex + 1) + " of " + Str(globalAudio.playlist.count()), "SUCCESS")
        sleep(2000)
    else
        print "[GLOBAL AUDIO] ERROR: Failed to build playlist or set current track"
        showKodiStyleAuthScreen(screen, region, font, "Playback Error", "Could not create audio playlist", "Press OK to continue", "ERROR")
        wait(3000, screen.GetMessagePort())
    end if
end sub

' Build audio playlist from current folder contents
sub buildAudioPlaylist(globalAudio as object, allItems as object, selectedIndex as integer, accessToken as string, currentPath as string)
    print "[GLOBAL AUDIO] Building audio playlist from " + Str(allItems.count()) + " items"

    ' Clear existing playlist
    globalAudio.playlist = []
    globalAudio.currentIndex = -1
    globalAudio.accessToken = accessToken
    globalAudio.folderPath = currentPath

    playlistIndex = 0

    ' Add all audio files to playlist
    for i = 0 to allItems.count() - 1
        item = allItems[i]
        if item <> invalid and item.itemType = "file" then
            itemName = ""
            if item.name <> invalid then
                itemName = item.name
            else if item.path <> invalid then
                itemName = item.path
            else
                itemName = "Unknown Audio File"
            end if

            if isAudioFile(itemName) then
                globalAudio.playlist.push(item)

                ' Set current index if this is the selected item
                if i = selectedIndex then
                    globalAudio.currentIndex = playlistIndex
                end if

                playlistIndex = playlistIndex + 1
                print "[GLOBAL AUDIO] Added to playlist: " + itemName
            end if
        end if
    end for

    print "[GLOBAL AUDIO] Playlist built with " + Str(globalAudio.playlist.count()) + " audio files"
    print "[GLOBAL AUDIO] Current track index: " + Str(globalAudio.currentIndex)
end sub

' Play the current track in the playlist
sub playCurrentTrack(globalAudio as object)
    if globalAudio.playlist.count() = 0 or globalAudio.currentIndex < 0 or globalAudio.currentIndex >= globalAudio.playlist.count() then
        print "[GLOBAL AUDIO] ERROR: Invalid playlist or current index"
        return
    end if

    currentTrack = globalAudio.playlist[globalAudio.currentIndex]
    globalAudio.currentTrack = currentTrack

    print "[GLOBAL AUDIO] Playing track " + Str(globalAudio.currentIndex + 1) + ": " + currentTrack.name

    ' Get file ID
    fileIdValue = invalid
    if currentTrack.id <> invalid then
        fileIdValue = currentTrack.id
    else if currentTrack.file_id <> invalid then
        fileIdValue = currentTrack.file_id
    else
        print "[GLOBAL AUDIO] ERROR: No file ID found for track"
        return
    end if

    ' Convert using FormatJson to preserve precision
    fileId = FormatJson(fileIdValue)
    downloadEndpoint = "/api/v0.1/p/download/file/" + fileId + "/url"

    print "[GLOBAL AUDIO] Getting download URL for file ID: " + fileId
    audioUrlResponse = makeApiRequest(downloadEndpoint, globalAudio.accessToken, "GET")

    if audioUrlResponse = invalid or audioUrlResponse.url = invalid then
        print "[GLOBAL AUDIO] ERROR: Could not get audio download URL"
        return
    end if

    streamUrl = audioUrlResponse.url
    print "[GLOBAL AUDIO] Stream URL obtained: " + Left(streamUrl, 50) + "..."

    ' Set up audio content
    audioContent = {
        url: streamUrl
        Title: currentTrack.name
        Artist: "Seedr"
        Album: globalAudio.folderPath
        StreamFormat: "mp3"
    }

    ' Start playback
    if globalAudio.player <> invalid then
        globalAudio.player.SetContentList([audioContent])
        globalAudio.player.Play()
        globalAudio.isPlaying = true
        globalAudio.isPaused = false
        print "[GLOBAL AUDIO] Playback started successfully"
    else
        print "[GLOBAL AUDIO] ERROR: Audio player is invalid"
    end if
end sub

' Play next track in playlist
sub playNextTrack(globalAudio as object)
    if globalAudio.playlist.count() = 0 then
        print "[GLOBAL AUDIO] No playlist available"
        return
    end if

    if globalAudio.currentIndex < globalAudio.playlist.count() - 1 then
        globalAudio.currentIndex = globalAudio.currentIndex + 1
        print "[GLOBAL AUDIO] Moving to next track: " + Str(globalAudio.currentIndex + 1)
        playCurrentTrack(globalAudio)
    else
        print "[GLOBAL AUDIO] Reached end of playlist"
        ' Could loop back to beginning or stop
        globalAudio.currentIndex = 0
        playCurrentTrack(globalAudio)
    end if
end sub

' Play previous track in playlist
sub playPreviousTrack(globalAudio as object)
    if globalAudio.playlist.count() = 0 then
        print "[GLOBAL AUDIO] No playlist available"
        return
    end if

    if globalAudio.currentIndex > 0 then
        globalAudio.currentIndex = globalAudio.currentIndex - 1
        print "[GLOBAL AUDIO] Moving to previous track: " + Str(globalAudio.currentIndex + 1)
        playCurrentTrack(globalAudio)
    else
        print "[GLOBAL AUDIO] At beginning of playlist"
        ' Could loop to end or restart current track
        globalAudio.currentIndex = globalAudio.playlist.count() - 1
        playCurrentTrack(globalAudio)
    end if
end sub

' Toggle play/pause for global audio
sub toggleGlobalAudioPlayPause(globalAudio as object)
    if globalAudio.player = invalid then
        print "[GLOBAL AUDIO] No audio player available"
        return
    end if

    if globalAudio.isPlaying and not globalAudio.isPaused then
        ' Pause playback
        globalAudio.player.Pause()
        globalAudio.isPaused = true
        print "[GLOBAL AUDIO] Audio paused"
    else if globalAudio.isPaused then
        ' Resume playback
        globalAudio.player.Resume()
        globalAudio.isPaused = false
        print "[GLOBAL AUDIO] Audio resumed"
    else
        print "[GLOBAL AUDIO] No audio currently playing to pause/resume"
    end if
end sub

' Check for global audio events (auto-next, etc.)
sub checkGlobalAudioEvents(globalAudio as object)
    if globalAudio.player = invalid or globalAudio.port = invalid then
        return
    end if

    ' Check for audio player events with no wait
    msg = wait(0, globalAudio.port)
    if msg <> invalid then
        msgType = type(msg)
        if msgType = "roAudioPlayerEvent" then
            print "[GLOBAL AUDIO] Audio player event received"
            ' Handle audio finished, error, etc.
            ' Note: In simulator, most audio events may not work properly
            ' On real device, you could check for track completion and auto-advance
            if msg.GetType() = 8 then ' Track finished (example - actual values may vary)
                print "[GLOBAL AUDIO] Track finished - playing next"
                playNextTrack(globalAudio)
            end if
        end if
    end if
end sub

' Draw audio status display in header
sub drawAudioStatus(region as object, globalAudio as object, font as object, primaryText as integer, accentText as integer, secondaryText as integer)
    if globalAudio.currentTrack = invalid or not globalAudio.isPlaying then
        return ' No audio playing
    end if

    ' Position audio status in top right
    statusX = 900
    statusY = 25

    ' Get track name
    trackName = "Unknown Track"
    if globalAudio.currentTrack.name <> invalid then
        trackName = globalAudio.currentTrack.name
        ' Truncate if too long
        if Len(trackName) > 25 then
            trackName = Left(trackName, 22) + "..."
        end if
    end if

    ' Show play/pause icon and track info
    playIcon = "▶"
    if globalAudio.isPaused then
        playIcon = "⏸"
    end if

    statusText = playIcon + " " + trackName
    playlistInfo = "(" + Str(globalAudio.currentIndex + 1) + "/" + Str(globalAudio.playlist.count()) + ")"

    if font <> invalid then
        region.drawText("🎵 " + statusText, statusX, statusY, accentText, font)
        region.drawText(playlistInfo, statusX, statusY + 25, secondaryText, font)
        region.drawText("*/# Prev/Next • OK Pause", statusX, statusY + 45, &h888888FF, font)
    else
        region.drawText("🎵 " + statusText, statusX, statusY, accentText)
        region.drawText(playlistInfo, statusX, statusY + 25, secondaryText)
    end if
end sub