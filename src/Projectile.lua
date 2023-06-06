local RunService = game:GetService("RunService")


local RAYCAST_IDENTIFIER = "Default";
local SHAPECAST_BLOCK_IDENTIFIER = "Block";
local SHAPECAST_SPHERE_IDENTIFIER = "Sphere";

local ERR_COMPUTING_PEN_EXCEEDED = "Error! Computing whether or not the projectile would penetrate took too long to complete, remove any yielding statements in the Penetration callback"
local VISUALIZATION_ENABLED = false;


-- // Equations

local function GetPositionAtTime(InitialVelocity: Vector3, Acceleration: Vector3, ElapsedTime: number): Vector3
    return (0.5 * Acceleration * math.pow(ElapsedTime, 2) + InitialVelocity * ElapsedTime);
end

local function GetVelocityAtTime(Acceleration: Vector3, ElapsedTime: number): Vector3
    return Acceleration * ElapsedTime;
end

-- //

local function AverageVector3(Input: Vector3): number
    local x, y, z = Input.X, Input.Y, Input.Z
    return (x+y+z)/3;
end



local function VisualizeCast(Placement: CFrame, Length: number, Type: string, Size: Vector3|number)
    if (Type == RAYCAST_IDENTIFIER) then
        local adornment = Instance.new("ConeHandleAdornment")
        adornment.Adornee = workspace.Terrain
        adornment.CFrame = Placement
        adornment.Height = Length
        adornment.Transparency = 0.35
        adornment.Radius = 0.35;
        adornment.Parent = workspace.Terrain
    elseif (Type == SHAPECAST_BLOCK_IDENTIFIER) then
        local adornment = Instance.new("BoxHandleAdornment")
        adornment.CFrame = Placement
        adornment.Adornee = workspace.Terrain
        adornment.Size = (typeof(Size) == "Vector3" and Size) or (type(Size) == "number" and Vector3.new(Size, Size, Length)) 
        adornment.Transparency = 0.35
        adornment.Parent = workspace.Terrain
    elseif (Type == SHAPECAST_SPHERE_IDENTIFIER) then
        local adornment = Instance.new("SphereHandleAdornment")
        adornment.Adornee = workspace.Terrain
        adornment.CFrame = Placement
        adornment.Radius = (type(Size) == "number" and Size) or (typeof(Size) == "Vector3" and AverageVector3(Size))
        adornment.Transparency = 0.35
        adornment.Parent = workspace.Terrain
    end
end





-- //

local function FireSignal(ProjectileParent, SignalName: string, ...): ()
    ProjectileParent[SignalName]:Fire(...)
end


