-- much luv w/ dementiaenjoyer <3
local Config = {
    Enabled = true,
    HitChance = 100,
    MaxDistance = 300,
    BulletOffset = Vector3.new(0, 0, 0),
    
    TargetPart = "head",
    CharacterFolder = "characters",

    UseCustomSpeed = true,
    BulletSpeed = 1000,
    
    UseMultishot = true,
    BulletAmount = 3,

    OnShoot = function(TargetPlayer, SelfParam, Data, Origin, Direction, ...)
        
    end
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local Modules = {}
local OldFireServer = nil

local function GetClosestPlayer()
    local ClosestDistance = Config.MaxDistance
    local ClosestPlayer = nil
    local CharFolder = workspace:FindFirstChild(Config.CharacterFolder)
    
    if not CharFolder then
        return nil
    end

    for _, Player in CharFolder:GetChildren() do
        if not Player:FindFirstChild("hitbox") or not Player:FindFirstChild(Config.TargetPart) then
            continue
        end
        
        local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local Position, OnScreen = Camera:WorldToViewportPoint(Player.hitbox.Position)
        
        if not OnScreen then
            continue
        end
        
        local Distance = (Center - Vector2.new(Position.X, Position.Y)).Magnitude
        
        if Distance > ClosestDistance then
            continue
        end
        
        ClosestDistance = Distance
        ClosestPlayer = Player
    end
    
    return ClosestPlayer
end

for _, Module in ReplicatedStorage.module:GetDescendants() do
    if string.find(Module.ClassName, "Script") then
        Modules[Module.Name] = Module
    end
end

local Caster = require(Modules.caster)

for _, Upvalue in debug.getupvalues(Caster.fire) do
    if typeof(Upvalue) == "function" then
        local Constants = debug.getconstants(Upvalue)
        
        if Constants[1] == "pcall" and Constants[9] == "kill yourself" then
            hookfunction(Upvalue, function()
                return
            end)
        end
    end
end

OldFireServer = hookfunction(Caster.fire, function(SelfParam, OriginPos, Direction, Data, ...)
    local ClosestPlayer = nil
    
    if Config.Enabled then
        local Roll = math.random(1, 100)
        
        if Roll <= Config.HitChance then
            ClosestPlayer = GetClosestPlayer()
            
            if ClosestPlayer then
                OriginPos += Config.BulletOffset
                
                local TargetPos = ClosestPlayer[Config.TargetPart].Position
                local Speed = Config.UseCustomSpeed and Config.BulletSpeed or Direction.Magnitude
                
                Direction = (TargetPos - OriginPos).Unit * Speed
                
                -- Update internal data table velocity if it exists
                if type(Data) == "table" and Data.Velocity then
                    Data.Velocity = Direction
                end
            end
        elseif Config.UseCustomSpeed then
            Direction = Direction.Unit * Config.BulletSpeed
            
            if type(Data) == "table" and Data.Velocity then
                Data.Velocity = Direction
            end
        end
    else
        if Config.UseCustomSpeed then
            Direction = Direction.Unit * Config.BulletSpeed
        end
    end
    
    if typeof(Config.OnShoot) == "function" then
        task.spawn(Config.OnShoot, ClosestPlayer, SelfParam, Data, OriginPos, Direction, ...)
    end
    
    if Config.UseMultishot and Config.BulletAmount > 1 then
        for i = 1, (Config.BulletAmount - 1) do
            OldFireServer(SelfParam, OriginPos, Direction, Data, ...)
        end
    end
    
    return OldFireServer(SelfParam, OriginPos, Direction, Data, ...)
end)

return Config
