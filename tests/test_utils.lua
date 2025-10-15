SMODS = {
    Mods = {
        Multiplayer = {
            config = {
                username = '',
                blind_col = 1,
                preview = {},
                weekly = false,
            }
        }
    },
    create_mod_badges = function() end,
    calculate_context = function() end,
}
SMODS.ModInstances = {}
MP = { ACTIONS = { set_username = function() end, set_blind_col = function() end }, LOBBY = { code = false }, GAME = { stats = { reroll_count = 0, reroll_cost_total = 0 }, enemy = { sells_per_ante = {} } } }
G = { FUNCS = { reroll_shop = function() end, buy_from_shop = function() end, use_card = function() end }, GAME = { current_round = { reroll_cost = 0 }, starting_params = { joker_slots = 0 } }, CARD_W = 1, CARD_H = 1, P_CENTERS = {}, E_MANAGER = { add_event = function() end }, SETTINGS = {} }
Card = { sell_card = function() end }
function Card:is() return false end
sendTraceMessage = function() end
love = { system = { setClipboardText = function() end, getClipboardText = function() return '' end } }
dofile('misc/utils.lua')

local tests_run, tests_failed = 0, 0

local function assertTrue(condition, message)
    if not condition then error(message or 'Assertion failed', 2) end
end

local function run_test(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        tests_failed = tests_failed + 1
        io.stderr:write(string.format("Test '%s' failed: %s\n", name, err))
    else
        tests_run = tests_run + 1
    end
end

run_test('hide_sell_button removes button via remove', function()
    local removed = false
    local card = { children = {} }
    local use_button = {}
    function use_button:remove()
        removed = true
    end
    card.children.use_button = use_button

    MP.UTILS.hide_sell_button(card)

    assertTrue(removed, 'Expected remove to be called')
    assertTrue(card.children.use_button == nil, 'Expected use button reference to be cleared')
end)

run_test('hide_sell_button removes button via remove_self', function()
    local removed = false
    local card = { children = {} }
    local use_button = {}
    function use_button:remove_self()
        removed = true
    end
    card.children.use_button = use_button

    MP.UTILS.hide_sell_button(card)

    assertTrue(removed, 'Expected remove_self to be called')
    assertTrue(card.children.use_button == nil, 'Expected use button reference to be cleared')
end)

run_test('hide_sell_button hides button without removal helpers', function()
    local card = { children = { use_button = { visible = true, config = { visible = true } } } }

    MP.UTILS.hide_sell_button(card)

    assertTrue(card.children.use_button.visible == false, 'Expected use button to be hidden')
    assertTrue(card.children.use_button.config.visible == false, 'Expected config visibility to be hidden')
end)

run_test('hide_sell_button falls back to sell_button child', function()
    local removed = false
    local card = { children = { sell_button = {} } }
    function card.children.sell_button:remove()
        removed = true
    end

    MP.UTILS.hide_sell_button(card)

    assertTrue(removed, 'Expected remove to be called on sell button')
    assertTrue(card.children.sell_button == nil, 'Expected sell button reference to be cleared')
end)

run_test('hide_sell_button handles nil card', function()
    MP.UTILS.hide_sell_button(nil)
    MP.UTILS.hide_sell_button({})
    assertTrue(true)
end)

if tests_failed > 0 then
    io.stderr:write(string.format("%d tests failed, %d passed\n", tests_failed, tests_run))
    os.exit(1)
else
    print(string.format("All %d tests passed.", tests_run))
end
