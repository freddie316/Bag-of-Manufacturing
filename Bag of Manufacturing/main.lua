-- Load mod
local mod = RegisterMod("Bag of Manufacturing", 1)

mod.bagId = Isaac.GetItemIdByName("Bag of Manufacturing")
mod.bagAnim = Isaac.GetEntityVariantByName("Bag of Manufacturing")

-- Load bag code
local bag = require("scripts/bag")

-- Bag callback
mod:AddCallback(ModCallbacks.MC_USE_ITEM, bag.use, mod.bagId)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE,  bag.swing, mod.bagAnim)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, bag.newRoom)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, bag.onRender)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, bag.getInput)

-- If EID is detected, add a special description
if EID then
    EID:addCollectible(mod.bagId, "An upgraded version of the Bag of Crafting.")
end