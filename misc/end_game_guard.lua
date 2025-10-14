MP = MP or {}
MP.UTILS = MP.UTILS or {}

local function get_enemy_label()
        if type(localize) == "function" then
                local ok, result = pcall(localize, "k_enemy_jokers")
                if ok then return result end
        end
        return "k_enemy_jokers"
end

function MP.UTILS.should_block_enemy_joker_sale(card)
        if not card or not MP.end_game_jokers or not MP.end_game_jokers_text then return false end

        local enemy_label = get_enemy_label()
        if enemy_label and MP.end_game_jokers_text ~= enemy_label then return false end

        if card.area and card.area == MP.end_game_jokers then return true end

        if MP.end_game_jokers.cards then
                for _, enemy_card in pairs(MP.end_game_jokers.cards) do
                        if enemy_card == card then return true end
                end
        end

        return false
end

return MP.UTILS.should_block_enemy_joker_sale
