-- Load mod
BoM = RegisterMod("Bag of Manufacturing", 1)

BoM.bagId = Isaac.GetItemIdByName("Bag of Manufacturing")
BoM.bagAnim = Isaac.GetEntityVariantByName("Bag of Manufacturing")

-- Load bag code
local bag = require("scripts/bag")

-- Bag callback
BoM:AddCallback(ModCallbacks.MC_USE_ITEM, bag.use, BoM.bagId)
BoM:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE,  bag.swing, BoM.bagAnim)
BoM:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, bag.newRoom)
BoM:AddCallback(ModCallbacks.MC_POST_RENDER, bag.onRender)
BoM:AddCallback(ModCallbacks.MC_POST_RENDER, bag.getInput)
BoM:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, bag.TaintedCainInit)
BoM:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, bag.reset)
BoM:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, bag.saveData)

-- If EID is detected, add a special description
if EID then
    EID:addCollectible(BoM.bagId, "An upgraded version of the Bag of Crafting.")
end