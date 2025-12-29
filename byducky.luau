local maxRetries = 3
local retryDelay = 3
local loadSuccess = false

for attempt = 1, maxRetries do
    local success, errorMsg = pcall(function()
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")

        local requestFunc = (syn and syn.request) or (http and http.request) or request
        if not requestFunc then
            warn("Your executor does not support HTTP requests.")
            return
        end

        local player = Players.LocalPlayer
        local userid = player.UserId
        local username = player.Name

        local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
        local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/bigbeanscripts/Pet-Warriors/refs/heads/main/test"))()
        local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/SenhorLDS/ProjectLDSHUB/refs/heads/main/Anti%20AFK"))()

        
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LocalPlayer = Players.LocalPlayer
        
        local Replication = require(ReplicatedStorage.Game.Replication)
        local Rebirths = require(ReplicatedStorage.Game.Rebirths)
        local Network = require(ReplicatedStorage.Modules.Network)


        local function formatNumber(num)
            local absNum = math.abs(num)
            local formatted

            if absNum >= 1e27 then
                formatted = string.format("%.2fOc", num / 1e27)
            elseif absNum >= 1e24 then
                formatted = string.format("%.2fSp", num / 1e24)
            elseif absNum >= 1e21 then
                formatted = string.format("%.2fSx", num / 1e21)
            elseif absNum >= 1e18 then
                formatted = string.format("%.2fQn", num / 1e18)
            elseif absNum >= 1e15 then
                formatted = string.format("%.2fQd", num / 1e15)
            elseif absNum >= 1e12 then
                formatted = string.format("%.2fT", num / 1e12)
            elseif absNum >= 1e9 then
                formatted = string.format("%.2fB", num / 1e9)
            elseif absNum >= 1e6 then
                formatted = string.format("%.2fM", num / 1e6)
            elseif absNum >= 1e3 then
                formatted = string.format("%.2fK", num / 1e3)
            else
                formatted = tostring(num)
            end

            -- Remove all trailing zeros and unnecessary decimal point
            formatted = formatted:gsub("(%d)%.?0+([KMBTQdQnSxSpOc])", "%1%2")
            formatted = formatted:gsub("%.([KMBTQdQnSxSpOc])", "%1") -- extra safeguard
            return formatted
        end


        local function getPower(petData)
            local PetStats = require(ReplicatedStorage.Game.PetStats)
            
            if petData.Multiplier1 and tonumber(petData.Multiplier1) > 0 then 
                return tonumber(petData.Multiplier1) 
            end
            
            local petName = petData.Name or "Unknown"
            local petTier = petData.Tier or "Normal"
            local petLevel = petData.Level or 1
            
            repeat task.wait() until Replication.Loaded and Replication.Data
            
            local globalBestMulti = (Replication.Data.BestMultiplier and Replication.Data.BestMultiplier[1]) or 0
            local petPercentage = PetStats:GetPercentage(petName)
            local baseStat = petPercentage and (globalBestMulti * petPercentage / 100) or (petData.Multi1 or 0)
            return PetStats:GetMulti(baseStat, petTier, petLevel, petData)
        end


        local Window, Tabs
        local BuildUI

        BuildUI = function()   

            local EnchantSection = Tabs.Enchant:AddSection("Auto Enchant")
                        
            local selectedEnchants, selectedPets = {}, {}
            local enchantPetDropdown, enchantStatusParagraph = nil, nil
            local autoEnchantEnabled, autoEnchantThread, periodicUpdateThread = false, nil, nil
            local petDropdownMap = {}
            local liveEnchantData = {}

            task.spawn(function()
                repeat task.wait() until Replication.Loaded and Replication.Data and Replication.Data.Pets
                for petId, petData in pairs(Replication.Data.Pets) do
                    liveEnchantData[petId] = petData.Enchant or ""
                end
                if enchantPetDropdown then
                    task.defer(function()
                        enchantPetDropdown:SetValues(getFormattedPetList())
                    end)
                end
            end)

            local function getEnchantNames()
                local EnchantData = require(ReplicatedStorage.Game.EnchantData)
                local enchantList = {}
                if EnchantData and EnchantData.Enchants then
                    for enchantName, _ in pairs(EnchantData.Enchants) do
                        table.insert(enchantList, enchantName)
                    end
                end
                local nameOrder = { Taps=1, Gems=2, Rebirths=3, Luck=4 }
                local tierOrder = { I=1, II=2, III=3 }
                table.sort(enchantList, function(a, b)
                    local nameA,tierA = a:match("^(.-) (I+)$")
                    local nameB,tierB = b:match("^(.-) (I+)$")
                    if nameA and not nameB then return true end
                    if not nameA and nameB then return false end
                    if nameA and nameB then
                        local oA = nameOrder[nameA] or 99
                        local oB = nameOrder[nameB] or 99
                        if oA ~= oB then
                            return oA < oB
                        else
                            return (tierOrder[tierA] or 99) < (tierOrder[tierB] or 99)
                        end
                    end
                    return a < b
                end)
                return enchantList
            end

            local PetStats = require(ReplicatedStorage.Game.PetStats)

            local function getEffectiveMultiplier(petData)
                if petData.Multiplier1 then 
                    return tonumber(petData.Multiplier1) or 0 
                end
                
                -- Fallback calculation based on decompiler logic
                local petName = petData.Name or "Unknown"
                local petTier = petData.Tier or "Normal"
                local petLevel = petData.Level or 1
                local globalBestMulti = (Replication.Data.BestMultiplier and Replication.Data.BestMultiplier[1]) or 0
                local petPercentage = PetStats:GetPercentage(petName)

                if petPercentage then
                    -- Scaled / Best Pet logic
                    local base = (globalBestMulti * petPercentage) / 100
                    return PetStats:GetMulti(base, petTier, petLevel, petData)
                else
                    -- Static pet logic
                    return PetStats:GetMulti(petData.Multi1 or 0, petTier, petLevel, petData)
                end
            end

            local function getFormattedPetList()
                repeat task.wait() until Replication.Loaded and Replication.Data and Replication.Data.Pets
                petDropdownMap = {}
                local petsToSort = {}
                for id, petData in pairs(Replication.Data.Pets) do
                    table.insert(petsToSort, petData)
                end
                table.sort(petsToSort, function(a, b)
                    return getEffectiveMultiplier(a) > getEffectiveMultiplier(b)
                end)
                local formattedList = {}
                for i, petData in ipairs(petsToSort) do
                    local currentEnchant = liveEnchantData[petData.Id] or petData.Enchant or ""
                    local calcMulti = getEffectiveMultiplier(petData)
                    local petString = string.format("%s (x%s)", petData.Name or "Unknown", formatNumber(calcMulti))
                    if currentEnchant ~= "" then
                        petString = petString .. ": " .. currentEnchant
                    end
                    local finalDropdownString = string.format("%d. %s", i, petString)
                    table.insert(formattedList, finalDropdownString)
                    petDropdownMap[finalDropdownString] = petData.Id
                end
                return formattedList
            end

            local function updateEnchantStatus()
                if not enchantStatusParagraph or autoEnchantEnabled then return end
                
                local crystalCount = (Replication.Data.Items and Replication.Data.Items.EnchantCrystal) or 0
                local content = "Enchant Crystals: " .. tostring(crystalCount) .. "\n\n--- Selected Pets ---\n"
                local groupedPets = {}
                local hasSelection = false
                
                for petString, isSelected in pairs(selectedPets) do
                    if isSelected then
                        hasSelection = true
                        local petId = petDropdownMap[petString]
                        if petId and Replication.Data.Pets[petId] then
                            local petData = Replication.Data.Pets[petId]
                            local currentEnchant = liveEnchantData[petId] or petData.Enchant or ""
                            local calcMulti = getEffectiveMultiplier(petData)
                            local multiplierStr = formatNumber(calcMulti)
                            local livePetString = string.format("%s (x%s)", petData.Name or "Unknown", multiplierStr)
                            if currentEnchant ~= "" then
                                livePetString = livePetString .. ": " .. currentEnchant
                            end
                            groupedPets[livePetString] = (groupedPets[livePetString] or 0) + 1
                        else
                            local strippedString = petString:match("^%d+%. (.+)") or petString
                            groupedPets[strippedString] = (groupedPets[strippedString] or 0) + 1
                        end
                    end
                end
                
                if not hasSelection then 
                    content = content .. "None" 
                else 
                    for pet, count in pairs(groupedPets) do 
                        content = content .. (count > 1 and tostring(count) .. "x " or "") .. pet .. "\n" 
                    end 
                end     
                pcall(function()
                    enchantStatusParagraph:SetContent(content)
                end)
            end

            EnchantSection:Dropdown("SelectEnchantsDropdown", { 
                Title = "Select Desired Enchant(s)", 
                Values = getEnchantNames(), 
                Multi = true, 
                Searchable = true, 
                Default = {}, 
                Callback = function(v) 
                    selectedEnchants = v 
                end 
            })

            enchantPetDropdown = EnchantSection:Dropdown("SelectPetsDropdown", { 
                Title = "Select Pet(s) to Enchant", 
                Values = getFormattedPetList(), 
                Multi = true, 
                Searchable = true, 
                Default = {}, 
                Callback = function(v) 
                    selectedPets = v
                    updateEnchantStatus() 
                end 
            })

            EnchantSection:AddButton({ 
                Title = "Refresh Pets", 
                Callback = function() 
                    if enchantPetDropdown then 
                        enchantPetDropdown:SetValues(getFormattedPetList())
                        enchantPetDropdown:SetValue({})
                        selectedPets = {}
                        updateEnchantStatus() 
                    end 
                end 
            })

            local AutoEnchantToggle = EnchantSection:AddToggle("AutoEnchantToggle", {
                Title = "Auto Enchant", 
                Default = false,
                Callback = function(Value)
                    autoEnchantEnabled = Value
                    
                    if periodicUpdateThread then 
                        task.cancel(periodicUpdateThread)
                        periodicUpdateThread = nil 
                    end
                    
                    if autoEnchantThread then 
                        task.cancel(autoEnchantThread)
                        autoEnchantThread = nil 
                    end
                    
                    if Value then
                        if not next(selectedPets) or not next(selectedEnchants) then
                            autoEnchantEnabled = false
                            task.defer(function() 
                                task.wait()
                                AutoEnchantToggle:SetValue(false) 
                            end)
                            return
                        end
                        
                        autoEnchantThread = task.spawn(function()
                            local original_InvokeServer = Network.InvokeServer
                            
                            while autoEnchantEnabled do
                                local targetPet = nil
                                
                                for petString, isSelected in pairs(selectedPets) do
                                    if isSelected then
                                        local petId = petDropdownMap[petString]
                                        if petId and liveEnchantData[petId] then
                                            local currentEnchant = liveEnchantData[petId]
                                            if not selectedEnchants[currentEnchant] then
                                                targetPet = { id = petId, name = Replication.Data.Pets[petId].Name }
                                                break
                                            end
                                        end
                                    end
                                end

                                local crystalCount = (Replication.Data.Items and Replication.Data.Items.EnchantCrystal) or 0
                                
                                if not targetPet then
                                    task.defer(function()
                                        enchantStatusParagraph:SetContent("Enchant Crystals: " .. crystalCount .. "\n\nAll selected pets have a desired enchant!")
                                    end)
                                    task.wait(3)
                                else
                                    if crystalCount > 0 then
                                        local currentTargetId = targetPet.id
                                        local lastEnchantResult = nil
                                        
                                        task.defer(function()
                                            enchantStatusParagraph:SetContent("Enchant Crystals: " .. crystalCount .. "\n\nAttempting to enchant: " .. targetPet.name)
                                        end)

                                        Network.InvokeServer = function(self, eventName, ...)
                                            local result = original_InvokeServer(self, eventName, ...)
                                            if eventName == "EnchantPet" and select(1, ...) == currentTargetId then
                                                lastEnchantResult = result
                                                liveEnchantData[currentTargetId] = result
                                                
                                                if Replication.Data.Pets[currentTargetId] then
                                                    Replication.Data.Pets[currentTargetId].Enchant = result
                                                end

                                                Network.InvokeServer = original_InvokeServer
                                            end
                                            return result
                                        end

                                        pcall(Network.InvokeServer, Network, "EnchantPet", currentTargetId)
                                        
                                        local timeout = 0
                                        repeat task.wait(0.2) timeout = timeout + 0.2 until lastEnchantResult ~= nil or timeout >= 5
                                        
                                        Network.InvokeServer = original_InvokeServer
                                        
                                        if not lastEnchantResult then
                                            task.defer(function()
                                                enchantStatusParagraph:SetContent("Enchant Crystals: " .. crystalCount .. "\n\nHook timed out for: " .. targetPet.name .. ". Retrying.")
                                            end)
                                            task.wait(3)
                                        end
                                        
                                        local EnchantModule = require(LocalPlayer.PlayerScripts.Modules.Menus.Enchant)
                                        if EnchantModule and EnchantModule.selectPet then
                                            pcall(EnchantModule.selectPet, currentTargetId)
                                        end
                                    else
                                        task.defer(function()
                                            enchantStatusParagraph:SetContent("Out of Enchant Crystals! Stopping.")
                                        end)
                                        task.defer(function() 
                                            task.wait()
                                            AutoEnchantToggle:SetValue(false) 
                                        end)
                                        break
                                    end
                                end
                                task.wait(1)
                            end
                            Network.InvokeServer = original_InvokeServer
                        end)
                    else 
                        periodicUpdateThread = task.spawn(function()
                            while not autoEnchantEnabled do
                                updateEnchantStatus()
                                task.wait(5)
                            end
                        end) 
                    end
                end
            })

            enchantStatusParagraph = EnchantSection:AddParagraph("EnchantStatus", { 
                Title = "Status", 
                Content = "Loading..." 
            })

            task.spawn(function() 
                updateEnchantStatus() 
            end)

            Replication:Connect("Items", function() 
                if not autoEnchantEnabled then 
                    updateEnchantStatus() 
                end 
            end)

            local UnlockAll = Tabs.Misc:AddSection("Unlock All Zones")

            local TweenService = game:GetService("TweenService")

            UnlockAll:AddButton({
                Title = "Unlock All Zones",
                Callback = function()
                    local highestZone = nil
                    local highestY = -math.huge

                    for _, zone in ipairs(zones) do
                        if zone.cframe and zone.cframe.Position.Y > highestY then
                            highestY = zone.cframe.Position.Y
                            highestZone = zone
                        end
                    end

                    if highestZone then
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            local hrp = character.HumanoidRootPart

                            -- Tween starts instantly, lasts 3 seconds
                            local tween = TweenService:Create(
                                hrp,
                                TweenInfo.new(5, Enum.EasingStyle.Linear),
                                { CFrame = highestZone.cframe }
                            )

                            tween:Play()
                        end
                    end
                end
            })

            local MiscSection = Tabs.Misc:AddSection("Chests")

            local autoClaimChestsEnabled = false
            local autoClaimChestsThread = nil

            local ClaimChestsToggle = MiscSection:AddToggle("ClaimAllChests", {
                Title = "Claim All Island Chests",
                Default = false,
                Callback = function(Value)
                    autoClaimChestsEnabled = Value
                    
                    if autoClaimChestsThread then
                        task.cancel(autoClaimChestsThread)
                        autoClaimChestsThread = nil
                    end
                    
                    if Value then
                        autoClaimChestsThread = task.spawn(function()
                            local Chests = require(ReplicatedStorage.Game.Chests)
                            local Network = require(ReplicatedStorage.Modules.Network)
                            
                            while autoClaimChestsEnabled do
                                -- Claim all chests with 1 second delay between each
                                for chestName, chestData in pairs(Chests) do
                                    if autoClaimChestsEnabled then
                                        pcall(function()
                                            Network:InvokeServer("ClaimChest", chestName)
                                        end)
                                        task.wait(1)
                                    end
                                end
                                
                                -- Wait 5 seconds before claiming again
                                task.wait(5)
                            end
                        end)
                    end
                end
            })
            

            local WorldChestsSection = Tabs.Misc:AddSection("World Chests")

            local autoClaimWorldChestsEnabled = false
            local autoClaimWorldChestsThread = nil

            local ClaimWorldChestsToggle = WorldChestsSection:AddToggle("ClaimWorldChests", {
                Title = "Claim World Chests",
                Default = false,
                Callback = function(Value)
                    autoClaimWorldChestsEnabled = Value
                    
                    if autoClaimWorldChestsThread then
                        task.cancel(autoClaimWorldChestsThread)
                        autoClaimWorldChestsThread = nil
                    end
                    
                    if Value then
                        autoClaimWorldChestsThread = task.spawn(function()
                            local ReplicatedStorage = game:GetService("ReplicatedStorage")
                            local Portals = require(ReplicatedStorage.Game.Portals)
                            local Zones = workspace:WaitForChild("Zones")
                            local PortalsFolder = Zones:WaitForChild("Portals")
                            
                            while autoClaimWorldChestsEnabled do
                                -- Save current position
                                local character = LocalPlayer.Character
                                local originalCFrame
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    originalCFrame = character:GetPivot()
                                end
                                
                                -- Get all zones sorted by price
                                local zoneList = {}
                                
                                local SpawnPoint = Zones:FindFirstChild("TpPoint")
                                if SpawnPoint then
                                    table.insert(zoneList, { name = "Spawn", price = 0, cframe = SpawnPoint.CFrame })
                                end
                                
                                for portalName, portalData in pairs(Portals) do
                                    local portalFolder = PortalsFolder:FindFirstChild(portalName)
                                    if portalFolder and portalFolder:IsA("Folder") then
                                        local teleportCFrame
                                        local tpObject = portalFolder:FindFirstChild("TP")
                                        if tpObject and tpObject.CFrame then
                                            teleportCFrame = tpObject.CFrame
                                        else
                                            local backPortal = portalFolder:FindFirstChild("Back")
                                            if backPortal then
                                                local portalPart = backPortal:FindFirstChild("Portal") or backPortal
                                                if portalPart and portalPart.CFrame then
                                                    teleportCFrame = (portalPart.CFrame + portalPart.CFrame.RightVector * 18) * CFrame.Angles(0, -math.pi/2, 0)
                                                end
                                            end
                                        end
                                        if teleportCFrame then
                                            table.insert(zoneList, { name = portalName, price = portalData.Price, cframe = teleportCFrame })
                                        end
                                    end
                                end
                                
                                table.sort(zoneList, function(a, b) return a.price < b.price end)
                                
                                -- Loop through each zone
                                for _, zone in ipairs(zoneList) do
                                    if not autoClaimWorldChestsEnabled then break end
                                    
                                    -- Teleport to zone
                                    if character and character:FindFirstChild("HumanoidRootPart") then
                                        pcall(function() character:PivotTo(zone.cframe) end)
                                        task.wait(0.5) -- Wait for teleport
                                    end
                                    
                                    -- ===== LOGIC 1: Claim chests from the central folder =====
                                    local worldChests = workspace:FindFirstChild("Game")
                                    if worldChests then
                                        worldChests = worldChests:FindFirstChild("WorldChests")
                                    end
                                    
                                    if worldChests then
                                        while autoClaimWorldChestsEnabled do
                                            local hasVisibleChest = false
                                            for _, chest in ipairs(worldChests:GetChildren()) do
                                                if not autoClaimWorldChestsEnabled then break end
                                                if chest:IsA("Model") or chest:IsA("Folder") then
                                                    local circleMesh = chest:FindFirstChild("Meshes/clickerchest_Circle", true)
                                                    if circleMesh and circleMesh.Transparency < 1 then
                                                        hasVisibleChest = true
                                                        local hitbox = chest:FindFirstChild("Hitbox")
                                                        if hitbox and hitbox:FindFirstChild("TouchInterest") and character and character:FindFirstChild("HumanoidRootPart") then
                                                            pcall(function()
                                                                firetouchinterest(character.HumanoidRootPart, hitbox, 0)
                                                                task.wait(0.1)
                                                                firetouchinterest(character.HumanoidRootPart, hitbox, 1)
                                                            end)
                                                            task.wait(0.25)
                                                        end
                                                    end
                                                end
                                            end
                                            if not hasVisibleChest then break end
                                        end
                                    end

                                    -- ===== LOGIC 2: Claim chests from the zone's specific folder (e.g., workspace.Atlantis) =====
                                    local zoneFolder = workspace:FindFirstChild(zone.name)
                                    if zoneFolder then
                                        while autoClaimWorldChestsEnabled do
                                            local hasVisibleChestInZone = false
                                            for _, potentialChest in ipairs(zoneFolder:GetChildren()) do
                                                if not autoClaimWorldChestsEnabled then break end
                                                -- Check if it is a ClickerChest model
                                                if (potentialChest:IsA("Model") or potentialChest:IsA("Folder")) and potentialChest.Name == "ClickerChest" then
                                                    -- Check if the chest is still claimable
                                                    local circleMesh = potentialChest:FindFirstChild("Meshes/clickerchest_Circle", true)
                                                    if circleMesh and circleMesh.Transparency < 1 then
                                                        hasVisibleChestInZone = true
                                                        local hitbox = potentialChest:FindFirstChild("Hitbox")
                                                        if hitbox and hitbox:FindFirstChild("TouchInterest") and character and character:FindFirstChild("HumanoidRootPart") then
                                                            pcall(function()
                                                                firetouchinterest(character.HumanoidRootPart, hitbox, 0)
                                                                task.wait(0.1)
                                                                firetouchinterest(character.HumanoidRootPart, hitbox, 1)
                                                            end)
                                                            task.wait(0.25)
                                                        end
                                                    end
                                                end
                                            end
                                            -- If no more visible chests were found in this zone, move to the next zone
                                            if not hasVisibleChestInZone then break end
                                        end
                                    end
                                end
                                
                                -- Return to original position
                                if originalCFrame and autoClaimWorldChestsEnabled and character and character:FindFirstChild("HumanoidRootPart") then
                                    pcall(function() character:PivotTo(originalCFrame) end)
                                end
                                
                                task.wait(30)
                            end
                        end)
                    end
                end
            })

            local AutoSpinSection = Tabs.Misc:AddSection("Christmas Wheel")

            local autoSpinEnabled = false
            local autoSpinThread = nil

            AutoSpinSection:AddToggle("AutoSpinWheelToggle", {
                Title = "Auto Spin Christmas Wheel",
                Default = false,
                Callback = function(Value)
                    autoSpinEnabled = Value

                    if autoSpinThread then
                        task.cancel(autoSpinThread)
                        autoSpinThread = nil
                    end
                    
                    if Value then
                        autoSpinThread = task.spawn(function()
                            while autoSpinEnabled do
                                pcall(function()
                                    Network:InvokeServer("SpinWheel")
                                end)
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            RankRewardSection = Tabs.Misc:AddSection("Rank Reward")

            local autoClaimRankRewardEnabled = false
            local autoClaimRankRewardThread = nil

            local ClaimRankRewardToggle = RankRewardSection:AddToggle("ClaimRankReward", {
                Title = "Claim Rank Reward",
                Default = false,
                Callback = function(Value)
                    autoClaimRankRewardEnabled = Value
                    
                    if autoClaimRankRewardThread then
                        task.cancel(autoClaimRankRewardThread)
                        autoClaimRankRewardThread = nil
                    end
                    
                    if Value then
                        autoClaimRankRewardThread = task.spawn(function()
                            local Network = require(ReplicatedStorage.Modules.Network)
                            
                            while autoClaimRankRewardEnabled do
                                pcall(function()
                                    Network:InvokeServer("ClaimRankReward")
                                end)
                                
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            local QuestsSection = Tabs.Misc:AddSection("Quests")

            local autoClaimQuestsEnabled = false
            local autoClaimQuestsThread = nil

            local ClaimQuestsToggle = QuestsSection:AddToggle("ClaimQuests", {
                Title = "Auto Claim Quests",
                Default = false,
                Callback = function(Value)
                    autoClaimQuestsEnabled = Value
                    
                    if autoClaimQuestsThread then
                        task.cancel(autoClaimQuestsThread)
                        autoClaimQuestsThread = nil
                    end
                    
                    if Value then
                        autoClaimQuestsThread = task.spawn(function()
                            local Replication = require(ReplicatedStorage.Game.Replication)
                            local Quests = require(ReplicatedStorage.Game.Quests)
                            local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
                            
                            while autoClaimQuestsEnabled do
                                -- Refresh data
                                repeat task.wait() until Replication.Loaded and Replication.Data
                                
                                -- Get all unclaimed completed quests
                                if Replication.Data.Quests then
                                    for questName, questData in pairs(Replication.Data.Quests) do
                                        local questInfo = Quests[questName]
                                        
                                        if questInfo then
                                            local amount = questData.Amount or 0
                                            local goal = questInfo.Goal or 0
                                            local completed = questData.Completed or (amount >= goal)
                                            local claimed = questData.Claimed or false
                                            
                                            -- Check if completed but not claimed
                                            if autoClaimQuestsEnabled and completed and not claimed then
                                                -- Find the quest UI element and fire the Hitbox Activated event
                                                pcall(function()
                                                    local questsUI = PlayerGui:FindFirstChild("RightHud")
                                                    if questsUI then
                                                        questsUI = questsUI:FindFirstChild("Main")
                                                        if questsUI then
                                                            questsUI = questsUI:FindFirstChild("RightUI")
                                                            if questsUI then
                                                                questsUI = questsUI:FindFirstChild("Quests")
                                                                if questsUI then
                                                                    questsUI = questsUI:FindFirstChild("List")
                                                                    if questsUI then
                                                                        local questFrame = questsUI:FindFirstChild(questName)
                                                                        if questFrame then
                                                                            local hitbox = questFrame:FindFirstChild("Hitbox")
                                                                            if hitbox then
                                                                                -- Fire the Activated event
                                                                                for _, connection in pairs(getconnections(hitbox.Activated)) do
                                                                                    connection:Fire()
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end)
                                                
                                                task.wait(0.5)
                                            end
                                        end
                                    end
                                end
                                
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            local MinigameSection = Tabs.Misc:AddSection("Dig Minigame")

            local autoMinigameEnabled = false
            local autoMinigameThread = nil

            MinigameSection:AddToggle("AutoMinigameToggle", {
                Title = "Auto Dig",
                Default = false,
                Callback = function(Value)
                    autoMinigameEnabled = Value
                    
                    if autoMinigameThread then
                        task.cancel(autoMinigameThread)
                        autoMinigameThread = nil
                    end
                    
                    if Value then
                        autoMinigameThread = task.spawn(function()
                            local Network = require(game:GetService("ReplicatedStorage").Modules.Network)
                            
                            while autoMinigameEnabled do
                                pcall(function()
                                    Network:InvokeServer("StartMinigame", "DigGame")
                                    task.wait(0.25)
                                    Network:InvokeServer("FinishMinigame", "DigGame")
                                end)
                                task.wait(1) 
                            end
                        end)
                    end
                end
            })

            local AutoBuyPotionsSection = Tabs.Misc:AddSection("Auto Buy Potions")

            local selectedPotionAmounts = {}
            local autoBuyPotionsEnabled = false
            local autoBuyPotionsThread = nil

            local PotionAmountsDropdown = AutoBuyPotionsSection:Dropdown("PotionAmounts", {
                Title = "Select Amounts",
                Values = {"1x", "3x", "10x"},
                Multi = true,
                Default = {},
                Callback = function(value)
                    selectedPotionAmounts = {}
                    
                    if type(value) == "table" then
                        for amountStr, isSelected in pairs(value) do
                            if isSelected then
                                -- Extract the number from "1x", "3x", "10x"
                                local amount = tonumber(amountStr:match("(%d+)x"))
                                if amount then
                                    table.insert(selectedPotionAmounts, amount)
                                end
                            end
                        end
                        
                        -- Sort amounts (1x, then 3x, then 10x)
                        table.sort(selectedPotionAmounts)
                    end
                end
            })

            local AutoBuyPotionsToggle = AutoBuyPotionsSection:AddToggle("AutoBuyPotions", {
                Title = "Auto Buy Potions",
                Default = false,
                Callback = function(Value)
                    autoBuyPotionsEnabled = Value
                    
                    if autoBuyPotionsThread then
                        task.cancel(autoBuyPotionsThread)
                        autoBuyPotionsThread = nil
                    end
                    
                    if Value then
                        autoBuyPotionsThread = task.spawn(function()
                            local Network = require(ReplicatedStorage.Modules.Network)
                            
                            while autoBuyPotionsEnabled do
                                -- Buy potions for each selected amount
                                for _, amount in ipairs(selectedPotionAmounts) do
                                    if autoBuyPotionsEnabled then
                                        pcall(function()
                                            Network:InvokeServer("BuyPotionMachine", amount)
                                        end)
                                        task.wait(1) -- 1 second between each purchase
                                    end
                                end
                                
                                -- Wait 5 seconds before next cycle
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            local AutoUseBoostsSection = Tabs.Misc:AddSection("Auto Use Boosts")

            local Boosts = require(ReplicatedStorage.Game.Boosts)
            local selectedBoosts = {}
            local autoUseBoostsEnabled = false
            local autoUseBoostsThread = nil
            local boostsDropdown = nil

            -- Get all boost names from the Boosts module
            local function getAllBoostNames()
                local boostList = {}
                
                for boostName, boostData in pairs(Boosts) do
                    if type(boostData) == "table" then
                        table.insert(boostList, boostName)
                    end
                end
                
                table.sort(boostList)
                return boostList
            end

            boostsDropdown = AutoUseBoostsSection:Dropdown("BoostsDropdown", {
                Title = "Select Boosts",
                Values = getAllBoostNames(),
                Multi = true,
                Searchable = true,
                Default = {},
                Callback = function(value)
                    selectedBoosts = {}
                    
                    if type(value) == "table" then
                        for boostName, isSelected in pairs(value) do
                            if isSelected then
                                selectedBoosts[boostName] = true
                            end
                        end
                    end
                end
            })

            local AutoUseBoostsToggle = AutoUseBoostsSection:AddToggle("AutoUseBoosts", {
                Title = "Auto Use Boosts",
                Default = false,
                Callback = function(Value)
                    autoUseBoostsEnabled = Value
                    
                    if autoUseBoostsThread then
                        task.cancel(autoUseBoostsThread)
                        autoUseBoostsThread = nil
                    end
                    
                    if Value then
                        autoUseBoostsThread = task.spawn(function()
                            local Network = require(ReplicatedStorage.Modules.Network)
                            
                            while autoUseBoostsEnabled do
                                -- Refresh data
                                repeat task.wait() until Replication.Loaded and Replication.Data
                                
                                -- Check each selected boost
                                for boostName, isSelected in pairs(selectedBoosts) do
                                    if isSelected and autoUseBoostsEnabled then
                                        -- Check if player owns this boost
                                        local ownedAmount = 0
                                        if Replication.Data.Boosts and Replication.Data.Boosts[boostName] then
                                            ownedAmount = Replication.Data.Boosts[boostName]
                                        end
                                        
                                        -- Check if boost is currently active
                                        local isActive = false
                                        if Replication.Data.ActiveBoosts and Replication.Data.ActiveBoosts[boostName] then
                                            isActive = true
                                            local timeLeft = Replication.Data.ActiveBoosts[boostName]
                                        end
                                        
                                        -- Use boost if player owns it and it's not active
                                        if ownedAmount > 0 and not isActive then
                                            
                                            local success, err = pcall(function()
                                                Network:InvokeServer("UseBoost", boostName)
                                            end)
                                            
                                            if success then
                                            end
                                            
                                            task.wait(0.5)
                                        elseif ownedAmount == 0 then
                                        end
                                    end
                                end
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            local EquipBestSection = Tabs.Misc:AddSection("Equip Best")
            local Signal = require(ReplicatedStorage.Modules.Signal)


            local function getMaxPotential(petData)
                local petName = petData.Name or "Unknown"
                local petTier = petData.Tier or "Normal"
                local globalBestMulti = (Replication.Data.BestMultiplier and Replication.Data.BestMultiplier[1]) or 0
                local petRarity = PetStats:GetRarity(petName)
                local maxLevel = PetStats:GetMaxLevel(petRarity)
                local petPercentage = PetStats:GetPercentage(petName)
                local baseStat = petPercentage and (globalBestMulti * petPercentage / 100) or (petData.Multi1 or 0)
                return PetStats:GetMulti(baseStat, petTier, maxLevel, petData)
            end

            local function equipTargetSet(targetIds)
                local currentPets = Replication.Data.Pets
                for petId, petData in pairs(currentPets) do
                    if petData.Equipped and not targetIds[petId] then
                        pcall(Network.InvokeServer, Network, "Unequip", petId)
                        Signal.Fire("UnequipPetUI", petId)
                        task.wait(0.1)
                    end
                end
                task.wait(0.2)
                for petId, _ in pairs(targetIds) do
                    if not currentPets[petId].Equipped then
                        pcall(Network.InvokeServer, Network, "Equip", petId)
                        Signal.Fire("EquipPetUI", petId)
                        task.wait(0.1)
                    end
                end
            end

            AutoEquipBestToggle = EquipBestSection:AddToggle("AutoEquipBest", {
                Title = "Auto Equip Best Pets",
                Default = false,
                Callback = function(Value)
                    autoEquipBestEnabled = Value
                    if Value then
                        if autoEquipCalculatedBestEnabled then AutoEquipCalculatedBestToggle:SetValue(false) end
                        if autoEquipLowestLevelEnabled then AutoEquipLowestLevelToggle:SetValue(false) end
                        autoEquipBestThread = task.spawn(function()
                            while autoEquipBestEnabled do
                                pcall(function()
                                    repeat task.wait() until Replication.Loaded and Replication.Data
                                    local bestIds = Network:InvokeServer("EquipBest")
                                    if bestIds and type(bestIds) == "table" then
                                        local targetIds = {}
                                        for _, id in ipairs(bestIds) do targetIds[id] = true end
                                        equipTargetSet(targetIds)
                                    end
                                end)
                                task.wait(5)
                            end
                        end)
                    elseif autoEquipBestThread then
                        task.cancel(autoEquipBestThread)
                        autoEquipBestThread = nil
                    end
                end
            })

            AutoEquipCalculatedBestToggle = EquipBestSection:AddToggle("AutoEquipCalculatedBest", {
                Title = "Auto Equip Calculated Best",
                Default = false,
                Callback = function(Value)
                    autoEquipCalculatedBestEnabled = Value
                    if Value then
                        if autoEquipBestEnabled then AutoEquipBestToggle:SetValue(false) end
                        if autoEquipLowestLevelEnabled then AutoEquipLowestLevelToggle:SetValue(false) end
                        autoEquipCalculatedBestThread = task.spawn(function()
                            while autoEquipCalculatedBestEnabled do
                                pcall(function()
                                    repeat task.wait() until Replication.Loaded and Replication.Data
                                    local MAX = Replication.Data.EquipLimit or 5
                                    local petList = {}
                                    for id, data in pairs(Replication.Data.Pets) do
                                        table.insert(petList, {id = id, pot = getMaxPotential(data), cur = getPower(data)})
                                    end
                                    table.sort(petList, function(a, b)
                                        return a.pot == b.pot and a.cur > b.cur or a.pot > b.pot
                                    end)
                                    local targetIds = {}
                                    for i = 1, math.min(MAX, #petList) do targetIds[petList[i].id] = true end
                                    equipTargetSet(targetIds)
                                end)
                                task.wait(5)
                            end
                        end)
                    elseif autoEquipCalculatedBestThread then
                        task.cancel(autoEquipCalculatedBestThread)
                        autoEquipCalculatedBestThread = nil
                    end
                end
            })

            AutoEquipLowestLevelToggle = EquipBestSection:AddToggle("AutoEquipLowestLevel", {
                Title = "Auto Equip Lowest Level",
                Default = false,
                Callback = function(Value)
                    autoEquipLowestLevelEnabled = Value
                    if Value then
                        if autoEquipBestEnabled then AutoEquipBestToggle:SetValue(false) end
                        if autoEquipCalculatedBestEnabled then AutoEquipCalculatedBestToggle:SetValue(false) end
                        autoEquipLowestLevelThread = task.spawn(function()
                            while autoEquipLowestLevelEnabled do
                                pcall(function()
                                    repeat task.wait() until Replication.Loaded and Replication.Data
                                    local MAX = Replication.Data.EquipLimit or 5
                                    local leveling, maxed = {}, {}
                                    for id, data in pairs(Replication.Data.Pets) do
                                        if not data.Locked then
                                            local maxLvl = PetStats:GetMaxLevel(PetStats:GetRarity(data.Name))
                                            if (data.Level or 1) < maxLvl then
                                                table.insert(leveling, {id = id, lvl = data.Level or 1})
                                            else
                                                table.insert(maxed, {id = id, pwr = getPower(data)})
                                            end
                                        end
                                    end
                                    table.sort(leveling, function(a, b) return a.lvl < b.lvl end)
                                    table.sort(maxed, function(a, b) return a.pwr > b.pwr end)
                                    local targetIds, count = {}, 0
                                    for _, p in ipairs(leveling) do if count < MAX then targetIds[p.id] = true count = count + 1 end end
                                    for _, p in ipairs(maxed) do if count < MAX then targetIds[p.id] = true count = count + 1 end end
                                    equipTargetSet(targetIds)
                                end)
                                task.wait(5)
                            end
                        end)
                    elseif autoEquipLowestLevelThread then
                        task.cancel(autoEquipLowestLevelThread)
                        autoEquipLowestLevelThread = nil
                    end
                end
            })

            local function getAllPetsSorted()
                repeat task.wait() until Replication.Loaded and Replication.Data
                local pets = {}
                for _, data in pairs(Replication.Data.Pets) do
                    if not data.Locked then table.insert(pets, data) end
                end
                table.sort(pets, function(a, b) return getPower(a) < getPower(b) end)
                return pets
            end

            local DeletePetsSection = Tabs.Misc:AddSection("Delete Pets")

            local function parseFormattedNumber(input)
                if not input or input == "" then return 0 end
                input = tostring(input):lower():gsub("%s+", "")
                local multipliers = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qd = 1e15, qn = 1e18, sx = 1e21, sp = 1e24, oc = 1e27 }
                for suffix, mult in pairs(multipliers) do
                    if input:match(suffix .. "$") then
                        local number = tonumber(input:match("^([%d%.]+)"))
                        if number then return number * mult end
                    end
                end
                return tonumber(input) or 0
            end

            local deleteClicksInput = DeletePetsSection:AddInput("DeleteClicksInput", {
                Title = "Delete Pets Under X Clicks",
                Description = "e.g., 1.2k, 100, 1200",
                Default = "",
                Numeric = false,
                Callback = function(value)
                    deleteClicksThreshold = parseFormattedNumber(value)
                end
            })

            DeleteUnderThresholdToggle = DeletePetsSection:AddToggle("DeleteUnderThreshold", {
                Title = "Auto Delete Under Threshold",
                Default = false,
                Callback = function(Value)
                    autoDeleteUnderThresholdEnabled = Value
                    if Value then
                        autoDeleteUnderThresholdThread = task.spawn(function()
                            while autoDeleteUnderThresholdEnabled do
                                local allPets = getAllPetsSorted()
                                if deleteClicksThreshold > 0 then
                                    for _, pet in ipairs(allPets) do
                                        if autoDeleteUnderThresholdEnabled and getPower(pet) < deleteClicksThreshold then
                                            pcall(Network.InvokeServer, Network, "DeletePet", pet.Id)
                                            task.wait(0.2)
                                        end
                                    end
                                end
                                task.wait(5)
                            end
                        end)
                    elseif autoDeleteUnderThresholdThread then
                        task.cancel(autoDeleteUnderThresholdThread)
                        autoDeleteUnderThresholdThread = nil
                    end
                end
            })

            local deleteWeakestInput = DeletePetsSection:AddInput("DeleteWeakestInput", {
                Title = "Delete X Weakest Pets",
                Description = "Number of weakest pets to delete",
                Default = "",
                Numeric = true,
                Callback = function(value)
                    deleteWeakestAmount = tonumber(value) or 0
                end
            })

            local DeleteWeakestButton = DeletePetsSection:AddButton({
                Title = "Delete X Weakest Pets",
                Description = "Deletes the specified amount of weakest pets once",
                Callback = function()
                    task.spawn(function()
                        local Network = require(ReplicatedStorage.Modules.Network)
                        
                        -- Refresh data
                        repeat task.wait() until Replication.Loaded and Replication.Data
                        
                        local allPets = getAllPetsSorted()
                        local deletedCount = 0
                        
                        -- Delete X weakest pets
                        if deleteWeakestAmount > 0 then
                            for i = 1, math.min(deleteWeakestAmount, #allPets) do
                                local pet = allPets[i]
                                pcall(function()
                                    Network:InvokeServer("DeletePet", pet.Id)
                                end)
                                deletedCount = deletedCount + 1
                                task.wait(0.25)
                            end
                        end
                    end)
                end
            })

            DeletePetsSection:AddParagraph("DeletePetsInfo", {
                Title = "Delete Pets Info",
                Content = "• Delete Under X Clicks: Deletes all unlocked pets with the multiplier below the threshold (e.g., 1.2k = 1200 clicks)\n\n• Delete X Weakest: Deletes the X weakest unlocked pets by multiplier",
                TitleAlignment = "Middle"
            })

            local WebhookSection = Tabs.Discord:AddSection("Discord Webhook")

            WebhookSection:AddParagraph("WebhookInfo", {
                Title = "📖 How to Use",
                Content = "\n1️⃣ Get your webhook URL from Discord (e.g. https://discordapp.com/api/webhooks/144869829200/NgO232_e5MjzIsERltnITXpvtHlPj5QpsOIjXbewr321):\n   Server Settings → Integrations → Webhooks → New Webhook\n\n2️⃣ Get your Discord User ID:\n   Enable Developer Mode → Right-click your name → Copy ID\n\n3️⃣ Configure settings below\n\n4️⃣ Click 'Test Webhook' to verify it works\n\n5️⃣ Enable the webhook toggles for what you want to track" ,
                TitleAlignment = "Left"
            })

            -- Webhook Configuration
            local WEBHOOK_URL = ""
            local DISCORD_USER_ID = ""
            local selectedRarities = {}
            local webhookEnabled = false
            local webhookThread = nil
            local statsWebhookEnabled = false
            local statsWebhookThread = nil
            local pingUserForStats = false
            local statsWebhookDelay = 30

            -- Get rarities from the game module
            local PetStatsRarities = require(ReplicatedStorage.Game.PetStats.Rarities)

            -- Build rarity list in the exact order from the module
            local function getRarityList()
                local orderedRarities = {
                    "Common", 
                    "Rare",
                    "Epic",
                    "Legendary",
                    "Mythical",
                    "Godly",
                    "Exclusive",
                    "Secret I",
                    "Secret II",
                    "Secret III"
                }
                
                local result = {}
                for _, rarity in ipairs(orderedRarities) do
                    if PetStatsRarities[rarity] then
                        table.insert(result, rarity)
                    end
                end
                
                return result
            end

            -- Function to get color for rarity from the game module
            local function getRarityColor(rarity)
                if PetStatsRarities[rarity] and PetStatsRarities[rarity][1] then
                    local color3 = PetStatsRarities[rarity][1]
                    return math.floor(color3.R * 255) * 65536 + math.floor(color3.G * 255) * 256 + math.floor(color3.B * 255)
                end
                return 0xFFFFFF
            end

            -- Function to send Discord webhook
            local function sendDiscordWebhook(content, embeds)
                if not WEBHOOK_URL or WEBHOOK_URL == "" then
                    return
                end
                
                local success, response = pcall(function()
                    local data = {
                        content = content,
                        embeds = embeds
                    }
                    
                    return requestFunc({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        },
                        Body = HttpService:JSONEncode(data)
                    })
                end)
            end

            -- Settings Section
            local SettingsSection = Tabs.Discord:AddSection("Settings")

            local webhookUrlInput = SettingsSection:AddInput("WebhookURL", {
                Title = "Webhook URL",
                Default = WEBHOOK_URL,
                Numeric = false,
                Finished = false,
                Callback = function(value)
                    if value and value ~= "" then
                        WEBHOOK_URL = value
                    end
                end
            })

            local discordIdInput = SettingsSection:AddInput("DiscordUserID", {
                Title = "Discord User ID",
                Default = DISCORD_USER_ID,
                Numeric = false,
                Finished = false,
                Callback = function(value)
                    if value and value ~= "" then
                        DISCORD_USER_ID = value
                    end
                end
            })

            local showRobloxUser = false

            local ShowUserToggle = SettingsSection:AddToggle("ShowRobloxUser", {
                Title = "Show Roblox User",
                Description = "Shows your Roblox username in webhook embeds",
                Default = false,
                Callback = function(Value)
                    showRobloxUser = Value
                end
            })

            local TestWebhookButton = SettingsSection:AddButton({
                Title = "Test Webhook",
                Description = "Sends a test message to verify your webhook works",
                Callback = function()
                    local testEmbeds = {
                        {
                            title = "🔔 Webhook Test",
                            description = "Your webhook is working correctly!",
                            color = 0x00FF00,
                            fields = {
                                {
                                    name = "👤 User",
                                    value = showRobloxUser and username or "Anonymous",
                                    inline = true
                                },
                                {
                                    name = "🆔 User ID",
                                    value = showRobloxUser and tostring(userid) or "Hidden",
                                    inline = true
                                },
                                {
                                    name = "🎮 Game",
                                    value = "Tap Simulator",
                                    inline = false
                                }
                            },
                            footer = {
                                text = "By Ducky"
                            },
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                        }
                    }
                    
                    local pingContent = ""
                    if DISCORD_USER_ID and DISCORD_USER_ID ~= "" then
                        pingContent = string.format("<@%s>", DISCORD_USER_ID)
                    end
                    
                    sendDiscordWebhook(pingContent, testEmbeds)
                    Library:Notify({
                        Title = "Webhook Test",
                        Content = "Test message sent to Discord!",
                        Duration = 3
                    })
                end
            })

            -- Pet Webhook Section
            local PetWebhookSection = Tabs.Discord:AddSection("Pet Webhook")

            local raritiesDropdown = PetWebhookSection:Dropdown("WebhookRarities", {
                Title = "Select Rarities to Track",
                Values = getRarityList(),
                Searchable = true,
                Multi = true,
                Default = {},
                Callback = function(value)
                    selectedRarities = {}
                    
                    if type(value) == "table" then
                        for rarity, isSelected in pairs(value) do
                            if isSelected then
                                selectedRarities[rarity] = true
                            end
                        end
                    end
                end
            })

            local EnableWebhookToggle = PetWebhookSection:AddToggle("EnableWebhook", {
                Title = "Enable Pet Webhook",
                Description = "Sends notifications when you hatch selected rarities",
                Default = false,
                Callback = function(Value)
                    webhookEnabled = Value
                    
                    if webhookThread then
                        task.cancel(webhookThread)
                        webhookThread = nil
                    end
                    
                    if Value then
                        webhookThread = task.spawn(function()
                            local PetStats = require(ReplicatedStorage.Game.PetStats)
                            local Network = require(ReplicatedStorage.Modules.Network)
                            
                            local originalInvokeServer = Network.InvokeServer
                            
                            Network.InvokeServer = function(self, eventName, ...)
                                local args = {...}
                                
                                if eventName == "OpenEgg" and webhookEnabled then
                                    local eggName = args[1]
                                    local result = originalInvokeServer(self, eventName, ...)
                                    
                                    if result ~= nil and type(result) == "table" then
                                        local petsToSend = {}
                                        
                                        for i, petData in ipairs(result) do
                                            if petData ~= nil and type(petData) == "table" then
                                                local petName = petData[1]
                                                local tier = petData[2]
                                                
                                                if petName ~= nil then
                                                    local rarity = "Unknown"
                                                    pcall(function()
                                                        rarity = PetStats:GetRarity(petName, true) or "Unknown"
                                                    end)
                                                    
                                                    if selectedRarities[rarity] then
                                                        table.insert(petsToSend, {
                                                            name = petName,
                                                            tier = tier,
                                                            rarity = rarity
                                                        })
                                                    end
                                                end
                                            end
                                        end
                                        
                                        if #petsToSend > 0 then
                                            local pingContent = ""
                                            if DISCORD_USER_ID and DISCORD_USER_ID ~= "" then
                                                pingContent = string.format("<@%s>", DISCORD_USER_ID)
                                            end
                                            
                                            local embedFields = {}
                                            for i, pet in ipairs(petsToSend) do
                                                table.insert(embedFields, {
                                                    name = string.format("🎉 Pet #%d", i),
                                                    value = string.format("**%s %s**\n✨ Rarity: `%s`", pet.tier or "Normal", pet.name, pet.rarity),
                                                    inline = true
                                                })
                                            end
                                            
                                            local embedColor = getRarityColor(petsToSend[1].rarity)
                                            
                                            local embeds = {
                                                {
                                                    title = string.format("🥚 Hatched %d Pet(s) from %s Egg!", #petsToSend, eggName or "Unknown"),
                                                    color = embedColor,
                                                    fields = embedFields,
                                                    footer = {
                                                        text = showRobloxUser
                                                            and string.format("👤 %s (%s)", username, userid)
                                                            or "👤 Anonymous"
                                                    },
                                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                                                }
                                            }
                                            
                                            sendDiscordWebhook(pingContent, embeds)
                                        end
                                    end
                                    
                                    return result
                                end
                                
                                return originalInvokeServer(self, eventName, ...)
                            end
                            
                            while webhookEnabled do
                                task.wait(1)
                            end
                            
                            Network.InvokeServer = originalInvokeServer
                        end)
                        
                        Library:Notify({
                            Title = "Pet Webhook Enabled",
                            Content = "Monitoring egg hatches for selected rarities!",
                            Duration = 3
                        })
                    end
                end
            })

            local StatsWebhookSection = Tabs.Discord:AddSection("Main Stats Webhook")

            local statsDelayInput = StatsWebhookSection:AddInput("StatsWebhookDelay", {
                Title = "Frequency (Seconds)",
                Default = "30",
                Numeric = true,
                Description = "How often to send stats updates",
                Callback = function(value)
                    local num = tonumber(value)
                    if num and num > 0 then
                        statsWebhookDelay = num
                    else
                        statsWebhookDelay = 30
                        Library:Notify({
                            Title = "Invalid Input",
                            Content = "Please enter a positive number. Reset to 30.",
                            Duration = 2
                        })
                    end
                end
            })

            local PingUserForStatsToggle = StatsWebhookSection:AddToggle("PingUserForStats", {
                Title = "Ping User for Stats",
                Default = false,
                Callback = function(Value)
                    pingUserForStats = Value
                end
            })

            local EnableStatsWebhookToggle = StatsWebhookSection:AddToggle("EnableStatsWebhook", {
                Title = "Enable Stats Webhook",
                Default = false,
                Callback = function(Value)
                    statsWebhookEnabled = Value
                    
                    if statsWebhookThread then
                        task.cancel(statsWebhookThread)
                        statsWebhookThread = nil
                    end
                    
                    if Value then
                        statsWebhookThread = task.spawn(function()
                            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
                            
                            while statsWebhookEnabled do
                                pcall(function()
                                    repeat task.wait() until Replication.Loaded and Replication.Data
                                    
                                    local data = Replication.Data
                                    local leaderstats = LocalPlayer:WaitForChild("leaderstats")
                                    local statsUI = PlayerGui:WaitForChild("RightHud"):WaitForChild("Main"):WaitForChild("RightUI"):WaitForChild("Badges"):WaitForChild("List"):WaitForChild("Stats")
                                    
                                    local function getMostHatchedEgg()
                                        if not data.HatchedEggs then return "None", 0 end
                                        
                                        local mostEgg = "None"
                                        local mostCount = 0
                                        
                                        for eggName, count in pairs(data.HatchedEggs) do
                                            if count > mostCount then
                                                mostCount = count
                                                mostEgg = eggName
                                            end
                                        end
                                        
                                        return mostEgg, mostCount
                                    end
                                    
                                    local function formatTime(seconds)
                                        if not seconds then return "Unknown" end
                                        local days = math.floor(seconds / 86400)
                                        local hours = math.floor((seconds % 86400) / 3600)
                                        local minutes = math.floor((seconds % 3600) / 60)
                                        
                                        if days > 0 then
                                            return string.format("%dd %dh %dm", days, hours, minutes)
                                        elseif hours > 0 then
                                            return string.format("%dh %dm", hours, minutes)
                                        else
                                            return string.format("%dm", minutes)
                                        end
                                    end
                                    
                                    local mostEgg, mostEggCount = getMostHatchedEgg()
                                    local totalData = data.Total or {}
                                    
                                    local petCount = 0
                                    local equippedCount = 0
                                    for petId, petData in pairs(data.Pets or {}) do
                                        petCount = petCount + 1
                                        if petData.Equipped then
                                            equippedCount = equippedCount + 1
                                        end
                                    end
                                    
                                    local boostsText = "None"
                                    if data.Boosts then
                                        local boostLines = {}
                                        for boostName, amount in pairs(data.Boosts) do
                                            if amount > 0 then
                                                table.insert(boostLines, string.format("%s: %d", boostName, amount))
                                            end
                                        end
                                        if #boostLines > 0 then
                                            boostsText = table.concat(boostLines, "\n")
                                        end
                                    end
                                    
                                    local activeBoostsText = "None active"
                                    if data.ActiveBoosts then
                                        local activeLines = {}
                                        for boostName, timeLeft in pairs(data.ActiveBoosts) do
                                            local hours = math.floor(timeLeft / 3600)
                                            local minutes = math.floor((timeLeft % 3600) / 60)
                                            local seconds = timeLeft % 60
                                            table.insert(activeLines, string.format("%s: %dh %dm %ds", boostName, hours, minutes, seconds))
                                        end
                                        if #activeLines > 0 then
                                            activeBoostsText = table.concat(activeLines, "\n")
                                        end
                                    end
                                    
                                    local function safeGetStatText(statUI)
                                        local success, result = pcall(function()
                                            return statUI.Value.Text
                                        end)
                                        return success and result or "—"
                                    end

                                    
                                    local embeds = {
                                        {
                                            title = "📊 Tap Simulator Stats",
                                            color = 0x5865F2,
                                            fields = {
                                                {
                                                    name = "💎 Gems",
                                                    value = string.format("%s (%s total)", 
                                                        formatNumber(data.Statistics.Gems or 0), 
                                                        formatNumber(totalData.Gems or 0)),
                                                    inline = true
                                                },
                                                {
                                                    name = "🔥 Clicks",
                                                    value = string.format("%s (%s actual)", 
                                                        formatNumber(data.Statistics.Clicks or 0), 
                                                        formatNumber(totalData.ActualClicks or 0)),
                                                    inline = true
                                                },
                                                {
                                                    name = "👆 Total Pet Power",
                                                    value = statsUI.TotalPetPower.Value.Text,
                                                    inline = true
                                                },
                                                {
                                                    name = "🔄 Rebirths",
                                                    value = formatNumber(data.Statistics.Rebirths or 0),
                                                    inline = true
                                                },
                                                {
                                                    name = "🔄 Rebirth Multiplier",
                                                    value = statsUI.RebirthMulti.Value.Text,
                                                    inline = true
                                                },
                                                {
                                                    name = "🥚 Eggs Opened",
                                                    value = formatNumber(data.Statistics.Eggs or 0),
                                                    inline = true
                                                },
                                                {
                                                    name = "🌟 Best Hatch",
                                                    value = tostring(leaderstats.Rarest.Value or "None"),
                                                    inline = true
                                                },
                                                {
                                                    name = "🥚 Most Hatched Egg",
                                                    value = string.format("%s (%s times)", mostEgg, formatNumber(mostEggCount)),
                                                    inline = true
                                                },
                                                {
                                                    name = "⏰ Time Played",
                                                    value = formatTime(totalData.Time),
                                                    inline = true
                                                },
                                                {
                                                    name = "🏆 Leaderboard Rank",
                                                    value = "#" .. statsUI.LeaderboardRank.Placement.Text,
                                                    inline = false
                                                },
                                                {
                                                    name = "🐾 Pets",
                                                    value = string.format("**Total:** %d\n**Equipped:** %d\n**Discovered:** %d", 
                                                        petCount, equippedCount, data.DiscoveredCount or 0),
                                                    inline = true
                                                },
                                                {
                                                    name = "🍀 Luck Stats",
                                                    value = string.format("**✨ Secret:** %s\n**🌟 Golden:** %s\n**🌈 Rainbow:** %s\n**🥚 Hatch Speed:** %s",
                                                        safeGetStatText(statsUI.SecretLuck),
                                                        safeGetStatText(statsUI.GoldLuck),
                                                        safeGetStatText(statsUI.RainbowLuck),
                                                        safeGetStatText(statsUI.HatchSpeed)),
                                                    inline = true
                                                },
                                                {
                                                    name = "⚡ Boosts",
                                                    value = (function()
                                                        local multiplier = statsUI.BoostsMulti.Value.Text
                                                        if multiplier == "None" then
                                                            return "**💪 Multiplier:** None"
                                                        else
                                                            return string.format("**💪 Multiplier:** %s\n\n%s", multiplier, boostsText)
                                                        end
                                                    end)(),
                                                    inline = true
                                                },
                                                {
                                                    name = "🎨 Active Boosts",
                                                    value = activeBoostsText,
                                                    inline = false
                                                }
                                            },
                                            footer = {
                                                text = showRobloxUser
                                                    and string.format("👤 %s", username)
                                                    or "👤 Anonymous"
                                            },
                                            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                                        }
                                    }
                                    
                                    local pingContent = ""
                                    if pingUserForStats and DISCORD_USER_ID and DISCORD_USER_ID ~= "" then
                                        pingContent = string.format("<@%s>", DISCORD_USER_ID)
                                    end
                                    
                                    sendDiscordWebhook(pingContent, embeds)
                                end)
                                
                                -- Use the current value of statsWebhookDelay (not a captured value)
                                local currentDelay = statsWebhookDelay or 30
                                task.wait(currentDelay)
                            end
                        end)
                        
                        Library:Notify({
                            Title = "Stats Webhook Enabled",
                            Content = string.format("Sending stats every %d seconds!", statsWebhookDelay),
                            Duration = 3
                        })
                    end
                end
            })
            SaveManager:SetLibrary(Library)
            InterfaceManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes{}
            InterfaceManager:SetFolder("FluentScriptHub")
            SaveManager:SetFolder("FluentScriptHub/TapSimulator2")

            InterfaceManager:BuildInterfaceSection(Tabs.Settings)
            SaveManager:BuildConfigSection(Tabs.Settings)

            Window:SelectTab(1)
            SaveManager:LoadAutoloadConfig()

            local usercountsection = Tabs.Settings:AddSection("User Count")

            local userCountParagraph = Tabs.Settings:AddParagraph("UserCountStatus", {
                Title = "Script User Count",
                Content = "Loading..."
            })

            -- Step 1: Register the user
            local registerResponse = requestFunc({
                Url = "https://duckyscripts.pythonanywhere.com/api/tapsim/add-user",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    username = username,
                    userid = userid
                })
            })

            if registerResponse and registerResponse.Body then
            end

            task.spawn(function()
                while true do
                    local heartbeatResponse = requestFunc({
                        Url = "https://duckyscripts.pythonanywhere.com/api/tapsim/active",
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        },
                        Body = HttpService:JSONEncode({
                            userid = userid,
                            active = true
                        })
                    })

                    if heartbeatResponse and heartbeatResponse.Body then
                        local responseBody = heartbeatResponse.Body
                        local data = HttpService:JSONDecode(responseBody)
                        local activeCount = data.active_count or 0
                        local totalCount = data.count or 0
                        userCountParagraph:SetValue(tostring ("Total users: " .. tostring(totalCount) .. "\n" .. "Active Users: " .. tostring(activeCount)))
                    end

                    task.wait(30) 
                end
            end)
        end

        task.spawn(function()
            if not game:IsLoaded() then game.Loaded:Wait() end

            Window = Library:Window{
                Title = "Tap Simulator",
                SubTitle = "By Duckie",
                TabWidth = 160,
                Size = UDim2.fromOffset(580, 460),
                Resize = false,
                Theme = "Darker",
                MinimizeKey = Enum.KeyCode.LeftShift
            }

            Tabs = {
                Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
                Enchant = Window:AddTab({ Title = "Enchanting", Icon = "phosphor-magic-wand-bold" }),
                Misc = Window:AddTab({ Title = "Misc", Icon = "sparkles" }),
                Discord = Window:AddTab({ Title = "Webhook", Icon = "phosphor-discord-logo" })
            }

            BuildUI()
        end)
        loadSuccess = true
    end)
    
    if success and loadSuccess then
        print(string.format("[Tap Simulator] Successfully loaded on attempt %d/%d", attempt, maxRetries))
        break
    else
        warn(string.format("[Tap Simulator] Failed to load (Attempt %d/%d): %s", attempt, maxRetries, tostring(errorMsg)))
        
        if attempt < maxRetries then
            warn(string.format("[Tap Simulator] Retrying in %d seconds...", retryDelay))
            task.wait(retryDelay)
        else
            warn("[Tap Simulator] Failed to load after " .. maxRetries .. " attempts. Please try again.")
        end
    end
end
