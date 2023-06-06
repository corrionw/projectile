
local Signal = require(script:WaitForChild("Signal"))
local Projectile = require(script:WaitForChild("Projectile"))

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


function ProjectileLauncher:Launch(Origin: Vector3, Velocity: Vector3, Behaviour)

    local newProjectile = Projectile.new(self, Origin, Velocity, Behaviour)
    newProjectile:Simulate()

    return newProjectile
end




function Library.new()
    return ProjectileLauncher.new();
end

function Library.NewBehaviour()
    return {

        RaycastParams = nil;

        Acceleration = Vector3.new(0, 0, 0);
        Projectile = nil;
        ProjectileContainer = nil;

        Resolution = 1;
        Type = "Default";
        Size = 1;



    }
end



return Library