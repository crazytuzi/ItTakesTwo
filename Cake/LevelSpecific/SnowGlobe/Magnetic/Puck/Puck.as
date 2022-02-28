import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class APuck : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UCapsuleComponent Collision;
	
	UPROPERTY(DefaultComponent, Attach = Collision)
	UMagnetGenericComponent MagneticComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY()
	float Drag = 0.05f;

	UPROPERTY()
	float Restitution = 1.f;

	FVector PuckVelocity;

	bool bIsAffected;

	TArray<AHazePlayerCharacter> AffectingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup();

		Capability::AddPlayerCapabilityRequest(RequiredCapability.Get());

		MagneticComponent.OnActivatedBy.AddUFunction(this, n"BeginAffecting");
		MagneticComponent.OnDeactivatedBy.AddUFunction(this, n"EndAffecting");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability.Get());
	}

	UFUNCTION()
	void BeginAffecting(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		bIsAffected = true;
		AffectingPlayers.Add(Player);
	}

	UFUNCTION()
	void EndAffecting(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		bIsAffected = false;
		AffectingPlayers.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector Force;

		for (AHazePlayerCharacter Player : AffectingPlayers)
		{
			FVector Distance = this.GetActorLocation() - Player.GetActorLocation();
			float Strength = Distance.Size() / 2000.f;
			Strength = 2.f - Strength;
			Strength = FMath::Pow(Strength, 12);
			Print("Power: " + Strength);
			Distance.Normalize();
			Force += Distance * Strength * 20.f;
		}

		PuckVelocity = MoveComp.GetVelocity();

		Force += PuckVelocity * Drag * -1;

		Force = Force.ConstrainToPlane(FVector::UpVector);

		PuckVelocity += Force * DeltaTime;

		if(MoveComp.ForwardHit.bBlockingHit)
		{
			Print("Bounce!", 1.f);
 			FVector Direction = PuckVelocity.MirrorByVector(MoveComp.ForwardHit.Normal);
			Direction = Direction.ConstrainToPlane(FVector::UpVector);
			Direction.Normalize();
			PuckVelocity = Direction * PuckVelocity.Size() * Restitution;
		}	

		Move();

	}

	void Move()
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Movement");

		FrameMove.ApplyVelocity(PuckVelocity);
		FrameMove.ApplyGravityAcceleration();

		MoveComp.Move(FrameMove);
	}
}