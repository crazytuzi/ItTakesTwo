import Cake.LevelSpecific.SnowGlobe.Magnetic.Underwater.MagneticBuoyComponent;
struct FFrameStaticPerlinVector
{
	private FVector PerlinVector;
	private uint LastFrameNumber;
	
	FVector GetPerlinNoiseVector()
	{
		if(Time::FrameNumber == LastFrameNumber)
			return PerlinVector;

		return FVector(FMath::PerlinNoise1D(Time::GameTimeSeconds * 0.2f), FMath::PerlinNoise1D(Time::GameTimeSeconds * 0.6), FMath::PerlinNoise1D(Time::GameTimeSeconds)).GetSafeNormal();
	}
}

enum EMagneticBuoyState
{
	Idle,
	PulledByPlayer,
	Reconstituting
}

class UMagneticBuoyMovementComponent : UActorComponent
{
	UPROPERTY()
	FHazeConstrainedPhysicsValue Rotation;
	default Rotation.LowerBound = -80.f;
	default Rotation.UpperBound = 80.f;
	default Rotation.Friction = 0.6f;

	UPROPERTY()
	float TiltMaxAngle = 45.f;

	UPROPERTY()
	float IdleAngularForce = 150.f;

	UPROPERTY()
	float PullAngularForce = 1200.f;

	UPROPERTY()
	float ReconstituteSpeed = 60.f;
	
	UPROPERTY()
	float AvoidMoveDistance = 300.f;

	UPROPERTY()
	float OffsetResetTime = 0.2f;

	UPROPERTY()
	UNiagaraSystem VFX_Splash;

	UPROPERTY()
	ETraceTypeQuery CollisionTraceType;
	
	UMeshComponent BuoyMesh;
	UMagneticBuoyComponent BuoyMagnet;
	UHazeOffsetComponent OffsetComp;
	UCapsuleComponent CapsuleComp;

	EMagneticBuoyState BuoyState = EMagneticBuoyState::Idle;

	// Every instance of the class will share noise for the frame
	FFrameStaticPerlinVector FrameStaticPerlinVector;

	// Used to accelerated noise
	FHazeAcceleratedVector AcceleratedDirection;

	FVector InitialLocation;
	AHazePlayerCharacter PullingPlayer;
	FVector InitialBuoyToPlayer;
	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialLocation = Owner.ActorLocation;
		BuoyMesh = UStaticMeshComponent::Get(Owner);
		BuoyMagnet = UMagneticBuoyComponent::Get(Owner);
		OffsetComp = UHazeOffsetComponent::Get(Owner);
		CapsuleComp = UCapsuleComponent::Get(Owner);

		BuoyMagnet.OnActivatedBy.AddUFunction(this, n"OnMagnetActivated");
		BuoyMagnet.OnDeactivatedBy.AddUFunction(this, n"OnMagnetDeactivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!Owner.WasRecentlyRendered())
			return;

		switch(BuoyState)
		{
			case EMagneticBuoyState::Idle:
				TickIdle(DeltaTime);
				break;

			case EMagneticBuoyState::PulledByPlayer:
				TickPlayerPull(DeltaTime);
				break;

			case EMagneticBuoyState::Reconstituting:
				break;
		}

		Rotation.Update(DeltaTime);
	}

	void TickIdle(float DeltaTime)
	{
		// Reset rotation over time
		Rotation.AccelerateTowards(0.f, IdleAngularForce);

		FVector TiltUpVector = FVector::UpVector.RotateAngleAxis(Rotation.Value, Owner.ActorRightVector);
		FRotator TiltRotation = FRotator::MakeFromZY(TiltUpVector, Owner.ActorRightVector);
		Owner.ActorRotation = FMath::RInterpTo(Owner.ActorRotation, TiltRotation, DeltaTime, 5.f);
		
		// Get frame noise and ignore z axis
		FVector Noise = FrameStaticPerlinVector.GetPerlinNoiseVector() * FVector(1.f, 1.f, 0.f);
		AcceleratedDirection.AccelerateTo(Noise, 2.f, DeltaTime);

		Velocity += (AcceleratedDirection.Value * DeltaTime);
		Velocity = Velocity.ConstrainToPlane(FVector::UpVector);
		Velocity = Velocity.GetClampedToMaxSize(1.f);

		// Return to initial location
		FVector BuoyToInitial = InitialLocation - Owner.ActorLocation;
		FVector BuoyVelocity = BuoyToInitial.GetSafeNormal() * (BuoyToInitial.Size() * DeltaTime);
		BuoyMesh.AddLocalRotation(FRotator(0.f, AcceleratedDirection.Value.X, 0.f));

		float DistanceFromOrigin = InitialLocation.Distance(Owner.ActorLocation + Velocity);
		if (DistanceFromOrigin >= CapsuleComp.CapsuleRadius)
			Velocity = Math::RotateVectorTowards(Velocity, BuoyToInitial, DeltaTime * ReconstituteSpeed * 2.f);

		Owner.ActorLocation += Velocity * DeltaTime * ReconstituteSpeed;
		BuoyMesh.AddLocalRotation(FRotator(0.f, AcceleratedDirection.Value.X, 0.f));
	}

