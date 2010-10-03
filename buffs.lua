WeakAuras.RegisterMany(
  {
    id = "Hot Streak texture",
    regionType = "texture",
    texture = "Interface\\Addons\\PowerAuras\\Auras\\Aura23",
    width = 235,
    height = 235,
    rotation = 180,
    color = {1, 0, 0, 0.75},
    blendMode = "BLEND",
    yOffset = 100,
    trigger = {
      type = "aura",
      name = "Hot Streak",
      unit = "player",
      debuffType = "HELPFUL"
    },
    load = {
      player = "Mirrored"
    }
  },
  {
    id = "Hot Streak",
    regionType = "aurabar",
    width = 200,
    height = 15,
    orientation = "HORIZONTAL",
    barColor = {1, 0, 0},
    icon = true,
    cooldown = true,
    timer = true,
    bar = true,
    alpha = 0.7,
    trigger = {
      type = "aura",
      name = "Hot Streak",
      unit = "player",
      debuffType = "HELPFUL"
    },
    load = {
      player = "Mirrored"
    }
  },
  {
    id = "Living Bomb",
    regionType = "aurabar",
    width = 200,
    height = 15,
    orientation = "HORIZONTAL",
    barColor = {1, 0.75, 0},
    icon = true,
    cooldown = true,
    timer = true,
    bar = true,
    yOffset = -17,
    alpha = 0.7,
    trigger = {
      type = "aura",
      name = "Living Bomb",
      unit = "target",
      debuffType = "HARMFUL",
      ownOnly = true
    },
    load = {
      player = "Mirrored"
    }
  },
  {
    id = "Pushing the Limit",
    regionType = "aurabar",
    width = 200,
    height = 15,
    orientation = "HORIZONTAL",
    barColor = {0, 0.75, 1},
    icon = true,
    cooldown = true,
    timer = true,
    bar = true,
    yOffset = -34,
    alpha = 0.7,
    trigger = {
      type = "aura",
      name = "Pushing the Limit",
      unit = "player",
      debuffType = "HELPFUL",
      ownOnly = true
    },
    load = {
      player = "Mirrored"
    }
  },
  {
    id = "Quad Core",
    regionType = "aurabar",
    width = 200,
    height = 15,
    orientation = "HORIZONTAL",
    barColor = {0.1, 0.25, 1},
    icon = true,
    cooldown = true,
    timer = true,
    bar = true,
    yOffset = -51,
    alpha = 0.7,
    trigger = {
      type = "aura",
      name = "Quad Core",
      unit = "player",
      debuffType = "HELPFUL",
      ownOnly = true
    },
    load = {
      player = "Mirrored"
    }
  }
);