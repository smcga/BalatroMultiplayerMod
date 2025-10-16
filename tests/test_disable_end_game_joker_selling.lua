package.path = './?.lua;./?/init.lua;' .. package.path

-- Minimal stubs required by misc/utils.lua
local function noop(...) return ... end

Card = {}
function Card:sell_card()
    return 'original sell'
end

CardArea = {}
function CardArea:emplace(card, location, stay_flipped)
    self.cards = self.cards or {}
    table.insert(self.cards, card)
    return card
end

ease_dollars = function(mod, instant) return mod, instant end
sendTraceMessage = noop

love = { system = { setClipboardText = noop, getClipboardText = function() return '' end } }

local dummy_font = { FONT = { getWidth = function() return 1 end }, FONTSCALE = 1 }

G = {
    C = {
        UI = { TEXT_LIGHT = {} },
        IMPORTANT = {},
        RED = {},
        BLUE = {},
        WHITE = {},
        FILTER = {},
        L_BLACK = {},
        MULTIPLAYER = {},
        BLACK = {},
        EDITION = {},
    },
    LANG = { font = dummy_font },
    LANGUAGES = { ["en-us"] = { font = dummy_font } },
    localization = { misc = { challenge_names = {} } },
    UIT = { R = {}, C = {}, T = {}, O = {} },
    TILESIZE = 1,
    TILESCALE = 1,
    FUNCS = {
        overlay_menu = noop,
        reroll_shop = noop,
        buy_from_shop = noop,
        use_card = noop,
        evaluate_round = noop,
    },
    GAME = { current_round = { reroll_cost = 0 } },
    E_MANAGER = { add_event = noop },
}

G.CARD_W = 1
G.CARD_H = 1
G.SETTINGS = { F_LOCAL_CLIPBOARD = false }
G.P_CENTERS = {}
G.jokers = { cards = {} }
G.consumeables = { T = { x = 0, y = 0, w = 0, h = 0 } }

localize = function(arg)
    if type(arg) == 'table' then
        if arg.type == 'variable' then
            return { table.concat(arg.vars or {}, ' ') }
        end
    end
    return arg
end

copy_table = function(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = v
    end
    return result
end

SMODS = {
    create_mod_badges = noop,
    Mods = {
        Multiplayer = {
            config = {
                username = '',
                blind_col = 1,
                preview = {},
            },
        },
    },
}

SMODS.calculate_context = noop

MP = {
    ACTIONS = {
        set_username = noop,
        set_blind_col = noop,
    },
    LOBBY = {
        code = true,
        config = {
            preview = {},
        },
    },
    UTILS = {},
}

MP.shared = { cards = {} }

require('misc.utils')

local function new_card(cost)
    local card = { sell_cost = cost, config = {} }
    return setmetatable(card, { __index = Card })
end

local function new_ui_node(config, children)
    local node = {
        config = config or {},
        nodes = children,
    }

    function node:remove()
        self.removed = true
    end

    return node
end

local function assert_true(condition, message)
    if not condition then
        error(message or 'assertion failed', 2)
    end
end

local function test_mark_card_unsellable()
    local card = new_card(5)
    local result = MP.UTILS.mark_card_unsellable(card)
    assert_true(result == card, 'mark_card_unsellable should return the card')
    assert_true(card.mp_disable_selling == true, 'card should be flagged as unsellable')
    assert_true(card.sell_cost == nil, 'sell cost should be cleared')
    assert_true(card.config.can_sell == false, 'card config should disable selling')
end

local function test_mark_card_unsellable_removes_sell_ui()
    local sell_button = new_ui_node({ button = 'card_sell' })
    local sell_label = new_ui_node({ text = '$5' })
    local nested = new_ui_node({}, { sell_label })
    local card = new_card(5)
    card.children = {
        sell = sell_button,
        nested = nested,
    }
    card.T = new_ui_node({}, { new_ui_node({ ref_table = card, ref_value = 'sell_cost' }) })

    MP.UTILS.mark_card_unsellable(card)

    assert_true(card.children.sell == nil, 'sell button should be removed from children')
    assert_true(sell_button.removed == true, 'sell button remove should be invoked')
    assert_true(#nested.nodes == 0, 'nested sell labels should be pruned')
    assert_true(card.T.removed ~= true, 'root node should be preserved')
    assert_true(#card.T.nodes == 0, 'sell cost references should be removed from root nodes')
end

local function test_disable_card_area_selling()
    local area = { config = {}, cards = { new_card(2), new_card(nil) } }
    MP.UTILS.disable_card_area_selling(area)
    assert_true(area.mp_disable_selling == true, 'card area should be flagged as unsellable')
    assert_true(area.config.view_deck == true, 'card area should be set to view-only')
    for _, card in pairs(area.cards) do
        assert_true(card.mp_disable_selling == true, 'cards should be flagged as unsellable')
        assert_true(card.sell_cost == nil, 'sell cost should be cleared from cards')
        assert_true(card.config.can_sell == false, 'card config should disable selling')
    end

    -- Ensure idempotency
    MP.UTILS.disable_card_area_selling(area)
    assert_true(area.mp_disable_selling == true, 'card area flag should remain set after repeated calls')
end

local function test_card_area_emplace_hook()
    local area = { config = {}, cards = {} }
    setmetatable(area, { __index = CardArea })
    MP.UTILS.disable_card_area_selling(area)
    local card = new_card(7)
    area:emplace(card)
    assert_true(card.mp_disable_selling == true, 'cards added after disabling should be marked unsellable')
    assert_true(card.sell_cost == nil, 'sell cost should be cleared for newly added cards')
end

local function test_card_sell_guard()
    local card = new_card(10)
    MP.UTILS.mark_card_unsellable(card)
    local result = card:sell_card()
    assert_true(result == nil, 'selling a guarded card should be prevented')
end

local function run()
    test_mark_card_unsellable()
    test_mark_card_unsellable_removes_sell_ui()
    test_disable_card_area_selling()
    test_card_area_emplace_hook()
    test_card_sell_guard()
    print('All tests passed')
end

run()
