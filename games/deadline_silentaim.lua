local Config = {
    Enabled = true,
    HitChance = 100,
    MaxDistance = 300,
    BulletOffset = Vector3.new(0, 0, 0),
    BulletSpeed = 1000,
    TargetPart = "head",
    CharacterFolder = "characters"
}

local replicated_storage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local modules = {}
local old_fire_server = nil

local function get_closest_player()
    local closest_distance = Config.MaxDistance
    local closest_player = nil
    local char_folder = workspace:FindFirstChild(Config.CharacterFolder)
    
    if not char_folder then return nil end

    for _, player in char_folder:GetChildren() do
        if not player:FindFirstChild("hitbox") or not player:FindFirstChild(Config.TargetPart) then
            continue
        end
        
        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local position, on_screen = camera:WorldToViewportPoint(player.hitbox.Position)
        
        if not on_screen then
            continue
        end
        
        local distance = (center - Vector2.new(position.X, position.Y)).Magnitude
        if distance > closest_distance then
            continue
        end
        
        closest_distance = distance
        closest_player = player
    end
    
    return closest_player
end

for _, module in replicated_storage.module:GetDescendants() do
    if string.find(module.ClassName, "Script") then
        modules[module.Name] = module
    end
end

local caster = require(modules.caster)

for _, upvalue in debug.getupvalues(caster.fire) do
    if typeof(upvalue) == "function" then
        local constants = debug.getconstants(upvalue)
        if constants[1] == "pcall" and constants[9] == "kill yourself" then
            hookfunction(upvalue, function()
                return
            end)
        end
    end
end

old_fire_server = hookfunction(caster.fire, function(self_param, origin_pos, direction, data, ...)
    if not Config.Enabled then
        return old_fire_server(self_param, origin_pos, direction, data, ...)
    end

    local roll = math.random(1, 100)
    if roll <= Config.HitChance then
        local closest_player = get_closest_player()
        if closest_player then
            origin_pos += Config.BulletOffset
            local target_pos = closest_player[Config.TargetPart].Position
            direction = (target_pos - origin_pos).Unit * Config.BulletSpeed
        end
    end
    
    return old_fire_server(self_param, origin_pos, direction, data, ...)
end)

return Config
