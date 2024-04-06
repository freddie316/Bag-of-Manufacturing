-- Instantiate important objects
local game = Game()

BagId = Isaac.GetItemIdByName("Bag of Manufacturing")
BagAnim = Isaac.GetEntityVariantByName("Bag of Manufacturing")

-- Important Variables
local bag = {} -- the call back object
local bagContent = {} -- whats in the bag
local recipe = {} -- the item recipe, should be exactly 8 items 
for i=1,27 do -- init recipe to all zero
  recipe[i]=0
end

local resultId = 0

local bagSlot = nil
local bagOut = 0
local offset = Vector(0,4)
local offsetSwing = Vector(0,-40)

local guiMode = false
local selection = 0


-- The pickup tables
local pickupIDLookup = {
	["10.1"] = {1}, -- Red heart
	["10.2"] = {1}, -- half heart
	["10.3"] = {2}, -- soul heart
	["10.4"] = {4}, -- eternal heart
	["10.5"] = {1, 1}, -- double heart
	["10.6"] = {3}, -- black heart
	["10.7"] = {5}, -- gold heart
	["10.8"] = {2}, -- half soul heart
	["10.9"] = {1}, -- scared red heart
	["10.10"] = {2, 1}, -- blended heart
	["10.11"] = {6}, -- Bone heart
	["10.12"] = {7}, -- Rotten heart
	["20.1"] = {8}, -- Penny
	["20.2"] = {9}, -- Nickel
	["20.3"] = {10}, -- Dime
	["20.4"] = {8, 8}, -- Double penny
	["20.5"] = {11}, -- Lucky Penny
	["20.6"] = {9}, -- Sticky Nickel
	["20.7"] = {26}, -- Golden Penny
	["30.1"] = {12}, -- Key
	["30.2"] = {13}, -- golden Key
	["30.3"] = {12,12}, -- Key Ring
	["30.4"] = {14}, -- charged Key
	["40.1"] = {15}, -- bomb
	["40.2"] = {15,15}, -- double bomb
	["40.4"] = {16}, -- golden bomb
	["40.7"] = {17}, -- giga bomb
	["42.0"] = {29}, -- poop nugget
	["42.1"] = {29}, -- big poop nugget
	["70.14"] = {27}, -- golden pill
	["70.2062"] = {27}, -- golden horse pill
	["90.1"] = {19}, -- Lil Battery
	["90.2"] = {18}, -- Micro Battery
	["90.3"] = {20}, -- Mega Battery
	["90.4"] = {28}, -- Golden Battery
	["300.49"] = {24}, -- Dice shard
	["300.50"] = {21}, -- Emergency Contact
	["300.78"] = {25}, -- Cracked key
}

local pickupNameLookup = {
	"Red heart",
	"Soul heart",
    "Black heart",
    "Eternal heart",
    "Gold heart",
    "Bone heart",
    "Rotten heart",
    "Penny",
    "Nickel",
    "Dime",
    "Lucky penny",
    "Key",
    "Golden key",
    "Charged key",
    "Bomb",
    "Golden bomb",
    "Giga bomb",
    "Micro battery",
    "Lil battery",
    "Mega battery",
    "Card",
    "Pill",
    "Rune",
    "Dice shard",
    "Cracked key",
    "Golden penny",
    "Golden pill",
    "Golden battery",
    "Poop"
}

-- Bag function code
function bag.use(_, item, rng, player, useFlags, activeSlot, varData)

    if (bagOut == 0) then
        local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, BagAnim, 0, player.Position - offset, Vector.Zero, player):ToEffect()
        effect.Parent = player
        effect.DepthOffset = 99
        bagSlot = activeSlot
        bagOut = 1
    elseif (bagOut == 1) then
        bagOut = 0
    end

    return {
        Discharge = false,
        Remove = false,
        ShowAnim = true
    }
end

