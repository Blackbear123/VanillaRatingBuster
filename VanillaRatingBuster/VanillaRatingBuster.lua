
scoredItemTypes = { 
  INVTYPE_2HWEAPON, INVTYPE_CHEST, INVTYPE_CLOAK,
  INVTYPE_FEET, INVTYPE_FINGER, INVTYPE_HAND, INVTYPE_HEAD, INVTYPE_HOLDABLE,
  INVTYPE_LEGS, INVTYPE_NECK, INVTYPE_RANGED, INVTYPE_RELIC, INVTYPE_ROBE, INVTYPE_SHIELD,
  INVTYPE_SHOULDER, INVTYPE_TRINKET, INVTYPE_WAIST, INVTYPE_WEAPON,
  INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND, INVTYPE_WRIST,
  -- deDE
  "Schusswaffe", "Zauberstab", "Armbrust",
  -- enGB
  "Gun", "Wand", "Crossbow" 
}


function istable(t)
  return type(t) == 'table'
end


function VRBRound(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end


function VRBCheckItemType(slot)
  for id, scoredSlot in pairs(scoredItemTypes) do
    if slot == scoredSlot then
      return true
    end
  end
  return nil
end


function VRBGetValidRatings()
  local ratings = {}
  local class = UnitClass("player")

  if class == "Druid" then
    ratings = { "DruidHEP", "DruidHEP2", "DruidCatDPS", "DruidCatAPValue", "DruidBearTank" }
  elseif class == "Warrior" then
    ratings = { "WarriorProtEH", "WarriorProtAvoidance", "WarriorArmsDPS", "WarriorFuryDPS"}
  elseif class == "Shaman" then
    ratings = { "ShamanHEP" }
  elseif class == "Priest" then
    ratings = { "Priest2MINHEP", "Priest15MINHEP", "Priest2MINHEPT2", "Priest15MINHEPT2" } 
  end

  return ratings

end


function VRBCalculateRating(weightTable, bonuses)

  local baseScore = 0
  local bonus, i;
  local weightTypes = VRB_WEIGHTS_HEP[weightTable]
  local currentBonus = 0

  for t,w in pairs(weightTypes) do
  
    if (BonusScanner.bonuses[t]) then
      currentBonus = BonusScanner.bonuses[t]
    end

    if(bonuses[t]) then
      -- Now check if the weight is a compound structure; has a threshold
      if istable(w) then
        threshold = w[1]
        beforeWeight = w[2]
        afterWeight = w[3]
        if tonumber(currentBonus) < tonumber(threshold) then
          baseScore = baseScore + ( bonuses[t] * beforeWeight )
        else
          baseScore = baseScore + ( bonuses[t] * afterWeight )
        end
      else
        baseScore = baseScore + ( bonuses[t] * w )
      end
    end

  end

  return VRBRound(baseScore, 2) 

end


VRBItemScoreTooltip = CreateFrame( "Frame" , "VRBItemScoreTooltip", GameTooltip )
VRBItemScoreTooltip:SetScript("OnShow", function (self)
    local itemLevel = nil
    local itemRarity = nil
    local itemSlot = nil
    local bonuses = nil
    local tmpTxt, line;
    local lines = GameTooltip:NumLines();

    BonusScanner.temp.sets = {};
    BonusScanner.temp.set = "";
    BonusScanner.temp.bonuses = {};
    BonusScanner.temp.slot = "";

    local lbl = getglobal("GameTooltipTextLeft1")
    if lbl then

      for i=2, lines, 1 do
        tmpText = getglobal("GameTooltipTextLeft"..i);
        val = nil;
        if (tmpText:GetText()) then
          line = tmpText:GetText();
          BonusScanner:ScanLine(line);
        end
      end

      bonuses = BonusScanner.temp.bonuses;

      if(bonuses) then

        local ratings = VRBGetValidRatings()
        local className, classFileName = UnitClass("player")
        local color = RAID_CLASS_COLORS[classFileName]

        for i, r in ipairs(ratings) do
          vrbscore = VRBCalculateRating(r, bonuses)
          if vrbscore > 0 then
            normalizedLabel = string.gsub(r, className, "")
            GameTooltip:AddLine(normalizedLabel .. ": " .. vrbscore, color.r, color.g, color.b)
            GameTooltip:Show()          
          end
        end

      end

    end

  end)


SLASH_VRBSCORE1, SLASH_VRBSCORE2 = '/vrb';
