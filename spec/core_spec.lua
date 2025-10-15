local function prepare_environment()
    package.loaded["core"] = nil
    _G.MP = nil
    _G.MP_SKIP_BOOTSTRAP = true

    _G.sendDebugMessage = function() end
    local warn_log = {}
    _G.sendWarnMessage = function(message)
        table.insert(warn_log, message)
    end

    _G.localize = function(key)
        return "localized:" .. key
    end

    _G.HEX = function(value)
        return value
    end

    _G.G = { C = {}, E_MANAGER = { add_event = function() end } }
    _G.Event = function(def)
        return def
    end
    _G.G.MAIN_MENU_UI = false

    _G.NFS = { getDirectoryItems = function()
        return {}
    end }

    _G.love = {
        thread = {
            newThread = function()
                return {
                    start = function() end,
                }
            end,
        },
    }

    local mods_config = {
        integrations = {
            TheOrder = { enabled = true },
            Preview = { enabled = true },
        },
        preview = {
            text = "Preview text",
            button = "Preview",
        },
        server_url = "localhost",
        server_port = 0,
    }

    local load_calls = {}

    _G.SMODS = {
        current_mod = {
            path = ".",
            lovely = true,
            config = mods_config,
        },
        Mods = {
            ["Multiplayer"] = {
                config = mods_config,
            },
        },
        load_file = function(file, mod)
            table.insert(load_calls, { file = file, mod = mod })
            return function()
                return function() end
            end
        end,
        Atlas = function() end,
    }

    local MP = require("core")
    MP.UTILS = {
        get_username = function()
            return "UnitTester"
        end,
        get_blind_col = function()
            return 1
        end,
        get_weekly = function()
            return nil
        end,
        overlay_message = function() end,
        wrapText = function(text)
            return text
        end,
    }
    MP.INSANE_INT = {
        empty = function()
            return { zero = true }
        end,
    }

    return MP, warn_log, load_calls
end

local function reset_lobby(MP)
    MP.reset_lobby_config()
end

local assert = require("luassert")

local MP
local warn_log
local load_calls

before_each(function()
    MP, warn_log, load_calls = prepare_environment()
    reset_lobby(MP)
end)

describe("MP.should_use_the_order", function()
    it("returns true when lobby has code and the flag is enabled", function()
        MP.LOBBY.config.the_order = true
        MP.LOBBY.code = "ABC123"
        assert.are.equal("ABC123", MP.should_use_the_order())
    end)

    it("returns false when lobby is missing a code", function()
        MP.LOBBY.config.the_order = true
        MP.LOBBY.code = nil
        assert.is_nil(MP.should_use_the_order())
    end)
end)

describe("MP.reset_lobby_config", function()
    it("sets lobby options to defaults", function()
        MP.reset_lobby_config()
        local config = MP.LOBBY.config

        assert.is_true(config.gold_on_life_loss)
        assert.is_false(config.no_gold_on_round_loss)
        assert.is_true(config.death_on_round_loss)
        assert.are.equal("ruleset_mp_blitz", config.ruleset)
        assert.are.equal("gamemode_mp_attrition", config.gamemode)
        assert.are.equal("Red Deck", config.back)
        assert.are.equal("sleeve_casl_none", config.sleeve)
    end)

    it("preserves ruleset and gamemode when asked to persist", function()
        MP.LOBBY.config.ruleset = "ruleset_custom"
        MP.LOBBY.config.gamemode = "gamemode_custom"

        MP.reset_lobby_config(true)
        local config = MP.LOBBY.config

        assert.are.equal("ruleset_custom", config.ruleset)
        assert.are.equal("gamemode_custom", config.gamemode)
    end)
end)

describe("MP.load_mp_file", function()
    it("returns the compiled function on success", function()
        SMODS.load_file = function(file, mod)
            assert.are.equal("example.lua", file)
            assert.are.equal("Multiplayer", mod)
            return function()
                return function()
                    return "loaded"
                end
            end
        end

        local result = MP.load_mp_file("example.lua")
        assert.is_function(result)
        assert.are.equal("loaded", result())
    end)

    it("logs a warning when executing the chunk fails", function()
        SMODS.load_file = function()
            return function()
                error("boom")
            end
        end

        local result = MP.load_mp_file("broken.lua")
        assert.is_nil(result)
        assert.is_true(#warn_log > 0)
        assert.matches("Failed to process file", warn_log[#warn_log])
    end)

    it("logs a warning when the file cannot be loaded", function()
        SMODS.load_file = function()
            return nil, "not found"
        end

        local result = MP.load_mp_file("missing.lua")
        assert.is_nil(result)
        assert.is_true(#warn_log > 0)
        assert.matches("Failed to find or compile file", warn_log[#warn_log])
    end)
end)

describe("MP.load_mp_dir", function()
    it("loads underscore-prefixed files before regular files", function()
        NFS.getDirectoryItems = function()
            return { "alpha.lua", "_init.lua", "readme.md", "zeta.lua", "_pre.lua" }
        end

        local calls = {}
        local original_load = MP.load_mp_file
        MP.load_mp_file = function(path)
            table.insert(calls, path)
            return original_load(path)
        end

        MP.load_mp_dir("objects")

        assert.are.same({ "objects/_init.lua", "objects/_pre.lua", "objects/alpha.lua", "objects/zeta.lua" }, calls)
    end)
end)

describe("core bootstrap guard", function()
    it("skips initialization when MP_SKIP_BOOTSTRAP is set", function()
        assert.are.equal(0, #load_calls)
    end)
end)

describe("MP.reset_game_states", function()
    it("initializes the game state from the lobby configuration", function()
        MP.reset_lobby_config()

        local empty_calls = 0
        MP.INSANE_INT = {
            empty = function()
                empty_calls = empty_calls + 1
                return { id = empty_calls }
            end,
        }

        MP.reset_game_states()

        assert.are.equal(MP.LOBBY.config.starting_lives, MP.GAME.enemy.lives)
        assert.are.equal(MP.LOBBY.config.timer_base_seconds, MP.GAME.timer)
        assert.are.equal("localized:b_ready", MP.GAME.ready_blind_text)
        assert.are.equal(3, empty_calls)
    end)
end)

return true
