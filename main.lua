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

  local function addLeafeon()
    local Pokemon = require("src.core.game3.pokemon")
    local ItemsData = require("src.core.game3.items_data")
    local eevee = Pokemon.speciesFromNational(133)
    local leafeon = Pokemon.speciesFromNational(470)
    local leafStone = ItemsData.toNumericId("leaf-stone")
    if not eevee or not leafeon or not leafStone then return end
    Pokemon._evolutions = Pokemon._evolutions or {}
    local rows = Pokemon._evolutions[eevee] or {}
    Pokemon._evolutions[eevee] = rows
    for _, row in ipairs(rows) do
      if tonumber(row.target) == leafeon then return end
    end
    rows[#rows + 1] = { method = 7, param = leafStone, target = leafeon }
  end

  local function addEeveeRows()
    local Pokemon = require("src.core.game3.pokemon")
    local eevee = Pokemon.speciesFromNational(133)
    if not eevee then return end
    Pokemon._evolutions = Pokemon._evolutions or {}
    local rows = Pokemon._evolutions[eevee] or {}
    Pokemon._evolutions[eevee] = rows
    local wanted = { 196, 197, 471 }
    for _, nat in ipairs(wanted) do
      local target = Pokemon.speciesFromNational(nat)
      if target then
        local found = false
        for _, row in ipairs(rows) do
          if tonumber(row.target) == target then found = true break end
        end
        if not found then rows[#rows + 1] = { method = 4, param = 1, target = target } end
      end
    end
  end

  local EXTRA_LEVEL_EVOLUTIONS = {
    { source = 82, target = 462, level = 45 }, -- Magneton -> Magnezone
    { source = 193, target = 469, level = 40 }, -- Yanma -> Yanmega
    { source = 299, target = 476, level = 40 }, -- Nosepass -> Probopass
    { source = 315, target = 407, level = 40 }, -- Roselia -> Roserade
    { source = 190, target = 424, level = 32 }, -- Aipom -> Ambipom
    { source = 200, target = 429, level = 38 }, -- Misdreavus -> Mismagius
    { source = 198, target = 430, level = 38 }, -- Murkrow -> Honchkrow
    { source = 215, target = 461, level = 40 }, -- Sneasel -> Weavile
    { source = 108, target = 463, level = 33 }, -- Lickitung -> Lickilicky
    { source = 114, target = 465, level = 38 }, -- Tangela -> Tangrowth
    { source = 176, target = 468, level = 40 }, -- Togetic -> Togekiss
    { source = 207, target = 472, level = 40 }, -- Gligar -> Gliscor
    { source = 221, target = 473, level = 40 }, -- Piloswine -> Mamoswine
    { source = 281, target = 475, level = 30 }, -- male Kirlia -> Gallade
    { source = 361, target = 478, level = 42 }, -- female Snorunt -> Froslass
  }

  local function addExtraLevelEvolutions()
    local Pokemon = require("src.core.game3.pokemon")
    Pokemon._evolutions = Pokemon._evolutions or {}
    for _, spec in ipairs(EXTRA_LEVEL_EVOLUTIONS) do
      local source = Pokemon.speciesFromNational(spec.source)
      local target = Pokemon.speciesFromNational(spec.target)
      if source and target then
        local rows = Pokemon._evolutions[source] or {}
        Pokemon._evolutions[source] = rows
        local found = false
        for _, row in ipairs(rows) do
          if tonumber(row.method) == 4 and tonumber(row.target) == target then
            row.param = spec.level
            found = true
            break
          end
        end
        if not found then
          rows[#rows + 1] = { method = 4, param = spec.level, target = target }
        end
      end
    end
  end

  local function addEeveeEvolutions()
    addLeafeon()
    addEeveeRows()
    addExtraLevelEvolutions()
  end

  mod.events:on("game.ready", function()
    addEeveeEvolutions()
    local Pokemon = require("src.core.game3.pokemon")
    if Pokemon.onReload then
      Pokemon.onReload(addEeveeEvolutions, "level_up_trade_evolutions")
    end
  end)

  mod.hooks:wrap("evolution.check", function(next, game, mon, evo, trigger)
    local normal = next()
    if not trigger or trigger.kind ~= "levelup" then return normal end

    local Pokemon = require("src.core.game3.pokemon")
    local source = Pokemon.speciesOf(mon) or tonumber(mon and (mon.species or mon.speciesId))
    local sourceNat = source and Pokemon.national and tonumber(Pokemon.national(source))
    local target = tonumber(evo and evo.speciesId)
    local targetNat = target and Pokemon.national and tonumber(Pokemon.national(target))

    -- Preserve the Gen IV gender split while replacing the unavailable Dawn Stone.
    if sourceNat == 281 then
      local female = mon.gender == 1 or mon.gender == "female" or mon.isFemale == true
      if targetNat == 475 then return not female and (tonumber(mon.level) or 1) >= 30 end
      if targetNat == 282 and not female and (tonumber(mon.level) or 1) >= 30 then return false end
    elseif sourceNat == 361 then
      local female = mon.gender == 1 or mon.gender == "female" or mon.isFemale == true
      if targetNat == 478 then return female and (tonumber(mon.level) or 1) >= 42 end
      if targetNat == 362 and female and (tonumber(mon.level) or 1) >= 42 then return false end
    end

    if sourceNat == 133 and (targetNat == 196 or targetNat == 197 or targetNat == 471) then
      local held = numericItem(mon.item or mon.heldItem)
      if targetNat == 471 then return held == numericItem("never-melt-ice") end
      if held ~= numericItem("soothe-bell") then return false end
      local t = os.date("*t")
      local minutes = t.hour * 60 + t.min
      local period
      if minutes >= 4 * 60 and minutes < 10 * 60 then
        period = "morning"
      elseif minutes >= 10 * 60 and minutes < 18 * 60 then
        period = "day"
      else
        period = "night"
      end
      if targetNat == 196 then return period ~= "night" end
      return period == "night"
    end

    if normal then return true end

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
