sub init()
    print "[DocumentViewer] DocumentViewer init()"

    ' Get references to UI elements
    m.headerTitle = m.top.findNode("headerTitle")
    m.headerSubtitle = m.top.findNode("headerSubtitle")
    m.documentIcon = m.top.findNode("documentIcon")
    m.documentTitle = m.top.findNode("documentTitle")
    m.documentSize = m.top.findNode("documentSize")
    m.documentType = m.top.findNode("documentType")
    m.documentDate = m.top.findNode("documentDate")
    m.downloadDialog = m.top.findNode("downloadDialog")
    m.dialogMessage = m.top.findNode("dialogMessage")
    m.errorOverlay = m.top.findNode("errorOverlay")
    m.errorMessage = m.top.findNode("errorMessage")

    ' Set up observers
    m.top.observeField("documentData", "onDocumentDataChanged")

    ' Set up key handling
    m.top.setFocus(true)

    ' Initialize state
    m.downloadDialogOpen = false
end sub

sub onDocumentDataChanged()
    documentData = m.top.documentData
    if documentData <> invalid then
        print "[DocumentViewer] Loading document: "; documentData.title
        loadDocument(documentData)
    end if
end sub

sub loadDocument(documentData as object)
    ' Set header
    m.headerSubtitle.text = documentData.title

    ' Set document info
    m.documentTitle.text = documentData.title

    ' Get file extension and set appropriate icon
    fileExt = getFileExtension(documentData.title)
    setDocumentIcon(fileExt)

    ' Set document details
    if documentData.fileData <> invalid then
        ' File size
        if documentData.fileData.size <> invalid then
            m.documentSize.text = "Size: " + formatFileSizeLocal(documentData.fileData.size)
        else
            m.documentSize.text = "Size: Unknown"
        end if

        ' File type
        m.documentType.text = "Type: " + getDocumentTypeDescription(fileExt)

        ' Last modified date
        if documentData.fileData.last_update <> invalid then
            m.documentDate.text = "Modified: " + formatDate(documentData.fileData.last_update)
        else
            m.documentDate.text = "Modified: Unknown"
        end if
    else
        m.documentSize.text = "Size: Unknown"
        m.documentType.text = "Type: " + getDocumentTypeDescription(fileExt)
        m.documentDate.text = "Modified: Unknown"
    end if

    print "[DocumentViewer] Document loaded: "; documentData.title
end sub

function getFileExtension(fileName as string) as string
    if fileName <> invalid then
        dotIndex = InStr(fileName, ".")
        if dotIndex > 0 then
            return LCase(Right(fileName, Len(fileName) - dotIndex))
        end if
    end if
    return ""
end function

sub setDocumentIcon(fileExt as string)
    ' Set appropriate icon based on file type
    if fileExt = "pdf" then
        m.documentIcon.uri = "pkg:/images/pdf.png"
    else if fileExt = "docx" or fileExt = "doc" then
        m.documentIcon.uri = "pkg:/images/word.png"
    else if fileExt = "txt" then
        m.documentIcon.uri = "pkg:/images/text.png"
    else
        m.documentIcon.uri = "pkg:/images/document.png"
    end if
end sub

function getDocumentTypeDescription(fileExt as string) as string
    if fileExt = "pdf" then
        return "PDF Document"
    else if fileExt = "docx" then
        return "Microsoft Word Document (DOCX)"
    else if fileExt = "doc" then
        return "Microsoft Word Document (DOC)"
    else if fileExt = "txt" then
        return "Text Document"
    else if fileExt = "rtf" then
        return "Rich Text Format"
    else if fileExt = "odt" then
        return "OpenDocument Text"
    else
        return "Document (" + UCase(fileExt) + ")"
    end if
end function

sub showDownloadDialog()
    print "[DocumentViewer] Showing download dialog"

    m.downloadDialog.visible = true
    m.downloadDialogOpen = true
    m.dialogMessage.text = "Getting download link..."

    ' Get download URL
    documentData = m.top.documentData
    if documentData <> invalid then
        downloadUrl = getDocumentDownloadUrl(documentData)
        if downloadUrl <> invalid and downloadUrl <> "" then
            ' Show download URL (truncated for display)
            displayUrl = downloadUrl
            if Len(displayUrl) > 200 then
                displayUrl = Left(displayUrl, 200) + "..."
            end if

            m.dialogMessage.text = "Download URL obtained. Copy this link to access the document on another device:" + Chr(10) + Chr(10) + displayUrl + Chr(10) + Chr(10) + "Note: This link may expire after some time."
        else
            m.dialogMessage.text = "Failed to get download URL. Please try again later."
        end if
    else
        m.dialogMessage.text = "Document data not available."
    end if
end sub

function getDocumentDownloadUrl(documentData as object) as string
    ' For now, we can't make API calls from components directly
    ' This functionality would need to be implemented in the parent scene
    ' or through a task node
    print "[DocumentViewer] Download URL functionality not available in component scope"
    print "[DocumentViewer] File ID: "; documentData.fileId
    return "Download functionality requires API access from parent scene"
end function

sub hideDownloadDialog()
    m.downloadDialog.visible = false
    m.downloadDialogOpen = false
end sub

sub showError(message as string)
    print "[DocumentViewer] Error: "; message

    m.errorOverlay.visible = true
    m.errorMessage.text = message
end sub

sub hideError()
    m.errorOverlay.visible = false
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        print "[DocumentViewer] Key pressed: "; key

        if key = "back" then
            if m.downloadDialogOpen then
                ' Close download dialog
                hideDownloadDialog()
                return true
            else
                ' Return to previous screen
                print "[DocumentViewer] Back pressed - returning to previous screen"
                m.top.onBackPressed = true
                return true
            end if

        else if key = "OK" then
            if not m.downloadDialogOpen then
                ' Show download dialog
                showDownloadDialog()
                return true
            end if
        end if
    end if

    return false
end function

' Helper function to format file size (local implementation)
function formatFileSizeLocal(sizeBytes as longinteger) as string
    if sizeBytes < 1024 then
        return sizeBytes.ToStr() + " B"
    else if sizeBytes < 1048576 then ' 1024 * 1024
        return Int(sizeBytes / 1024).ToStr() + " KB"
    else if sizeBytes < 1073741824 then ' 1024 * 1024 * 1024
        return Int(sizeBytes / 1048576).ToStr() + " MB"
    else
        return Int(sizeBytes / 1073741824).ToStr() + " GB"
    end if
end function

' Helper function to format date
function formatDate(timestamp as string) as string
    ' Simple date formatting - could be enhanced
    if timestamp <> invalid and Len(timestamp) >= 10 then
        return Left(timestamp, 10) ' Just return YYYY-MM-DD part
    end if
    return "Unknown"
end function
