local function setup_environment()
    package.loaded["compatibility/TheOrder"] = nil

    _G.create_card = function()
        return {}
    end

    _G.reset_idol_card = function() end
    _G.reset_mail_rank = function() end

    _G.CardArea = {}
    function CardArea:shuffle(_seed)
        return {}
    end

    local sequences = {}

    _G.pseudoseed = function(key)
        return key
    end

    _G.pseudorandom = function(_)
        return 0.1
    end

    _G.pseudorandom_element = function(t, seed)
        local seq = sequences[seed]
        if seq and seq.index <= #seq.values then
            local desired = seq.values[seq.index]
            seq.index = seq.index + 1
            for i, v in ipairs(t) do
                if v == desired then return v, i end
            end
        end
        return t[1], 1
    end

    local voucher_pairs = {
        { base = "v_telescope", upgrade = "v_observatory" },
        { base = "v_blank", upgrade = "v_antimatter" },
    }

    _G.get_current_pool = function(pool_type)
        assert(pool_type == "Voucher", "expected Voucher pool")
        local pool = {}
        for _, pair in ipairs(voucher_pairs) do
            if G.GAME.used_vouchers[pair.base] then
                pool[#pool + 1] = "UNAVAILABLE"
            else
                pool[#pool + 1] = pair.base
            end

            if G.GAME.used_vouchers[pair.upgrade] then
                pool[#pool + 1] = "UNAVAILABLE"
            elseif G.GAME.used_vouchers[pair.base] then
                pool[#pool + 1] = pair.upgrade
            else
                pool[#pool + 1] = pair.upgrade
            end
        end
        return pool
    end

    _G.G = {
        GAME = {
            round_resets = { ante = 3 },
            starting_params = { vouchers_in_shop = 1 },
            modifiers = {},
            stake = 1,
            current_round = {
                idol_card = {},
                mail_card = {},
            },
            pseudorandom = {},
            used_vouchers = {},
            hands = {},
            blind = {
                config = { blind = { key = "" } },
                name = "",
                disabled = false,
            },
        },
        pack_cards = {},
        deck = setmetatable({ cards = {} }, { __index = CardArea }),
        playing_cards = {},
        jokers = { cards = {} },
        hand = {},
        play = {},
    }

    _G.poll_edition = function() end
    _G.sendDebugMessage = function() end

    local booster = {}
    function booster:take_ownership_by_kind(_, _)
        return self
    end

    _G.SMODS = {
        Booster = booster,
        poll_seal = function() end,
        size_of_pool = function(pool)
            return #pool
        end,
    }

    local function base_get_next_vouchers(vouchers)
        vouchers = vouchers or { spawn = {} }
        vouchers.spawn = vouchers.spawn or {}
        local limit = math.min(
            G.GAME.starting_params.vouchers_in_shop + (G.GAME.modifiers.extra_vouchers or 0),
            #get_current_pool("Voucher")
        )
        for i = #vouchers + 1, limit do
            local center = _G.pseudorandom_element(
                get_current_pool("Voucher"),
                _G.pseudoseed("Voucher" .. G.GAME.round_resets.ante)
            )
            vouchers[#vouchers + 1] = center
            vouchers.spawn[center] = true
        end
        return vouchers
    end

    _G.SMODS.get_next_vouchers = base_get_next_vouchers

    _G.get_next_voucher_key = function()
        local pool = get_current_pool("Voucher")
        local center = _G.pseudorandom_element(pool, _G.pseudoseed("Voucher" .. G.GAME.round_resets.ante))
        return center
    end

    _G.SMODS.Rank = { obj_buffer = {} }
    _G.SMODS.Suit = { obj_buffer = {} }

    _G.MP = {
        LOBBY = {
            config = { the_order = true },
            code = "ORDER",
        },
    }

    function MP.should_use_the_order()
        return MP.LOBBY.config.the_order and MP.LOBBY.code
    end

    require("compatibility/TheOrder")

    local function set_sequence(seed, values)
        sequences[seed] = { values = values, index = 1 }
    end

    local function run_shop(order_enabled, used_vouchers, desired)
        sequences = {}
        set_sequence(order_enabled and "Voucher0" or ("Voucher" .. G.GAME.round_resets.ante), { desired })
        MP.LOBBY.config.the_order = order_enabled
        MP.LOBBY.code = "ORDER"
        G.GAME.used_vouchers = used_vouchers
        local vouchers = SMODS.get_next_vouchers({ spawn = {} })
        return vouchers[1]
    end

    return {
        run_shop = run_shop,
    }
end

describe("voucher reroll when higher tier locked", function()
    local env

    before_each(function()
        env = setup_environment()
    end)

    it("with The Order enabled player without Telescope sees Antimatter", function()
        local voucher = env.run_shop(true, { v_blank = true }, "v_antimatter")
        assert.are.equal("v_antimatter", voucher)
    end)

    it("with The Order disabled player without Telescope sees Antimatter", function()
        local voucher = env.run_shop(false, { v_blank = true }, "v_antimatter")
        assert.are.equal("v_antimatter", voucher)
    end)

    it("with The Order enabled player with Telescope sees Observatory", function()
        local voucher = env.run_shop(true, { v_blank = true, v_telescope = true }, "v_observatory")
        assert.are.equal("v_observatory", voucher)
    end)

    it("with The Order disabled player with Telescope sees Observatory", function()
        local voucher = env.run_shop(false, { v_blank = true, v_telescope = true }, "v_observatory")
        assert.are.equal("v_observatory", voucher)
    end)
end)
