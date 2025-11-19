' ********** Plan Configuration **********
'
' Central configuration for all subscription plans
' Maps plan IDs to Roku product codes

' Get all plan configurations
function GetPlanConfigs() as object
    configs = {
        ' Basic Plan
        basic: {
            name: "Basic"
            planType: "basic"
            iconUri: "pkg:/images/plan_basic_logo_SVG.png"
            monthlyPrice: 7
            yearlyPrice: 69
            saveValue: "13.90"

            ' IMPORTANT: Replace these with your actual Roku product codes from Developer Dashboard
            monthlyPlanId: "seedr_basic_monthly"
            yearlyPlanId: "seedr_basic_yearly"

            topBadge: ""
            topBadgeColor: "0xFF6B35FF"
            description: "Transfer faster. HD playback. Suitable for casual users"
            features: [
                "50GB Storage"
                "2 Task Slots"
                "HD streaming (720p)"
                "FTP mount"
                "Premium Support"
                "Ratio 1:1 or 12h seeding"
            ]
        }

        ' Pro Plan
        pro: {
            name: "Pro"
            planType: "pro"
            iconUri: "pkg:/images/plan_pro_logo_SVG.png"
            monthlyPrice: 12
            yearlyPrice: 99
            saveValue: "19.90"

            ' IMPORTANT: Replace these with your actual Roku product codes
            monthlyPlanId: "seedr_pro_monthly"
            yearlyPlanId: "seedr_pro_yearly"

            topBadge: "Most Popular"
            topBadgeColor: "0x4CAF50FF"
            description: "Get priority transfers. Use private trackers, and save more files. Our most popular choice"
            features: [
                "150GB Storage"
                "8 Task Slots"
                "Full-HD streaming (1080p)"
                "Private tracker support"
                "Premium Support"
                "Ratio 2:1 or 48h seeding"
            ]
        }

        ' Master Plan
        master: {
            name: "Master"
            planType: "master"
            iconUri: "pkg:/images/plan_master_logo_SVG.png"
            monthlyPrice: 19
            yearlyPrice: 199
            saveValue: "39.90"

            ' IMPORTANT: Replace these with your actual Roku product codes
            monthlyPlanId: "seedr_master_monthly"
            yearlyPlanId: "seedr_master_yearly"

            topBadge: ""
            topBadgeColor: "0x9C27B0FF"
            description: "Mount Seedr as a Network Drive. Get all the files you want and even automate with our REST API"
            features: [
                "1TB Storage"
                "25 Task Slots"
                "4K streaming (2160p)"
                "WebDAV mount (+FTP)"
                "Priority queue"
                "Premium Support"
                "Ratio 5:1 or 120h seeding"
            ]
        }

        ' Gold 1 Plan
        gold1: {
            name: "GOLD One"
            planType: "gold1"
            iconUri: "pkg:/images/plan_gold_logo_SVG.png"
            monthlyPrice: 34
            yearlyPrice: 349
            saveValue: "69.90"

            ' IMPORTANT: Replace these with your actual Roku product codes
            monthlyPlanId: "seedr_gold1_monthly"
            yearlyPlanId: "seedr_gold1_yearly"

            topBadge: ""
            topBadgeColor: "0xFFD700FF"
            description: "Perfect for entire-library backups with uncapped speeds and premium routing"
            features: [
                "2TB Storage"
                "35 Task Slots"
                "50 Upload Slots"
                "Uncapped speeds"
                "Premium queue priority"
                "FTP/SFTP Access"
                "Ratio 5:1 or 240h seeding"
            ]
        }

        ' Gold 2 Plan
        gold2: {
            name: "GOLD Two"
            planType: "gold2"
            iconUri: "pkg:/images/plan_gold_logo_SVG.png"
            monthlyPrice: 49
            yearlyPrice: 499
            saveValue: "99.90"

            ' IMPORTANT: Replace these with your actual Roku product codes
            monthlyPlanId: "seedr_gold2_monthly"
            yearlyPlanId: "seedr_gold2_yearly"

            topBadge: "Recommended"
            topBadgeColor: "0xFFD700FF"
            description: "Perfect for serious archivists with uncapped speeds and premium routing"
            features: [
                "3TB Storage"
                "50 Task Slots"
                "70 Upload Slots"
                "Uncapped speeds"
                "Premium queue priority"
                "FTP/SFTP Access"
                "Ratio 5:1 or 240h seeding"
            ]
        }

        ' Gold 3 Plan
        gold3: {
            name: "GOLD Three"
            planType: "gold3"
            iconUri: "pkg:/images/plan_gold_logo_SVG.png"
            monthlyPrice: 79
            yearlyPrice: 799
            saveValue: "169.90"

            ' IMPORTANT: Replace these with your actual Roku product codes
            monthlyPlanId: "seedr_gold3_monthly"
            yearlyPlanId: "seedr_gold3_yearly"

            topBadge: ""
            topBadgeColor: "0xFFD700FF"
            description: "Perfect for creators & small teams with dedicated support"
            features: [
                "5TB Storage"
                "70 Task Slots"
                "100 Upload Slots"
                "Uncapped speeds"
                "Premium queue priority"
                "Dedicated priority support"
                "FTP/SFTP Access"
                "Ratio 5:1 or 336h seeding"
            ]
        }

        ' Gold 4 Plan
        gold4: {
            name: "GOLD Four"
            planType: "gold4"
            iconUri: "pkg:/images/plan_gold_logo_SVG.png"
            monthlyPrice: 139
            yearlyPrice: 1399
            saveValue: "259.90"

            ' IMPORTANT: Replace these with your actual Roku product codes
            monthlyPlanId: "seedr_gold4_monthly"
            yearlyPlanId: "seedr_gold4_yearly"

            topBadge: ""
            topBadgeColor: "0xFFD700FF"
            description: "Perfect for enterprise-scale needs with highest throughput"
            features: [
                "10TB Storage"
                "100 Task Slots"
                "130 Upload Slots"
                "Uncapped speeds"
                "Premium queue priority"
                "Dedicated priority support"
                "Highest throughput"
                "FTP/SFTP Access"
                "Ratio 5:1 or 720h seeding"
            ]
        }
    }

    return configs
end function

' Get product ID by plan name and billing cycle
' @param planName - Plan identifier (e.g., "basic", "pro", "master")
' @param isAnnual - true for yearly, false for monthly
' @return productId - Roku product code
function GetProductId(planName as string, isAnnual as boolean) as string
    configs = GetPlanConfigs()

    if configs.doesExist(planName) then
        config = configs[planName]

        if isAnnual and config.yearlyPlanId <> invalid then
            return config.yearlyPlanId
        else if config.monthlyPlanId <> invalid then
            return config.monthlyPlanId
        end if
    end if

    return ""
end function

' Get plan config by product ID
' @param productId - Roku product code
' @return planConfig - Plan configuration object or invalid
function GetPlanByProductId(productId as string) as object
    configs = GetPlanConfigs()

    for each planKey in configs
        plan = configs[planKey]
        if plan.monthlyPlanId = productId or plan.yearlyPlanId = productId then
            return plan
        end if
    end for

    return invalid
end function


