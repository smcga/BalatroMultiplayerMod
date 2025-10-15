MP.UTILS = MP.UTILS or {}

local overlay_menu_ref = G.FUNCS.overlay_menu

local function value_contains_sell(value)
	if type(value) == "string" then
		return value:lower():find("sell", 1, true) ~= nil
	elseif type(value) == "table" then
		for _, inner in pairs(value) do
			if value_contains_sell(inner) then return true end
		end
	end
	return false
end

local function should_remove_sell_button(element)
	if not element or not element.config then return false end
	local config = element.config
	if value_contains_sell(config.button) then return true end
	if value_contains_sell(config.func) then return true end
	if value_contains_sell(config.id) then return true end
	if value_contains_sell(config.label) then return true end
	return false
end

function MP.UTILS.remove_sell_buttons_from_overlay()
	if not G or not G.OVERLAY_MENU or not G.OVERLAY_MENU.children then return end

	local function traverse(node)
		if not node then return end
		if should_remove_sell_button(node) then
			if node.remove then node:remove() end
			return
		end
		if node.children then
			for i = #node.children, 1, -1 do
				traverse(node.children[i])
			end
		end
	end

	for i = #G.OVERLAY_MENU.children, 1, -1 do
		traverse(G.OVERLAY_MENU.children[i])
	end
end

function G.FUNCS.overlay_menu(args)
	local result = overlay_menu_ref(args)
	if MP.LOBBY and MP.LOBBY.code and MP.GAME and MP.GAME.disable_end_screen_selling then
		MP.UTILS.remove_sell_buttons_from_overlay()
	end
	return result
end
