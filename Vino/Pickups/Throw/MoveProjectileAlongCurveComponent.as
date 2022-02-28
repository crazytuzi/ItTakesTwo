import Peanuts.MeshMovement.MeshMovementObserver;

event void FThrownActorReachedTarget(AActor ProjectileActor, FVector LastTracedVelocity, FHitResult HitResult, bool bIsControlThrow);

class UMoveProjectileAlongCurveComponent : UActorComponent
{
	private FThrownActorReachedTarget OnProjectileReachedTarget;

	UMeshComponent MeshComponent;

	UObject MoveInstigator = nullptr;

	TArray<FPredictProjectilePathPointData> ProjectilePath;
	FPredictProjectilePathPointData CurrentGoal;

	FHitResult MoveSweepHit;

	FVector LastTracedVelocity;

	FName InitialCollisionProfileName;

	// Lower value equals faster travel time
	float SpeedModifier;
	float SimulationTime;
	float SimulationFrequency;

	bool bHasReachedEnd;
	bool bWasAborted;
	bool bHasControl;
	bool bCollisionIsDisabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
		MeshComponent = UMeshComponent::Get(Owner);
	}

	void Setup(FPredictProjectilePathResult ProjectilePathResult, FThrownActorReachedTarget ProjectileReachedTargetDelegate, float SimFrequency, bool bIsControlSide)
	{
		ProjectilePath = ProjectilePathResult.PathData;
		OnProjectileReachedTarget = ProjectileReachedTargetDelegate;
		SimulationFrequency = SimFrequency / 1000.f;

		bHasControl = bIsControlSide;
	}

	// Eman TODO: Maybe turn off component if we hit something along the way?
	void StartMoving(bool bDisableCollision, UObject Instigator, float StepSize = 1.f)
	{
		CurrentGoal = ProjectilePath[0];
		SimulationTime = -SimulationFrequency * StepSize;
		SpeedModifier = StepSize;
		bCollisionIsDisabled = bDisableCollision || !bHasControl;
		MoveInstigator = Instigator;

		if(bCollisionIsDisabled)
		{
			InitialCollisionProfileName = MeshComponent.CollisionProfileName;
			MeshComponent.SetCollisionProfileName(n"NoCollision");
		}
		else
		{
			MeshComponent.SetAllUseCCD(true);
		}

		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void Stop()
	{
		bHasReachedEnd = false;
		SimulationTime = 0;

		if(bCollisionIsDisabled)
			MeshComponent.SetCollisionProfileName(InitialCollisionProfileName);
		else
			MeshComponent.SetAllUseCCD(false);

		SetComponentTickEnabled(false);
		bCollisionIsDisabled = false;
		InitialCollisionProfileName = NAME_None;
		MoveInstigator = nullptr;
	}

	void Abort()
	{
		if(!IsComponentTickEnabled())
			return;
		
		bWasAborted = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bWasAborted)
		{
			HasReachedEnd();
			return;
		}

		// Move to current goal
		FVector NewLocation = Owner.GetActorLocation() + CurrentGoal.Velocity * DeltaSeconds / SpeedModifier;

		// Check if we're moving past the goal and fix
		FVector ActorToFinalLocation = ProjectilePath.Last().Location - Owner.ActorLocation;
		if(Owner.ActorLocation.Distance(NewLocation) > Owner.ActorLocation.Distance(Owner.ActorLocation + ActorToFinalLocation))
		{
			NewLocation = Owner.ActorLocation + ActorToFinalLocation;
		}

		if(!Owner.SetActorLocation(NewLocation, true, MoveSweepHit, false))
		{
			// Don't stop if we hit a player
			if(MoveSweepHit.Actor != nullptr && MoveSweepHit.Actor.IsA(AHazePlayerCharacter::StaticClass()))
				return;

			LastTracedVelocity = CurrentGoal.Velocity;
			HasReachedEnd();
			return;
		}

		SimulationTime += DeltaSeconds;

		// Test if we are at the local goal
		if(SimulationTime >= CurrentGoal.Time * SpeedModifier)
		{
			CurrentGoal = GetNextGoal();

			// Bail if we got to the final destination
			if(bHasReachedEnd)
			{
				LastTracedVelocity = CurrentGoal.Velocity;
				HasReachedEnd();
				return;
			}
		}
	}

	FPredictProjectilePathPointData GetNextGoal()
	{
		if(!ensure(ProjectilePath.Num() > 0))
		{
			Error("MoveProjectileAlongCurveComponent::GetNextGoal() - ProjectilePath is empty, why?!");
			return FPredictProjectilePathPointData();
		}

		ProjectilePath.RemoveAt(0);
		if(ProjectilePath.Num() == 0)
		{
			bHasReachedEnd = true;
			return CurrentGoal;
		}

		return ProjectilePath[0];
	}

	void HasReachedEnd()
	{
		Stop();

		if(bWasAborted)
		{
			bWasAborted = false;
			return;
		}

		if(HasControl())
			NetFireProjectileReachedTargetEvent(LastTracedVelocity, MoveSweepHit);
	}

	UFUNCTION(NetFunction)
	void NetFireProjectileReachedTargetEvent(FVector NetLastTracedVelocity, FHitResult NetHitResult)
	{
		OnProjectileReachedTarget.Broadcast(Owner, NetLastTracedVelocity, NetHitResult, bHasControl);
	}
}