package.path = package.path .. ';./?.lua'

local overlay_root_provider

_G.MP = {
  UTILS = {},
  LOBBY = { code = true },
  GAME = { disable_end_screen_selling = true },
}

_G.G = {
  OVERLAY_MENU = nil,
  FUNCS = {},
}

G.FUNCS.overlay_menu = function(args)
  if overlay_root_provider then
    G.OVERLAY_MENU = overlay_root_provider()
  end
  return "original"
end

require('misc.overlay')

local overlay_menu = G.FUNCS.overlay_menu

local function make_node(config)
  local state = { removed = false }
  local node = { config = config or {}, children = {} }
  function node:remove()
    state.removed = true
  end
  return node, function() return state.removed end
end

-- Test 1: sell button removed when flag enabled
MP.GAME.disable_end_screen_selling = true
local sell_node, was_removed = make_node({ button = 'sell_card' })
overlay_root_provider = function()
  return { children = { sell_node } }
end
local result = overlay_menu({})
assert(result == 'original', 'overlay menu should return original result')
assert(was_removed(), 'sell button should be removed when selling disabled')

-- Test 2: sell button stays when flag disabled
MP.GAME.disable_end_screen_selling = false
local sell_node2, was_removed2 = make_node({ button = 'sell_card' })
overlay_root_provider = function()
  return { children = { sell_node2 } }
end
result = overlay_menu({})
assert(result == 'original', 'overlay menu should return original result when flag disabled')
assert(not was_removed2(), 'sell button should remain when selling is allowed')

-- Test 3: nested label containing sell removed
MP.GAME.disable_end_screen_selling = true
local container, container_removed = make_node()
local label_node, label_removed = make_node({ label = 'Sell for $5' })
container.children[1] = label_node
overlay_root_provider = function()
  return { children = { container } }
end
result = overlay_menu({})
assert(result == 'original', 'overlay menu should return original result for nested label')
assert(label_removed(), 'label node mentioning sell should be removed')
assert(not container_removed(), 'parent node without sell metadata should remain')

overlay_root_provider = nil
print('All remove_sell_buttons tests passed')
