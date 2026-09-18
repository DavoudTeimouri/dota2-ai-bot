-- Courier System for AetherWeaver

local Courier = {}

Courier.sharedTangos = {}  -- Track shared tango offers

function Courier:Think(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    local courier = bot:GetCourier(0)
    if not courier or courier:IsNull() then return end
    
    local gameTime = DotaTime()
    
    -- Upgrade courier at 3 minutes
    if gameTime > 180 and not courier:HasFlyingCourier() then
        if bot:GetGold() >= 400 then
            bot:ActionImmediate_PurchaseItem("item_flying_courier")
        end
    end
    
    -- Use courier to deliver items
    if courier:IsIdle() then
        -- Transfer items from stash
        bot:ActionImmediate_Courier(courier, COURIER_ACTION_TRANSFER_ITEMS)
    end
    
    -- Share Tango with human allies
    self:ShareTango(bot, gameTime)
    
    -- Ask human for support items (tango, clarity, ward)
    self:AskHumanForSupport(bot, gameTime)
    
    -- Use Lotus Orb on allies
    self:UseLotusOrb(bot)
end

function Courier:ShareTango(bot, gameTime)
    -- Only supports share tango
    local role = self:GetBotRole(bot)
    if role ~= "support" then return end
    
    -- Check every 60 seconds
    if not bot.lastTangoShare then bot.lastTangoShare = 0 end
    if gameTime - bot.lastTangoShare < 60 then return end
    
    local tangoSlot = bot:FindItemSlot("item_tango")
    if tangoSlot < 0 then return end
    
    local tango = bot:GetItemInSlot(tangoSlot)
    if not tango or not tango:IsFullyCastable() then return end
    
    -- Find human ally with low HP/mana in lane
    for _, ally in ipairs(GetTeamPlayers(GetTeam())) do
        if ally ~= bot and not ally:IsIllusion() and ally:IsAlive() then
            local playerID = ally:GetPlayerID()
            if playerID and not PlayerResource:IsFakeClient(playerID) then
                local hpPct = ally:GetHealth() / ally:GetMaxHealth()
                local manaPct = ally:GetMana() / ally:GetMaxMana()
                local dist = (bot:GetAbsOrigin() - ally:GetAbsOrigin()):Length2D()
                
                if dist < 1200 and (hpPct < 0.6 or manaPct < 0.4) then
                    bot:Action_UseAbilityOnEntity(tango, ally)
                    bot.lastTangoShare = gameTime
                    MaybeSay("Here, take a tango!")
                    break
                end
            end
        end
    end
end

function Courier:AskHumanForSupport(bot, gameTime)
    -- Only cores ask for support
    local role = self:GetBotRole(bot)
    if role == "support" then return end
    
    -- Check every 120 seconds
    if not bot.lastSupportAsk then bot.lastSupportAsk = 0 end
    if gameTime - bot.lastSupportAsk < 120 then return end
    
    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    local manaPct = bot:GetMana() / bot:GetMaxMana()
    
    if hpPct < 0.4 or manaPct < 0.3 then
        -- Find human support
        for _, ally in ipairs(GetTeamPlayers(GetTeam())) do
            local playerID = ally:GetPlayerID()
            if playerID and not PlayerResource:IsFakeClient(playerID) then
                local allyRole = self:GetBotRole(ally)
                if allyRole == "support" then
                    local dist = (bot:GetAbsOrigin() - ally:GetAbsOrigin()):Length2D()
                    if dist < 2000 then
                        if hpPct < 0.4 then
                            MaybeSay("Support, I need a tango or heal!")
                        else
                            MaybeSay("Support, I'm out of mana! Clarity please!")
                        end
                        bot.lastSupportAsk = gameTime
                        break
                    end
                end
            end
        end
    end
end

function Courier:UseLotusOrb(bot)
    local lotusSlot = bot:FindItemSlot("item_lotus_orb")
    if lotusSlot < 0 then return end
    
    local lotus = bot:GetItemInSlot(lotusSlot)
    if not lotus or not lotus:IsFullyCastable() then return end
    
    -- Use on ally being targeted by projectiles or debuffed
    for _, ally in ipairs(GetTeamPlayers(GetTeam())) do
        if ally ~= bot and ally:IsAlive() and not ally:IsIllusion() then
            local dist = (bot:GetAbsOrigin() - ally:GetAbsOrigin()):Length2D()
            if dist < lotus:GetCastRange() + 200 then
                -- Check for incoming projectiles or strong debuffs
                if ally:HasModifier("modifier_stunned") or 
                   ally:HasModifier("modifier_silence") or
                   ally:HasModifier("modifier_hex") then
                    bot:Action_UseAbilityOnEntity(lotus, ally)
                    MaybeSay("Lotus Orb on " .. ally:GetUnitName() .. "!")
                    return
                end
            end
        end
    end
end

function Courier:GetBotRole(bot)
    local heroName = bot:GetUnitName()
    local carryHeroes = {"antimage", "juggernaut", "phantom_assassin", "spectre", "medusa"}
    local midHeroes = {"invoker", "storm_spirit", "templar_assassin", "puck", "ember_spirit"}
    local offlaneHeroes = {"centaur", "tidehunter", "dragon_knight", "axe", "mars"}
    
    for _, h in ipairs(carryHeroes) do if heroName:find(h) then return "carry" end end
    for _, h in ipairs(midHeroes) do if heroName:find(h) then return "mid" end end
    for _, h in ipairs(offlaneHeroes) do if heroName:find(h) then return "offlane" end end
    return "support"
end

return Courier