	void TickPlayerPull(float DeltaTime)
	{
		FVector BuoyToPlayer = PullingPlayer.ActorLocation - Owner.ActorLocation;
		FVector TiltDirection = -BuoyToPlayer.GetSafeNormal();
		FVector TiltForwardVector = TiltDirection.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector TiltRightVector = TiltForwardVector.CrossProduct(-FVector::UpVector);

		float TiltAngle = FMath::RadiansToDegrees(FMath::Acos(TiltDirection.DotProduct(FVector::UpVector)));
		TiltAngle = FMath::Clamp(TiltAngle, -TiltMaxAngle, TiltMaxAngle);

		Rotation.AccelerateTowards(TiltAngle, PullAngularForce);

		FVector TiltUpVector = FVector::UpVector.RotateAngleAxis(Rotation.Value, TiltRightVector);
		FRotator TiltRotation = FRotator::MakeFromZY(TiltUpVector, TiltRightVector);

		Owner.ActorRotation = FMath::RInterpTo(Owner.ActorRotation, TiltRotation, DeltaTime, 5.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMagnetActivated(UHazeActivationPoint ActivationPoint, AHazePlayerCharacter PlayerCharacter)
	{
		BuoyState = EMagneticBuoyState::PulledByPlayer;

		PullingPlayer = PlayerCharacter;
		InitialBuoyToPlayer = PlayerCharacter.ActorLocation - Owner.ActorLocation;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMagnetDeactivated(UHazeActivationPoint ActivationPoint, AHazePlayerCharacter PlayerCharacter)
	{
		// Collision between player and buoy will be re-enabled when the magnet is deactivated
		if (AvoidCollision() && VFX_Splash != nullptr)
			Niagara::SpawnSystemAtLocation(VFX_Splash, BuoyMesh.WorldLocation);

		PullingPlayer = nullptr;
		BuoyState = EMagneticBuoyState::Idle;
	}

	bool AvoidCollision()
	{
		if (PullingPlayer == nullptr)
			return false;

		FVector BuoyToPlayer = PullingPlayer.ActorLocation - Owner.ActorLocation;
		float AvoidRadius = CapsuleComp.BoundsRadius * 2.f;

		if (BuoyToPlayer.Size() > AvoidRadius)
			return false;

		FVector PlayerDirection = PullingPlayer.MovementComponent.Velocity.GetSafeNormal();
		FVector ForwardVector = PlayerDirection.ConstrainToPlane(PullingPlayer.MovementWorldUp).GetSafeNormal();
		FVector RightVector = ForwardVector.CrossProduct(PullingPlayer.MovementWorldUp);

		// Always try to move in the opposite direction of the player
		if (RightVector.DotProduct(BuoyToPlayer.GetSafeNormal()) > 0.f) 
			RightVector *= -1.f;

		FVector LocationOffset = RightVector * AvoidMoveDistance;

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Owner);
		ActorsToIgnore.Add(PullingPlayer);

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(CollisionTraceType);
		Trace.IgnoreActors(ActorsToIgnore);
		Trace.TraceShape.SetCapsule(CapsuleComp.CapsuleRadius, CapsuleComp.CapsuleHalfHeight);
		Trace.From = Owner.ActorLocation;
		Trace.To = Owner.ActorLocation + LocationOffset;

		FHazeHitResult HitResult;
		if (Trace.Trace(HitResult))
			LocationOffset = HitResult.ActorLocation - Owner.ActorLocation;

		OffsetComp.FreezeAndResetWithTime(OffsetResetTime);
		Owner.ActorLocation += LocationOffset;
		return true;
	}
}