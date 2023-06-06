local TypeDictionary = {}

type Trajectory = {
    Lifetime: number;
    InitialPosition: Vector3;
    InitialVelocity: Vector3;
    Acceleration: Vector3;
}

type PenetrationCallback = (Projectile, Vector3, RaycastResult) -> boolean

export type ProjectileLauncher = {
    ProjectileHit: RBXScriptSignal;
    ProjectilePenetrated: RBXScriptSignal;
    ProjectileDestroyed: RBXScriptSignal;
    ProjectileMoved: RBXScriptSignal;
}

export type Behaviour = {
    Acceleration: Vector3?;

    RaycastParams: RaycastParams?;
    Projectile: Instance?;
    ProjectileContainer: Instance?;

    PenetrationCallback: PenetrationCallback?;
    MaxDistance: number?;

    Resolution: number;
    Size: Vector3|number;

    Type: "Default"|"Block"|"Sphere"

}


export type Projectile = {

    Parent: ProjectileLauncher;
    Connection: RBXScriptConnection?;

    StateData: {
        TotalLifetime: number;
        TotalDistanceTravelled: number;
        ComputingPenetration: boolean;
        
        Trajectories: {
            [number]: Trajectory
        };
    };


    ProjectileData: {
        Instance: Instance?;
        Container: Instance?;
        PenetrationCallback: PenetrationCallback?;
        MaxDistance: number;
    };

    RayData: {
        Type: "Default"|"Block"|"Sphere";
        Size: Vector3|number;
        Resolution: number;
        RaycastParams: RaycastParams;

    };

    MiscData: {[any]: any};

}


return TypeDictionary
