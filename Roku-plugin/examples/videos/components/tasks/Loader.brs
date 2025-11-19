sub Init()
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL("https://hosttec.online/rokuxml/achei/achei.json")
    rsp = xfer.GetToString()
    rootChildren = []
    rows = {}

    m.json = ParseJson(rsp)

    if m.json <> invalid
        for each category in m.json.categories
            row = {}
            videos= []
            row.title = category.name
            row.children = []
            for each item in m.json.playlists
                if item.name = category.playlistName
                    ids = item.itemIds
                end if	
            end for 

            for each data in ids
                for each output in m.json.tvSpecials
                    if output.id = data
                    videos.Push(output)
                    end if	
                end for 
            end for 

            for each item in videos 
                itemData = updateDataStructure(item)
                row.children.Push(itemData)
            end for
            rootChildren.Push(row)
end for
       
        contentNode = CreateObject("roSGNode", "ContentNode")
        contentNode.Update({
            children: rootChildren
        }, true)
        m.top.content = contentNode
    end if
end sub

function updateDataStructure(video as Object) as Object
    item = {}
    if video.longDescription <> invalid
        item.description = video.longDescription
    else
        item.description = video.shortDescription
    end if
    item.hdPosterURL = video.thumbnail
    item.title = video.title
    item.genre = video.genres[0]
    item.releaseDate = video.releaseDate
    item.id = video.id
    if video.content <> invalid
        item.quality = video.content.videos[0].quality
        item.length = video.content.duration
        item.url = video.content.videos[0].url
        item.streamFormat = video.content.videos[0].videoType
    end if
    return item
end function

function findVideos(name as object) as object
    videos= []
    for each item in m.json.playlists
		if item.name = name
			ids = item.itemIds
		end if	
    end for 

    for each data in ids
        for each output in m.json.tvSpecials
            if output.id = data
            videos.Push(output)
            end if	
        end for 
    end for 
    return videos	
end function