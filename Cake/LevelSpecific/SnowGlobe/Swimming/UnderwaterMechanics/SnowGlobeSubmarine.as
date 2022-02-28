import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class ASnowGlobeSubmarine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UCapsuleComponent Collision;
	
	UPROPERTY(DefaultComponent, Attach = Collision)
	UMagnetGenericComponent MagneticComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent MeshRotationPivot;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY()
	float Drag = 1.f;

	UPROPERTY()
	float Restitution = 1.f;

	bool bIsAffected;

	TArray<AHazePlayerCharacter> AffectingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup();

		//Capability::AddPlayerCapabilityRequest(RequiredCapability.Get());

		MagneticComponent.OnActivatedBy.AddUFunction(this, n"BeginAffecting");
		MagneticComponent.OnDeactivatedBy.AddUFunction(this, n"EndAffecting");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		//Capability::RemovePlayerCapabilityRequest(RequiredCapability.Get());
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
		if(AffectingPlayers.Num() == 2)
		{
			//Print("HEj");
			FVector TargetLocation;
			TargetLocation = AffectingPlayers[0].GetActorLocation() - AffectingPlayers[1].GetActorLocation();
			TargetLocation = AffectingPlayers[1].GetActorLocation() + TargetLocation * 0.5f;
			System::DrawDebugPoint(TargetLocation,10.f);

			FVector TargetDirection = TargetLocation - this.GetActorLocation();
			TargetDirection.Normalize();
			Force += TargetDirection * 2000.f;

			FVector RotationTarget = this.GetActorLocation() - AffectingPlayers[1].GetActorLocation();
			FRotator MeshRotation = FMath::RInterpTo(MeshRotationPivot.GetWorldRotation(), RotationTarget.Rotation(), DeltaTime, 2.f);
			MeshRotationPivot.SetWorldRotation(MeshRotation);
		}

		else
		{
			for (AHazePlayerCharacter Player : AffectingPlayers)
			{
				FVector Distance = Player.GetActorLocation() - this.GetActorLocation();
				//float Strength = Distance.Size() / 2000.f;
				//Strength = 2.f - Strength;
				//Strength = FMath::Pow(Strength, 12);
				//Print("Power: " + Strength);
				Distance.Normalize();
				Force += Distance * 2000.f;
			}
		}

		FVector InternalVelocity = MoveComp.GetVelocity();

		Force += InternalVelocity * Drag * -1;

		InternalVelocity += Force * DeltaTime;

		if(MoveComp.ForwardHit.bBlockingHit)
		{
			Print("Bounce!", 1.f);
 			FVector Direction = InternalVelocity.MirrorByVector(MoveComp.ForwardHit.Normal);
			Direction.Normalize();
			InternalVelocity = Direction * InternalVelocity.Size() * Restitution;
		}	

		if(MoveComp.CanCalculateMovement())
		{
			Move(InternalVelocity);
		}
	}

	void Move(const FVector& VelocityToApply)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SubmarineMovement");

		FrameMove.ApplyVelocity(VelocityToApply);
		//FrameMove.ApplyGravityAcceleration();

		MoveComp.Move(FrameMove);
	}
}