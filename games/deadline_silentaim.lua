-- forever w/ dementiaenjoyer luv <3
local config = {
    enabled = true,
    hit_chance = 100,
    max_distance = 300,
    bullet_offset = Vector3.new(0, 0, 0),
    
    target_part = "head",
    character_folder = "characters",

    use_custom_speed = true,
    bullet_speed = 1000,
    
    use_multishot = true,
    bullet_amount = 3,

    on_shoot = function(target_player, origin, direction)
        
    end
}

local replicated_storage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local modules = {}
local old_fire_server = nil

local function get_closest_player()
    local closest_distance = config.max_distance
    local closest_player = nil
    local char_folder = workspace:FindFirstChild(config.character_folder)
    
    if not char_folder then return nil end

    for _, player in char_folder:GetChildren() do
        if not player:FindFirstChild("hitbox") or not player:FindFirstChild(config.target_part) then
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
    local closest_player = nil
    
    if config.enabled then
        local roll = math.random(1, 100)
        
        if roll <= config.hit_chance then
            closest_player = get_closest_player()
            if closest_player then
                origin_pos += config.bullet_offset
                local target_pos = closest_player[config.target_part].Position
                
                local speed = config.use_custom_speed and config.bullet_speed or direction.Magnitude
                direction = (target_pos - origin_pos).Unit * speed
            end
        elseif config.use_custom_speed then
            direction = direction.Unit * config.bullet_speed
        end
    else
        if config.use_custom_speed then
            direction = direction.Unit * config.bullet_speed
        end
    end
    
    if typeof(config.on_shoot) == "function" then
        task.spawn(config.on_shoot, closest_player, origin_pos, direction)
    end
    
    if config.use_multishot and config.bullet_amount > 1 then
        for i = 1, (config.bullet_amount - 1) do
            old_fire_server(self_param, origin_pos, direction, data, ...)
        end
    end
    
    return old_fire_server(self_param, origin_pos, direction, data, ...)
end)

return config