local function hitDetectEntity(damage, effect, player, offset)
    local hit = false

    for index, entity in ipairs(Isaac.FindInRadius(player.Position - offset, 24 * effect.SpriteScale.X)) do
        if entity:IsVulnerableEnemy() then -- enemy check
            hit = true
            
            local knockbackVec = entity.Position - player.Position

            entity:AddVelocity(knockbackVec:Resized(30))
            
            entity:TakeDamage(damage, 0, EntityRef(player), 0)

            if not entity:HasMortalDamage() then
                player:AddVelocity(knockbackVec:Resized(-5))
            end

            SFXManager():Play(SoundEffect.SOUND_MEATY_DEATHS, 0.9, 0, false, 1)
        end

        if entity.Type == EntityType.ENTITY_FIREPLACE then -- fireplace check
            entity:TakeDamage(damage*3, 0, EntityRef(player), 0)
        end
    end

    -- Pickup detection
    for index, entity in ipairs(Isaac.FindInRadius(player.Position - offset, 24 * effect.SpriteScale.X, EntityPartition.PICKUP)) do -- partition looks at only pickups
        local pickup = entity:ToPickup() -- if conversion fails returns nil
        
        if pickup == nil then -- check for conversion failure
            goto continue
        end

        local knockbackVec = pickup.Position - player.Position

        if pickup.Variant == PickupVariant.PICKUP_CHEST 
        or pickup.Variant == PickupVariant.PICKUP_SPIKEDCHEST 
        or pickup.Variant == PickupVariant.PICKUP_ETERNALCHEST 
        or pickup.Variant == PickupVariant.PICKUP_MIMICCHEST
        or pickup.Variant == PickupVariant.PICKUP_WOODENCHEST
        or pickup.Variant == PickupVariant.PICKUP_HAUNTEDCHEST
        or pickup.Variant == PickupVariant.PICKUP_LOCKEDCHEST
        or pickup.Variant == PickupVariant.PICKUP_REDCHEST
        or pickup.Variant == PickupVariant.PICKUP_BIGCHEST then
            pickup:TryOpenChest(player)
            pickup:AddVelocity(knockbackVec:Resized(30))
            goto continue -- skip handling putting item in bag and removal
        elseif pickup.Variant == PickupVariant.PICKUP_GRAB_BAG then
            -- I am not entirely sure how to open a grab bag
            pickup:AddVelocity(knockbackVec:Resized(30))
            goto continue
        elseif pickup.Variant == PickupVariant.PICKUP_COIN -- Address pickups that actual enter the bag
            or pickup.Variant == PickupVariant.PICKUP_HEART
            or pickup.Variant == PickupVariant.PICKUP_BOMB
            or pickup.Variant == PickupVariant.PICKUP_KEY
            or pickup.Variant == PickupVariant.PICKUP_LIL_BATTERY       
            or pickup.Variant == PickupVariant.PICKUP_POOP
            or pickup.Variant == PickupVariant.PICKUP_PILL
            or pickup.Variant == PickupVariant.PICKUP_TAROTCARD then
            -- need to add pickup sound
            -- print(pickup.Variant .. "." .. pickup.SubType)
            
            local intoBag = EID:getBagOfCraftingID(pickup.Variant, pickup.SubType)
            
            for _, incoming in pairs(intoBag) do
                if bagContent[incoming] == nil then
                    bagContent[incoming] = 1
                else
                    bagContent[incoming] = bagContent[incoming] + 1
                end
            end
            
            -- handle removal of bagged item
            local sprite = pickup:GetSprite()
            sprite:Play("Collect",true)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 1, pickup.Position, Vector.Zero, nil)
            pickup.Timeout = 6
            pickup.Wait = 6
            
        else
            -- it doesnt go in the bag? whack it
            pickup:AddVelocity(knockbackVec:Resized(30))
        end
        
        ::continue::
    end

    return hit
end

local function hitDetectGrid(damage,effect,player,offset)
    local room = game:GetRoom()
    for i=0, room:GetGridSize() do
        local grid = room:GetGridEntity(i)
        if grid then
            if grid.Position:Distance(player.Position - offset) <= 24*effect.SpriteScale.X then
                grid:Hurt(damage)
            end
        end
    end
end

