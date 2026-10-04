return function(mod)
  if mod.generation ~= 3 then return end

  local ok, natdex = pcall(function() return mod:find("national_dex_gen3") end)
  if not ok or not natdex then
    mod.log:warn("National Dex Gen 3 is not installed")
  end

  local TRADE_LEVELS = {
    -- Gen 1
    KADABRA = 38,
    MACHOKE = 42,
    GRAVELER = 40,
    HAUNTER = 44,

    -- Gen 2
    POLIWHIRL = 37,
    SLOWPOKE = 37,
    ONIX = 40,
    SCYTHER = 40,
    SEADRA = 40,
    PORYGON = 30,

    -- Gen 3
    CLAMPERL = 35,

    -- Gen 4
    RHYDON = 55,
    ELECTABUZZ = 52,
    MAGMAR = 52,
    PORYGON2 = 45,
    DUSCLOPS = 43,
  }

  local SPECIES_KEYS = {
    [64] = "KADABRA",
    [67] = "MACHOKE",
    [75] = "GRAVELER",
    [93] = "HAUNTER",
    [61] = "POLIWHIRL",
    [79] = "SLOWPOKE",
    [95] = "ONIX",
    [123] = "SCYTHER",
    [117] = "SEADRA",
    [137] = "PORYGON",
    [366] = "CLAMPERL",
    [112] = "RHYDON",
    [125] = "ELECTABUZZ",
    [126] = "MAGMAR",
    [233] = "PORYGON2",
    [356] = "DUSCLOPS",
  }

  local function keyFor(mon)
    local Pokemon = require("src.core.game3.pokemon")
    local species = Pokemon.speciesOf(mon) or tonumber(mon and (mon.species or mon.speciesId))
    if not species then return nil end
    local nat = Pokemon.national and Pokemon.national(species)
    return SPECIES_KEYS[tonumber(nat)]
  end

  local function tradeMethod(evo)
    local method = evo and (evo.methodId or evo.method)
    if tonumber(method) == 5 then return "trade" end
    if tonumber(method) == 6 then return "trade_item" end
    if type(method) == "string" then
      method = method:upper()
      if method == "EVO_TRADE" then return "trade" end
      if method == "EVO_TRADE_ITEM" then return "trade_item" end
    end
    return nil
  end

  local LEVEL_ONLY_TRADE_ITEM = {
    RHYDON = true,
    ELECTABUZZ = true,
    MAGMAR = true,
    PORYGON2 = true,
    DUSCLOPS = true,
  }

  local function numericItem(raw)
    if raw == nil then return 0 end
    local n = tonumber(raw)
    if n then return n end
    local ok, ItemsData = pcall(require, "src.core.game3.items_data")
    if ok and ItemsData and ItemsData.toNumericId then
      local ok2, id = pcall(ItemsData.toNumericId, raw)
      if ok2 and tonumber(id) then return tonumber(id) end
    end
    return 0
  end

  mod.hooks:wrap("evolution.check", function(next, game, mon, evo, trigger)
    local normal = next()
    if normal then return true end
    if not trigger or trigger.kind ~= "levelup" then return false end

    local method = tradeMethod(evo)
    if not method then return false end

    local key = keyFor(mon)
    local level = key and TRADE_LEVELS[key]
    if not level or (tonumber(mon.level) or 1) < level then return false end

    if method == "trade_item" and not LEVEL_ONLY_TRADE_ITEM[key] then
      local required = numericItem(evo.param or evo.item)
      local held = numericItem(mon.item or mon.heldItem)
      return required ~= 0 and held == required
    end

    return true
  end)

  mod.exports.tradeLevels = function()
    local copy = {}
    for species, level in pairs(TRADE_LEVELS) do copy[species] = level end
    return copy
  end
end
