import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;

/*
	Used when the follow target is not a player.
*/

class UMusicKeyFollowCapability : UHazeCapability
{
	FHazeAcceleratedVector AcceleratedLocation;
	AMusicalFollowerKey Key;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Key = Cast<AMusicalFollowerKey>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Key.FollowTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Key.MusicKeyState != EMusicalKeyState::FollowTarget)
			return EHazeNetworkActivation::DontActivate;

		if(Key.FollowTarget.IsA(AHazePlayerCharacter::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedLocation.Value = Owner.ActorLocation;
		Key.SetGlowActive(false);
		Key.SetTrailActive(true, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DirectionToKey = (Owner.ActorCenterLocation - Key.FollowTarget.ActorCenterLocation).GetSafeNormal();
		FVector TargetLocation = Key.FollowTarget.ActorCenterLocation + DirectionToKey * Key.DevilBirdOffsetDistance;
		AcceleratedLocation.AccelerateTo(TargetLocation, 0.6f, DeltaTime);
		Owner.SetActorLocation(AcceleratedLocation.Value);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Key.FollowTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Key.MusicKeyState != EMusicalKeyState::FollowTarget)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Key.FollowTarget != nullptr && Key.FollowTarget.IsA(AHazePlayerCharacter::StaticClass()))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