function bag.swing(_, effect)
    local sprite = effect:GetSprite()
    local player = effect.Parent:ToPlayer()

    local fireDir = player:GetFireDirection()
    local walkDir = player:GetMovementDirection()

    -- Disable tears
    if player.FireDelay < player.MaxFireDelay then
        player.FireDelay = player.MaxFireDelay - 1
    end

    effect.SpriteScale = player.SpriteScale

    local anim = sprite:GetAnimation()

    if anim == "Idle" then
        local angle = 0
        if fireDir > -1 then
            angle = fireDir * 90 + 90
            sprite.Rotation = angle

            if player.FireDelay < 25.0 then -- cap bag swing speed
                player.FireDelay = 25.0
                
                local damage = 3
                local bagOffset = offsetSwing:Rotated(angle)
                
                local hit = false

                sprite:Play("Swing", true)

                SFXManager():Play(SoundEffect.SOUND_POOPITEM_HOLD, 1, 0, false, 1) -- TODO: find correct sound
                hit = hitDetectEntity(damage, effect, player, bagOffset)
                hitDetectGrid(damage,effect,player,bagOffset)

            end
        elseif walkDir > -1 then
            angle = walkDir * 90 + 90
            sprite.Rotation = angle
        else
            sprite.Rotation = angle
        end
    else
        if sprite:IsFinished(sprite:GetAnimation()) then
            sprite:Play("Idle", true)
            bagOut = 0
        end
    end

    if (sprite.Rotation == 0 or sprite.Rotation == 180 or sprite.Rotation == 360) then
        effect.Position = effect.Parent.Position + offset:Rotated(sprite.Rotation) - Vector(0,8)
        effect.Velocity = effect.Parent.Velocity * 2
    else
        effect.Position = effect.Parent.Position + offset:Rotated(sprite.Rotation) * 4 - Vector(0,16)
        effect.Velocity = effect.Parent.Velocity * 2
    end

    if not (sprite.Rotation == 0 or sprite.Rotation == 360) then
        effect.DepthOffset = -99
    else
        effect.DepthOffset = 99
    end

    if bagOut == 0 or (not player:HasCollectible(Isaac.GetItemIdByName("Bag of Manufacturing"))) then
        effect:Remove()
        bagOut = 0
    end
end

function bag.newRoom()
    local player = Isaac.GetPlayer(0)
    if (bagOut == 1 and player:HasCollectible(BagId)) then
        --local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, BagAnim, 0, player.Position - offset, Vector.Zero, player):ToEffect()
        --effect.Parent = player
        --effect.DepthOffset = 99
        bagOut = 0
    end
end

local function bagCount(T) -- compute table length
    local count = 0
    for item,quantity in pairs(bagContent) do
        for i = 1, quantity do
            count = count + 1
        end
    end
    return count
  end

local function renderGUI() -- function to handle rendering the recipe selection gui
    local f = Font()
    f:Load("font/luaminioutlined.fnt")
    local x = Isaac.GetScreenWidth()*0.6 -- TODO: update these to use GetScreenWidth and GetScreenHeight to account for different monitors and fullscreen and such
    local y = 5

    if bagCount(bagContent) < 8 then
        f:DrawString("Need 8 pickups!", x,y,KColor(1,1,1,255),0,true)
        return
    end

    local yOffset = 0
    local yShift = 7

    -- round about way to display the items in the correct order 
    local order = {}
    local ind = 1
    f:DrawString("Select Recipe:", x, y, KColor(1,1,1,255),0,true)
    for k,v in pairs(bagContent) do
        if v == 0 then
            goto continue
        end

        table.insert(order, k)

        ::continue::
    end

    table.sort(order)

    for k,v in ipairs(order) do
        yOffset = yOffset + yShift

        if selection == v then
            f:DrawString(pickupNameLookup[v]..": "..recipe[v].." ("..bagContent[v]..")", x, y+yOffset, KColor(0,1,0,255), 0 , true)
        else
            f:DrawString(pickupNameLookup[v]..": "..recipe[v].." ("..bagContent[v]..")", x, y+yOffset, KColor(1,1,1,255), 0 , true)
        end

    end
end

-- Render a table that displays the current contents of the bag
function bag.onRender(t)
    -- Override EID display, the bag's content will override the inventory display of EID
    local hasBag, bagPlayer = EID:PlayersHaveCollectible(BagId)
    if hasBag then
        EID.bagPlayer = bagPlayer
        -- EID.ShowCraftingResult = true
        EID.BoC.BagItemsOverride = {}
        for item,quantity in pairs(recipe) do
            for i = 1, quantity do
                table.insert(EID.BoC.BagItemsOverride, item)
            end
        end

        EID.BoC.InventoryOverride = {}
        for item,quantity in pairs(bagContent) do
            for i = recipe[item]+1, quantity do
                table.insert(EID.BoC.InventoryOverride, item)
            end
        end

        -- Rendering overrides for EID are FUNKY! Still not working how I would like
        EID:handleBagOfCraftingUpdating()
        EID:handleBagOfCraftingRendering(false)
        if not EID.isDisplaying then
            EID:printDescriptions(false)
        end

        if guiMode then
            if bagOut == 0 then -- failsafe for a softlock
                guiMode = false
                bagPlayer.ControlsEnabled = true
            else
                renderGUI()
            end
        end
    end
