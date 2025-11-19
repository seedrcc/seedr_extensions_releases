sub init()
    m.catalog = {}
    m.purchases = {}

    m.store = m.top.findNode("store")
    m.store.ObserveField("catalog", "onGetCatalog")
    m.store.observeField("orderStatus", "onOrderStatus")
    m.store.ObserveField("purchases", "onGetPurchases")

    m.textContent = m.top.findNode("textContent")

    m.productsList = m.top.findNode("productsList")
    m.productsList.observeField("itemFocused", "onProductFocused")
    m.productsList.observeField("itemSelected", "onProductSelected")
    m.productsList.setFocus(true)

    m.store.command = "getAllPurchases"
    m.store.command = "getCatalog"
end sub

sub onGetCatalog()
    m.catalog = {}
    for i = 0 to m.store.catalog.GetChildCount() - 1
        item = m.store.catalog.getChild(i)
        m.catalog[item.code] = item
    end for
    updateProductsList()
end sub

sub onGetPurchases()
    m.purchases = {}
    for i = 0 to m.store.purchases.GetChildCount() - 1
        item = m.store.purchases.getChild(i)
        m.purchases[item.code] = item
    end for
    updateProductsList()
end sub

sub onOrderStatus()
    if m.store.orderStatus.status = 1
        m.store.command = "getAllPurchases"
        m.store.command = "getCatalog"
    end if
end sub

sub onProductFocused()
    if m.productsList.content = invalid then
        return
    end if
    item = m.productsList.content.getChild(m.productsList.itemFocused)
    updateProductInfo(m.catalog[item.id])
end sub

sub onProductSelected()
    item = m.productsList.content.getChild(m.productsList.itemFocused)
    orderProduct(item.id)
end sub

sub orderProduct(code)
    order = CreateObject("roSGNode", "ContentNode")
    item = order.createChild("ContentNode")
    item.addFields({ "code": code, "qty": 1})
    m.store.order = order
    m.store.command = "doOrder"
end sub

sub updateProductsList()
    contentNode = createObject("roSGNode", "ContentNode")
    for each entry in m.catalog.Items()
        listItemNode = createObject("roSGNode", "ContentNode")
        title = entry.key
        listItemNode.title = title
        listItemNode.id = entry.key
        contentNode.AppendChild(listItemNode)
    end for
    m.productsList.content = contentNode
end sub

sub isEntitled(product) as boolean
    if m.purchases <> invalid and m.purchases[product.code] <> invalid
        if m.purchases[product.code].status = "Valid"
            return true
        else
            return false
        end if
    end if
end sub

sub updateProductInfo(product)
    text = "Is Entitled: " + isEntitled(product).toStr() + chr(10) + chr(10)
    text += "==== Product Info ====" + chr(10)
    text += "Name: " + product.name + chr(10)
    text += "Description: " + product.description + chr(10)
    text += "Cost: " + product.cost + chr(10)
    text += "Product Type: " + product.productType + chr(10)
    text += "In Stock: " + product.inStock + chr(10)
    text += "Free Trial Quantity: " + product.freeTrialQuantity.toStr() + chr(10)
    text += "Free Trial Type: " + product.freeTrialType + chr(10)
    text += "Trial Cost: " + product.trialCost + chr(10)
    text += "Trial Quantity: " + product.trialQuantity.toStr() + chr(10)
    text += "Trial Type: " + product.trialType + chr(10)
    text += "Offer Start Date: " + product.offerStartDate + chr(10)
    text += "Offer End Date: " + product.offerEndDate + chr(10)
    text += "HD Poster URL: " + product.HDPosterUrl + chr(10)
    text += "SD Poster URL: " + product.SDPosterUrl + chr(10)
    text += "Product Image URL: " + product.productImageUrl + chr(10)
    text += "Quantity: " + product.qty.toStr() + chr(10)

    if m.purchases <> invalid and m.purchases[product.code] <> invalid
        purchase = m.purchases[product.code]
        text += chr(10) + "==== Latest Purchase Info ====" + chr(10)
        text += "Purchase Channel: " + purchase.purchaseChannel + chr(10)
        text += "Purchase Context: " + purchase.purchaseContext + chr(10)
        text += "Purchase Date: " + purchase.purchaseDate + chr(10)
        text += "Purchase ID: " + purchase.purchaseId + chr(10)
        text += "Expiration Date: " + purchase.expirationDate + chr(10)
        text += "Renewal Date: " + purchase.renewalDate + chr(10)
        text += "In Dunning: " + purchase.inDunning + chr(10)
        text += "Status: " + purchase.status + chr(10)
        text += "Name: " + purchase.name + chr(10)
        text += "Description: " + purchase.description + chr(10)
        text += "Cost: " + purchase.cost + chr(10)
        text += "Product Type: " + purchase.productType + chr(10)
        text += "Free Trial Quantity: " + purchase.freeTrialQuantity.toStr() + chr(10)
        text += "Free Trial Type: " + purchase.freeTrialType + chr(10)
        text += "Trial Cost: " + purchase.trialCost + chr(10)
        text += "Trial Quantity: " + purchase.trialQuantity.toStr() + chr(10)
        text += "Trial Type: " + purchase.trialType + chr(10)
        text += "HD Poster URL: " + purchase.HDPosterUrl + chr(10)
        text += "SD Poster URL: " + purchase.SDPosterUrl + chr(10)
        text += "Product Image URL: " + purchase.productImageUrl + chr(10)
        text += "Quantity: " + purchase.qty.toStr() + chr(10)
    end if

     m.textContent.text = text
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press
        if key = "left"
            m.productsList.setFocus(true)
            handled = true
        end if
        if key = "right"
            m.textContent.setFocus(true)
            handled = true
        end if
    end if
    return handled
end function
