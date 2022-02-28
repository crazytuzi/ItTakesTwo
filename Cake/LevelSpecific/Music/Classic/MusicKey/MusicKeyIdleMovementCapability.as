import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;

class UMusicKeyIdleMovementCapability : UHazeCapability
{
	AMusicalFollowerKey Key;

	FVector WantedDirection;

	FVector Velocity;
	float Drag = 0.7f;
	float Acceleration = 800.0f;
	float VelocityMaximum = 4000.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Key = Cast<AMusicalFollowerKey>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Key.bDisableKey)
			return EHazeNetworkActivation::DontActivate;
		
		if(Key.MusicKeyState != EMusicalKeyState::Idle)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Velocity = FVector::ZeroVector;
		Key.MovementReplication.Value = Owner.ActorLocation;
		Key.SetGlowActive(true);
		Key.SetTrailActive(false, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector Direction;
			// Return inside the combat area if outside.
			if(Key.CombatArea != nullptr && !Key.CombatArea.IsPointOverlapping(Owner.ActorLocation))
			{
				const FVector DirectionToCombatArea = (Key.CombatArea.Shape.ShapeCenterLocation - Owner.ActorLocation).GetSafeNormal();
				Direction += DirectionToCombatArea;
			}

			FVector HitOrigin;
			if(IsPointOverlappingBoidObstacle(Owner.ActorLocation, HitOrigin))
			{
				const FVector DirectionToHit = (Owner.ActorLocation - HitOrigin).GetSafeNormal();
				Direction += DirectionToHit;
				Direction.Normalize();
			}

			Velocity += Direction * Acceleration;

			Velocity = Velocity.GetClampedToMaxSize(VelocityMaximum);
			Velocity *= FMath::Pow(Drag, DeltaTime);

			Key.MovementReplication.Value = Owner.ActorLocation + Velocity * DeltaTime;
		}

		const FVector NewLocation = FMath::VInterpTo(Owner.ActorLocation, Key.MovementReplication.Value, DeltaTime, 15.0f);
		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Key.MusicKeyState != EMusicalKeyState::Idle)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