end

local function showCraftingText(player, id) -- helper function to display item text when you craft, broken for some reason
    local game = Game()
    local hud = game:GetHUD()
    local itemConfig = Isaac.GetItemConfig()

    local itemConfigItem = itemConfig:GetCollectible(id)
    hud:ShowItemText(player, itemConfigItem)
  end

-- Check if the player is holding down USEITEM to attempt a craft
local holding = 0 -- how long has the player held
local holdTime = 1.5*60 -- how many frames to hold for
function bag.getInput(t)
    local player = game:GetPlayer(0)
    local slotButton = nil
    
    if bagSlot == ActiveSlot.SLOT_POCKET then
        slotButton = ButtonAction.ACTION_PILLCARD
    else 
        slotButton = ButtonAction.ACTION_ITEM
    end

    if Input.IsActionPressed(slotButton,0) then
        holding = holding + 1
    else
        holding = 0
    end

    if holding == holdTime and #EID.BoC.BagItemsOverride == 8 then -- Handle giving the crafted item
        local itemConfig = Isaac.GetItemConfig()
        local resultId = EID:calculateBagOfCrafting(EID.BoC.BagItemsOverride)

        for item,quantity in pairs(recipe) do -- subtract used recipe from the bag content
            if bagContent[item] ~= nil then
                bagContent[item] = bagContent[item] - quantity
            end
        end

        for i=1,27 do -- reset recipe to all zero
            recipe[i]=0
        end

        player:AnimateCollectible(resultId)
        --showCraftingText(player, resultId)
        SFXManager():Play(SoundEffect.SOUND_CHOIR_UNLOCK, 0.9, 0, false, 1)
        player:AddCollectible(resultId)
    end

    if (bagOut==1) and Input.IsActionTriggered(ButtonAction.ACTION_MAP,0) then -- detect when to enter the recipe GUI
        if not guiMode then
            guiMode = true
            player.ControlsEnabled = false
        else
            guiMode = false
            player.ControlsEnabled = true
        end
    end

    if guiMode and bagCount(bagContent) >= 8 then -- checking if bag content has at least 8 items guarantees while loop exits 
        while bagContent[selection] == nil do -- move selection cursor to first available item in the bag
            selection = selection + 1
            if selection > 27 then -- failsafe wrap around
                selection = 0
            end
        end

        if selection < 27 and Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN,0) then
            selection = selection + 1
            while bagContent[selection] == nil or bagContent[selection] == 0 do -- skip over entries not in the bag
                selection = selection + 1
                if selection > 27 then
                    selection = 0
                end
            end
        elseif selection > 0 and Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP,0) then
            selection = selection - 1
            while bagContent[selection] == nil or bagContent[selection] == 0 do -- skip over entries not in the bag
                selection = selection - 1
                if selection < 0 then
                    selection = 27
                end
            end
        end

        if recipe[selection] < bagContent[selection] and #EID.BoC.BagItemsOverride < 8 and Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT,0) then
            recipe[selection] = recipe[selection] + 1
        elseif recipe[selection] > 0 and Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT,0) then
            recipe[selection] = recipe[selection] - 1
        end
    end
end

-- Handle starting as Tainted Cain
function bag.TaintedCainInit(_)
    local player = Isaac.GetPlayer()
    if player:GetPlayerType() ~= PlayerType.PLAYER_CAIN_B then
        return
    end
    if player:GetActiveItem(ActiveSlot.SLOT_POCKET) ~= BagId then
        player:SetPocketActiveItem(BagId, ActiveSlot.SLOT_POCKET, true)
    end
end

function bag.reset(_, isContinued)
    if isContinued then
        return
    end
    bagContent = {}
    for i=1,27 do -- init recipe to all zero
        recipe[i]=0
    end
    bagOut = 0
    guiMode = false
    selection = 0
end

return bag