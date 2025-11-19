sub init()
    m.top.setFocus(false)

    ' Get references to UI elements
    m.cardContainer = m.top.findNode("cardContainer")
    m.cardBorder = m.top.findNode("cardBorder")
    m.focusBorder = m.top.findNode("focusBorder")
    m.topBadge = m.top.findNode("topBadge")
    m.topBadgeText = m.top.findNode("topBadgeText")
    m.planIcon = m.top.findNode("planIcon")
    m.planName = m.top.findNode("planName")
    m.priceLabel = m.top.findNode("priceLabel")
    m.buyButton = m.top.findNode("buyButton")
    m.buyButtonText = m.top.findNode("buyButtonText")
    m.annualText = m.top.findNode("annualText")
    m.annualText2 = m.top.findNode("annualText2")
    m.savingsLabel = m.top.findNode("savingsLabel")
    m.featureDescription = m.top.findNode("featureDescription")
end sub

' Called when planData changes
sub onPlanDataChanged()
    planData = m.top.planData
    if planData = invalid then return

    ' Set plan name
    if planData.name <> invalid then
        m.planName.text = planData.name
    end if

    ' Set plan icon
    if planData.iconUri <> invalid then
        m.planIcon.uri = planData.iconUri
    end if

    ' Set price based on annual/monthly
    price = ""
    if m.top.isAnnual = true and planData.yearlyPrice <> invalid then
        price = "$" + planData.yearlyPrice.ToStr()
    else if planData.monthlyPrice <> invalid then
        price = "$" + planData.monthlyPrice.ToStr() + ".95"
    end if
    m.priceLabel.text = price

    ' Set savings info
    if planData.saveValue <> invalid then
        m.savingsLabel.text = "Save $" + planData.saveValue
    end if

    ' Set feature description
    if planData.description <> invalid then
        m.featureDescription.text = planData.description
    end if

    ' Show/hide top badge
    if planData.topBadge <> invalid and planData.topBadge <> "" then
        m.topBadge.visible = true
        m.topBadgeText.text = planData.topBadge
        ' Adjust card position if badge is shown
        m.cardContainer.translation = [0, 40]
        m.planIcon.translation = [140, 90]
        m.planName.translation = [40, 210]
        m.priceLabel.translation = [40, 260]
        m.buyButton.translation = [90, 350]
        m.annualText.translation = [40, 430]
        m.annualText2.translation = [40, 465]
        m.savingsLabel.translation = [40, 505]
        m.featureDescription.translation = [40, 560]

        ' Set badge color
        if planData.topBadgeColor <> invalid then
            m.topBadge.color = planData.topBadgeColor
        end if
    else
        m.topBadge.visible = false
        ' Reset positions
        m.cardContainer.translation = [0, 0]
        m.planIcon.translation = [140, 50]
        m.planName.translation = [40, 170]
        m.priceLabel.translation = [40, 220]
        m.buyButton.translation = [90, 310]
        m.annualText.translation = [40, 390]
        m.annualText2.translation = [40, 425]
        m.savingsLabel.translation = [40, 465]
        m.featureDescription.translation = [40, 520]
    end if

    ' Set card border color based on plan type
    borderColor = getPlanBorderColor(planData.planType)
    m.cardBorder.color = borderColor
    m.cardBorder.opacity = 1.0
    m.buyButton.color = borderColor
    m.planName.color = borderColor

    ' Set top badge color if applicable
    if planData.planType = "pro" then
        m.topBadge.color = "0x4CAF50FF" ' Green
    end if
end sub

' Get border color based on plan type
function getPlanBorderColor(planType as string) as string
    if planType = "basic" then
        return "0xFF6B35FF" ' Orange/Red
    else if planType = "pro" then
        return "0x4CAF50FF" ' Green
    else if planType = "master" then
        return "0x9C27B0FF" ' Purple
    else if planType = "gold1" or planType = "gold2" or planType = "gold3" or planType = "gold4" then
        return "0xFFD700FF" ' Gold
    end if
    return "0xFF6B35FF" ' Default orange
end function

' Handle focus changes
sub onFocusChanged()
    if m.top.isFocused = true then
        ' Show focus border
        m.focusBorder.opacity = 1.0
        m.focusBorder.color = m.cardBorder.color
        ' Slightly scale up the card for visual feedback
        m.cardContainer.scale = [1.05, 1.05]
    else
        ' Hide focus border
        m.focusBorder.opacity = 0.0
        ' Scale back to normal
        m.cardContainer.scale = [1.0, 1.0]
    end if
end sub

' Handle key press
function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        if key = "OK" then
            ' Button pressed - trigger selection
            m.top.itemSelected = true
            return true
        end if
    end if
    return false
end function


