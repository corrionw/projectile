
local Signal = require(script:WaitForChild("Signal"))
local Projectile = require(script:WaitForChild("Projectile"))
local Types = require(script:WaitForChild("Types"))


type Behaviour = Types.Behaviour
type Options = Types.ProjectileSpawnOptions

local Library = {}

local ProjectileLauncher = {}
ProjectileLauncher.__index = ProjectileLauncher


function ProjectileLauncher.new()
    local self = setmetatable({

        ProjectileDestroyed = Signal.new();
        ProjectilePenetrated = Signal.new();
        ProjectileHit = Signal.new();
        ProjectileMoved = Signal.new();

    }, ProjectileLauncher)

    return self
end


function ProjectileLauncher:Launch(Origin: Vector3, Velocity: Vector3, Behaviour, SpawnOptions: Options?)

    local newProjectile = Projectile.new(self, Origin, Velocity, Behaviour)
    if (SpawnOptions and type(SpawnOptions) == "table") then
        for propertyName, value in pairs(SpawnOptions) do
            newProjectile:Set(propertyName, value)
        end

    end

    newProjectile:Simulate()

    return newProjectile
end




function Library.new()
    return ProjectileLauncher.new();
end

function Library.NewBehaviour(): Behaviour
    return {

        RaycastParams = nil;

        Acceleration = nil;

        Projectile = nil;
        ProjectileContainer = nil;
        MaxDistance = 1000;
        PenetrationCallback = nil;
        
        Resolution = 1;
        Type = "Default";
        Size = 1;
    }
end



return Library