local function GetLatestTrajectory(ProjectileObject): {InitialVelocity: Vector3; InitialPosition: Vector3; Acceleration: Vector3; Lifetime: number}
    local trajectories = ProjectileObject.StateData.Trajectories
    return trajectories[#trajectories];
end



local function MutateProjectileTrajectory(ProjectileObject, Position: Vector3?, Velocity: Vector3?, Acceleration: Vector3?, Lifetime: number?): ()
    local trajectory = GetLatestTrajectory(ProjectileObject)
    if (trajectory.Lifetime == 0) then

        trajectory.InitialPosition = Position or trajectory.InitialPosition
        trajectory.InitialVelocity = Velocity or trajectory.InitialVelocity
        trajectory.Acceleration = Acceleration or trajectory.Acceleration
        trajectory.Lifetime = Lifetime or trajectory.Lifetime

    else 

        table.insert(ProjectileObject.StateData.Trajectories, {
            InitialPosition = Position or GetPositionAtTime(trajectory.InitialVelocity, trajectory.Acceleration, trajectory.Lifetime) + trajectory.InitialPosition;
            InitialVelocity = Velocity or GetVelocityAtTime(trajectory.Acceleration, trajectory.Lifetime) + trajectory.InitialVelocity;
            Acceleration = Acceleration or trajectory.Acceleration;
            Lifetime = Lifetime or 0;
        })
 
    end


end


local function MovePhysicalProjectileTo(ProjectileObject, To: CFrame): ()
    local projectileData = ProjectileObject.ProjectileData
    if (projectileData.Instance and projectileData.Container) then
        projectileData.Instance:PivotTo(To)
    end
end



local function SimulateProjectileByTick(ProjectileObject, DeltaTime: number): ()
    local stateData = ProjectileObject.StateData
    local rayData = ProjectileObject.RayData
    local projectileData = ProjectileObject.ProjectileData
    if (stateData.Paused) then return; end

    if (stateData.ComputingPenetration) then
        ProjectileObject:Destroy()
        error(ERR_COMPUTING_PEN_EXCEEDED)
        return;
    end

    if (stateData.TotalDistanceTravelled >= projectileData.MaxDistance) then
        ProjectileObject:Destroy()
        return;
    end

    local currentTrajectory = GetLatestTrajectory(ProjectileObject)

    local initialPosition, initialVelocity = currentTrajectory.InitialPosition, currentTrajectory.InitialVelocity
    local acceleration = currentTrajectory.Acceleration

    local previousPosition = GetPositionAtTime(initialVelocity, acceleration, currentTrajectory.Lifetime) + initialPosition

    if (previousPosition.Y <= workspace.FallenPartsDestroyHeight) then
        ProjectileObject:Destroy()
        return;
    end

    local segmentedDeltaTime = DeltaTime/rayData.Resolution

    local currentPosition, currentVelocity
    local raycastResult

    for i = 1, rayData.Resolution do
        local currentStepDeltaTime = segmentedDeltaTime*i
        local currentStepProjectileLifetime = currentTrajectory.Lifetime + currentStepDeltaTime

        currentPosition = GetPositionAtTime(initialVelocity, acceleration, currentStepProjectileLifetime) + initialPosition
        currentVelocity = GetVelocityAtTime(acceleration, currentStepProjectileLifetime) + initialVelocity

        local displacement = currentPosition - previousPosition
        local raycastEndPoint = displacement.Unit * currentVelocity.Magnitude * currentStepDeltaTime


        raycastResult = (rayData.Type == RAYCAST_IDENTIFIER and workspace:Raycast(previousPosition, raycastEndPoint, rayData.RaycastParams))
            or (rayData.Type == SHAPECAST_BLOCK_IDENTIFIER and workspace:Blockcast(CFrame.lookAt(previousPosition, previousPosition + raycastEndPoint.Unit), (type(rayData.Size) == "number" and Vector3.new(rayData.Size, rayData.Size, rayData.Size)) or rayData.Size, raycastEndPoint, rayData.RaycastParams))
            or (rayData.Type == SHAPECAST_SPHERE_IDENTIFIER and workspace:Spherecast(previousPosition, (typeof(rayData.Size == "Vector3") and AverageVector3(rayData.Size)) or rayData.Size , raycastEndPoint))

        if (raycastResult) then
            break;
        end
    end

    currentTrajectory.Lifetime += DeltaTime
    stateData.TotalLifetime += DeltaTime

    local point = (raycastResult and raycastResult.Position) or currentPosition

    local actualDisplacement = point - previousPosition
    local distanceCovered = actualDisplacement.Magnitude

    stateData.TotalDistanceTravelled += distanceCovered

    if (VISUALIZATION_ENABLED) then
        VisualizeCast(CFrame.lookAt(previousPosition, previousPosition + actualDisplacement.Unit), distanceCovered, rayData.Type, rayData.Size)
    end


    MovePhysicalProjectileTo(ProjectileObject, CFrame.lookAt(previousPosition, point))
    FireSignal(ProjectileObject.Parent, "ProjectileMoved")

    if (raycastResult) then
        if (projectileData.PenetrationCallback) then
            stateData.ComputingPenetration = true
            if (projectileData.PenetrationCallback(ProjectileObject, raycastResult, currentVelocity)) then
                stateData.ComputingPenetration = false;
                FireSignal(ProjectileObject.Parent, "ProjectilePenetrated", raycastResult, currentVelocity, projectileData.Instance)
            else
                FireSignal(ProjectileObject.Parent, "ProjectileHit", raycastResult, currentVelocity, projectileData.Instance)
                ProjectileObject:Destroy()
            end
        else    
            FireSignal(ProjectileObject.Parent, "ProjectileHit", raycastResult, currentVelocity, projectileData.Instance)
            ProjectileObject:Destroy()
        end
    end
end
 


local Projectile = {}
Projectile.__index = Projectile



function Projectile.new(ProjectileParent, Origin: Vector3, Velocity: Vector3, Behaviour)

    local self = setmetatable({

        Parent = ProjectileParent;
        Connection = nil;


        StateData = {
            
            TotalLifetime = 0;
            TotalDistanceTravelled = 0;
        
            ComputingPenetration = false;

            Trajectories = {
                {
                    Lifetime = 0;
                    InitialPosition = Origin;
                    InitialVelocity = Velocity;
                    Acceleration = Behaviour.Acceleration or Vector3.new(0, 0, 0);
                }


            }
        };

        ProjectileData = {
            Instance = (Behaviour.Projectile and Behaviour.Projectile:Clone()) or nil;
            Container = Behaviour.ProjectileContainer;
            PenetrationCallback = Behaviour.PenetrationCallback;
            MaxDistance = Behaviour.MaxDistance;
        };

        RayData = {
            Type = Behaviour.Type;
            Size = Behaviour.Size;
            Resolution = Behaviour.Resolution;
            RaycastParams = Behaviour.RaycastParams;
        };

        MiscData = {};
        

    }, Projectile)

    return self;
end



function Projectile:Simulate(): ()
    local chosenEvent = (RunService:IsClient() and RunService.RenderStepped) or RunService.Heartbeat


    if (self.ProjectileData.Instance and self.ProjectileData.Container) then
        local currentTrajectory = GetLatestTrajectory(self)
        self.ProjectileData.Instance.Parent = self.ProjectileData.Container
        MovePhysicalProjectileTo(self, CFrame.lookAt(currentTrajectory.InitialPosition, currentTrajectory.InitialPosition + currentTrajectory.InitialVelocity.Unit))
    end


    self.Connection = chosenEvent:Connect(function(DeltaTime)
        SimulateProjectileByTick(self, DeltaTime)
    end)

end


function Projectile:Pause(): ()
    self.StateData.Paused = true
end


function Projectile:Resume(): ()
    self.StateData.Paused = false
end

 
function Projectile:Get(PropertyName: string): Vector3|number|nil
    local trajectory = GetLatestTrajectory(self)
    if (PropertyName == "Position") then
        return GetPositionAtTime(trajectory.InitialVelocity, trajectory.Acceleration, trajectory.Lifetime) + trajectory.InitialPosition;
    elseif (PropertyName == "Velocity") then
      return GetVelocityAtTime(trajectory.Acceleration, self.Lifetime) + trajectory.InitialVelocity;
    elseif (PropertyName == "Acceleration") then 
       return trajectory.Acceleration;
    elseif (PropertyName == "Lifetime") then
       return self.StateData.TotalLifetime;
    end
    return nil;
end

function Projectile:Set(PropertyName: string, Value: any): ()
    if (PropertyName == "Position") then
        MutateProjectileTrajectory(self, Value, nil, nil, nil)
    elseif (PropertyName == "Velocity") then
        MutateProjectileTrajectory(self, nil, Value, nil, nil)
    elseif (PropertyName == "Acceleration") then 
        MutateProjectileTrajectory(self, nil, nil, Value, nil)
    elseif (PropertyName == "Lifetime") then
        MutateProjectileTrajectory(self, nil, nil, nil, Value)
    end
end

function Projectile:Destroy(): ()
    self.Connection:Disconnect()
    self.Connection = nil;

    FireSignal(self.Parent, "ProjectileDestroyed", self)

    self.ProjectileData = nil
    self.RayData = nil;
    self.StateData = nil;
    self.MiscData = nil;

    setmetatable(self, nil)
end


return Projectile
