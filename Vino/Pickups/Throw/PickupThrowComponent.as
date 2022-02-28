import Vino.Movement.Components.MovementComponent;
import Vino.Pickups.Throw.MoveProjectileAlongCurveComponent;
import Vino.Pickups.PickupActor;
import Vino.Trajectory.TrajectoryStatics;

class UPickupThrowComponent : UActorComponent
{
    // Holds reference to currently active pickup component
    AHazePlayerCharacter PlayerOwner;
    UHazeMovementComponent MovementComponent;

	const float MinThrowingDistanceFromTarget = 200.f;
	float SimulationFrequency;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        MovementComponent = UHazeMovementComponent::Get(Owner);
    }

    bool CalculateThrowPath(APickupActor PickupActor, FVector StartLocation, FVector ThrowForce, float Mass, FPredictProjectilePathResult& OutThrowPath, TArray<AActor> AdditionalIgnores = TArray<AActor>(), EDrawDebugTrace DebugDrawType = EDrawDebugTrace::None, float DebugDrawDuration = 0.f)
	{
		// Why would this be null?
		if(!ensure(PickupActor != nullptr))
		{
			Warning("PickupComponent::GetThrowPath() - ActorToThrow is null, why u lie?!");
			return false;
		}

		FPredictProjectilePathParams PredictionParams;
		PredictionParams.StartLocation = StartLocation;

		// Add pickup radius to prediction
		// PredictionParams.ProjectileRadius = PickupActor.PickupRadius;

		// Debug stuff
		PredictionParams.DrawDebugType = DebugDrawType;
		PredictionParams.DrawDebugTime = DebugDrawDuration;

		// Calculates velocity based on pickupable throw force and where the camera is pointing
		PredictionParams.LaunchVelocity = ThrowForce / Mass;
		
		// Increase gravity as we aim higher (creates a sharper curve)?
		PredictionParams.OverrideGravityZ = MovementComponent.GetGravity().Z;

		// Le arbitrary value
		PredictionParams.MaxSimTime = 3.f;
		SimulationFrequency = PredictionParams.SimFrequency;

		// Add actors to ignore
		TArray<AActor> IgnoredActors;
		IgnoredActors.AddUnique(PickupActor);
		IgnoredActors.AddUnique(PlayerOwner);
		IgnoredActors.AddUnique(PlayerOwner.GetOtherPlayer());
		IgnoredActors.Append(AdditionalIgnores);
		
		PredictionParams.ActorsToIgnore = IgnoredActors;
		PredictionParams.bTraceWithCollision = true;

		// UE ftw!
		Gameplay::Blueprint_PredictProjectilePath_Advanced(PredictionParams, OutThrowPath);

		// Validate we are at a decent throwing distance
		return ThrowPathIsValid(PickupActor, OutThrowPath);
	}

	// Kept just to not fuck with Golberg circus' trapeze section
	// SpeedModifier: Lower value equals faster travel time (step size)
    void Throw_Legacy(APickupActor PickupActor, FVector StartLocation, FVector Force, float Mass, float SimulationSpeedModifier, FThrownActorReachedTarget OnReachedTargetDelegate, bool bIsControlThrow, bool bCollisionEnabled, TArray<AActor> IgnoreList = TArray<AActor>())
	{
		FPredictProjectilePathResult ThrowPath;
		CalculateThrowPath(PickupActor, StartLocation, Force, Mass, ThrowPath, IgnoreList);

		if(!ThrowPathIsValid(PickupActor, ThrowPath))
			return;

		// Move Throwable along curve path
		UMoveProjectileAlongCurveComponent MoveProjectileAlongCurveComponent = UMoveProjectileAlongCurveComponent::GetOrCreate(PickupActor);
		MoveProjectileAlongCurveComponent.Setup(ThrowPath, OnReachedTargetDelegate, SimulationFrequency, bIsControlThrow);
		MoveProjectileAlongCurveComponent.StartMoving(!bCollisionEnabled, PlayerOwner, SimulationSpeedModifier);
	}

	// SpeedModifier: Lower value equals faster travel time (step size)
    void Throw(APickupActor PickupActor, FVector StartLocation, FVector EndLocation, float TrajectoryPeak, FPickupThrowCollisionEvent OnThrowCollision, TArray<AActor> IgnoreList = TArray<AActor>())
    {
		FOutCalculateVelocity ThrowParams = CalculateParamsForPathWithHeight(StartLocation, EndLocation, MovementComponent.Gravity.Size(), TrajectoryPeak);
		PickupActor.SetPickupThrowParams(ThrowParams.Velocity, MovementComponent.Gravity, ThrowParams.Time, OnThrowCollision);
    }

    // Returns whether there is a valid throw path
	UFUNCTION()
	bool ThrowPathIsValid(APickupActor PickupActor, FPredictProjectilePathResult ThrowPath)
	{
		// Path is too short or non-existent 
		if(ThrowPath.PathData.Num() <= 1)
		{
			Print("ThrowComponent::ThrowPathIsValid() - Throw path with " + ThrowPath.PathData.Num() + " points is invalid");
			return false;
		}

		// Check if object is overlapping other geometry
		FVector PickupableZExtents = FVector(0.f, 0.f, PickupActor.PickupExtents.Z);

		FHazeTraceParams ThrowTrace;
		ThrowTrace.InitWithPrimitiveComponent(PickupActor.Mesh);
		ThrowTrace.From = PickupActor.GetActorLocation() + PickupableZExtents;
		ThrowTrace.To = ThrowPath.PathData[1].Location + PickupableZExtents;

		if (ThrowTrace.From.Equals(ThrowTrace.To))
			return false;

		ThrowTrace.IgnoreActor(PickupActor);
		ThrowTrace.IgnoreActor(Owner);

		// Eman TODO: Send this to function instead of fetching here! It's gross that throwcomponent has to know about pickup shit
		ThrowTrace.TraceShape = FCollisionShape::MakeBox(PickupActor.PickupExtents);
		ThrowTrace.ShapeRotation = PickupActor.GetActorQuat();

		return !ThrowTrace.Trace(FHazeHitResult());
	}
}
