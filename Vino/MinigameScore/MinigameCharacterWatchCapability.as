import Vino.MinigameScore.MinigameCharacter;

class UMinigameCharacterWatchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MinigameCharacterWatchCapability");
	default CapabilityTags.Add(MinigameCapabilityTags::Minigames);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMinigameCharacter MinigameCharacter;

	TPerPlayer<AHazePlayerCharacter> Players;

	FHazeAcceleratedRotator AcceleratedRotator;

	TPerPlayer<float> Distances;

	float CurrentZTarget;
	float ZOffsetUp = 1.5f;
	float ZOffsetDown = -1.5f;

	float NewZ;

	bool bCanMoveUp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MinigameCharacter = Cast<AMinigameCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Players[0] = Game::May;
		Players[1] = Game::Cody;
		AcceleratedRotator.SnapTo(MinigameCharacter.ActorRotation);
		CurrentZTarget = ZOffsetUp;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Distances[0] = (Players[0].ActorLocation - Owner.ActorLocation).Size();
		Distances[1] = (Players[1].ActorLocation - Owner.ActorLocation).Size();

		auto FurthestDistance = (Distances[0] < Distances[1]) ? Distances[1] : Distances[0];

		FVector LookLocation(0.f); 

		if (FurthestDistance >= 4500.f)
		{
			auto ClosestPlayer = (Distances[0] < Distances[1]) ? Game::May : Game::Cody;
			
			LookLocation = ClosestPlayer.ActorLocation - MinigameCharacter.ActorLocation;
		}
		else
		{
			LookLocation = (Players[0].ActorLocation + Players[1].ActorLocation) * 0.5f - MinigameCharacter.ActorLocation;
		}
		
		LookLocation.Normalize();
		LookLocation.ConstrainToPlane(FVector::UpVector);
		FRotator MakeRot = FRotator::MakeFromX(LookLocation);
		AcceleratedRotator.AccelerateTo(MakeRot, 1.5f, DeltaTime);
		MinigameCharacter.SetActorRotation(FRotator(0.f, AcceleratedRotator.Value.Yaw, 0.f));

		// NewZ = FMath::FInterpConstantTo(NewZ, CurrentZTarget, DeltaTime, 2.f); 
		// FVector NewLoc = MinigameCharacter.ActorLocation + FVector(0.f, 0.f, NewZ);
		// MinigameCharacter.SetActorLocation(NewLoc);

		// float Distance = CurrentZTarget - NewZ;
		// Distance = FMath::Abs(Distance);
		
		// if (Distance <= 0.1f)
		// {
		// 	bCanMoveUp = !bCanMoveUp;

		// 	if (bCanMoveUp)
		// 		CurrentZTarget = ZOffsetUp;
		// 	else
		// 		CurrentZTarget = ZOffsetDown;
		// }
    }
}