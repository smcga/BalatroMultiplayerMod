local function assert_equals(actual, expected, message)
        if actual ~= expected then
                error((message or "Assertion failed") .. string.format(" (expected: %s, actual: %s)", tostring(expected), tostring(actual)))
        end
end

MP = { end_game_jokers = {}, end_game_jokers_text = nil }

localize = function(key)
        return key
end

dofile("misc/end_game_guard.lua")

local guard = MP.UTILS.should_block_enemy_joker_sale

local enemy_area = { cards = {} }
local enemy_card = { area = enemy_area }

MP.end_game_jokers = enemy_area
MP.end_game_jokers_text = "k_enemy_jokers"

assert_equals(guard(enemy_card), true, "Enemy joker in enemy area should be blocked")

MP.end_game_jokers_text = "k_your_jokers"
assert_equals(guard(enemy_card), false, "Enemy joker should be sellable when viewing your jokers")

MP.end_game_jokers_text = "k_enemy_jokers"
enemy_card.area = nil
enemy_area.cards = { enemy_card }
assert_equals(guard(enemy_card), true, "Enemy joker in saved list should be blocked")

enemy_area.cards = {}
assert_equals(guard({}), false, "Non enemy joker should not be blocked")

print("All end_game_guard tests passed")
