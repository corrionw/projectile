--[[
MIT License

Copyright (c) 2023 corrionw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

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
