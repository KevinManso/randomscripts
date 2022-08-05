local players = game:GetService('Players')
local runService = game:GetService('RunService')
local coreGui = game:GetService('CoreGui')

local client = players.LocalPlayer
local h_parent = coreGui

if type(gethui) == 'function' then h_parent = gethui() end
if type(get_hidden_gui) == 'function' then h_parent = get_hidden_gui() end

local function create(class, properties)
	local object = Instance.new(class)
	for k, v in next, properties do
		object[k] = v;
	end
	return object
end

local function cleaner()
	-- basic cleanup class so we dont have to import maid or broom 
	local tasks = {}
	local function give(task)
		table.insert(tasks, task)
	end
	local function clean()
		for i = #tasks, 1, -1 do
			local task = table.remove(tasks, i)

			if typeof(task) == 'Instance' then task:Destroy() end
			if typeof(task) == 'RBXScriptSignal' then task:Disconnect() end
			if typeof(task) == 'function' then task() end
		end
	end
	return give, clean
end

local chams = {}
local function onPlayerAdded(player)
	-- cleanup functions
	
	local p_give, p_clean = cleaner() -- player shit
	local c_give, c_clean = cleaner() -- character shit

	local function onCharacterAdded(character)
		c_clean()

		local highlight = create('Highlight', {
			Adornee = character,
			Parent = h_parent,
		})

		local storage = { player, highlight }

		c_give(highlight)
		c_give(function()
			local index = table.find(chams, storage)
			if index then
				table.remove(chams, index)
			end
		end)

		table.insert(chams, storage)
	end

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end

	p_give(player.CharacterAdded:Connect(onCharacterAdded))
	p_give(player:GetPropertyChangedSignal('Parent'):Connect(function()
		if player.Parent ~= players then
			p_clean()
			c_clean()
		end
	end))

end

for _, player in next, players:GetPlayers() do
	if player ~= client then
		task.spawn(onPlayerAdded, player)
	end
end

players.PlayerAdded:Connect(onPlayerAdded)

local function fail(r) client:Kick(r) end

-- just dont let this shit err
local success, response = pcall(game.HttpGet, game, 'https://raw.githubusercontent.com/wally-rblx/uwuware-ui/main/main.lua')
if not success then return fail'cant load ui library (httpget)' end

local fn, err = loadstring(response, '@uwuware-ui')
if not fn then return fail'cant load ui library (loadstring)' end

local _, library = pcall(fn)
if not _ then return fail'cant load ui library (error: ' .. tostring(library) .. ')' end

local window = library:CreateWindow('Player chams')

window:AddToggle({ text = 'Enabled', flag = 'enabled' })
window:AddToggle({ text = 'Use team colors', flag = 'teamColors' })
window:AddToggle({ text = 'Show teammates', flag = 'showTeams' })

window:AddColor({ text = 'Enemies', flag = 'enemyColor', color = Color3.fromRGB(255, 25, 25) })
window:AddColor({ text = 'Enemies (outline)', flag = 'enemyOutlineColor', color = Color3.new() })

window:AddColor({ text = 'Teammates', flag = 'allyColor', color = Color3.fromRGB(0, 255, 140) })
window:AddColor({ text = 'Teammates (outline)', flag = 'allyOutlineColor', color = Color3.new() })

window:AddSlider({ text = 'Transparency', min = 0, max = 1, value = 0, flag = 'transparency', float = 0.1 })
window:AddSlider({ text = 'Outline transparency', min = 0, max = 1, value = 0, flag = 'outlineTransparency', float = 0.1 })

library:Init()

runService.Stepped:Connect(function()
	for i = 1, #chams do
		local store = chams[i]
		local plr, highlight = store[1], store[2]

		local isSameTeam = plr.Team == client.Team
		local plrColor = (isSameTeam and library.flags.allyColor or library.flags.enemyColor)
		local plrOutlineColor = (isSameTeam and library.flags.allyOutlineColor or library.flags.enemyOutlineColor)

		local doesShow = library.flags.enabled 

		if library.flags.teamColors then plrColor = plr.TeamColor end
		if library.flags.showTeams then doesShow = isSameTeam end

		highlight.Enabled = doesShow
		
		highlight.FillColor = plrColor
		highlight.OutlineColor = plrOutlineColor

		highlight.FillTransparency = library.flags.transparency
		highlight.OutlineTransparency = library.flags.outlineTransparency
	end
end)
