import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Vino.Checkpoints.Volumes.DeathVolume;

class UClockworkBirdDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AClockworkBird Bird;

	AHazePlayerCharacter DiedPlayer;

	bool bDeathDone = false;

	TArray<FTransform> RespawnLocations;
	float RespawnLocationTimer = 0.f;

	FVector RespawnLocation;
	FVector RespawnDirection;

	UClockworkBirdFlyingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bird = Cast<AClockworkBird>(Owner);
		Settings = UClockworkBirdFlyingSettings::GetSettings(Bird);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Bird.bIsDead)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bDeathDone)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	TArray<AActor> PlayerDeathVolumeOverlaps;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Record locations for respawn
		RespawnLocationTimer -= DeltaTime;
		if (RespawnLocationTimer <= 0.f)
		{
			RespawnLocationTimer = 1.f;
			RespawnLocations.Add(Bird.ActorTransform);
			if (RespawnLocations.Num() > Settings.RespawnLocationPreviousSeconds)
				RespawnLocations.RemoveAt(0);
		}

		// Check if we should die due to death volumes
		if (Bird.ActivePlayer != nullptr && !Bird.bIsDead && HasControl() && Bird.bActivePlayerWantsToUseBird)
		{
			PlayerDeathVolumeOverlaps.Reset(10);
			Bird.ActivePlayer.GetOverlappingActors(PlayerDeathVolumeOverlaps, ADeathVolume::StaticClass());
			if (PlayerDeathVolumeOverlaps.Num() != 0)
				Bird.bIsDead = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		FTransform UseLocation;
		if (RespawnLocations.Num() != 0)
			UseLocation = RespawnLocations[0];
		else
			UseLocation = Bird.ActorTransform;

		OutParams.AddVector(n"RespawnLocation", UseLocation.Location);
		OutParams.AddVector(n"RespawnDirection", UseLocation.Rotation.ForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird.bIsDead = true;
		bDeathDone = false;
		RespawnLocation = ActivationParams.GetVector(n"RespawnLocation");
		RespawnDirection = ActivationParams.GetVector(n"RespawnDirection");
		Bird.SetCapabilityActionState(n"AudioBirdDeath", EHazeActionState::ActiveForOneFrame);

		DiedPlayer = Bird.ActivePlayer;
		BP_StartDeath(Bird, DiedPlayer);
		Bird.BP_OnBirdDeath(DiedPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bird.BP_OnBirdRespawn(DiedPlayer);
		Bird.SetCapabilityActionState(n"AudioBirdRespawn", EHazeActionState::ActiveForOneFrame);
		Bird.bIsDead = false;
		Bird.TeleportBirdIntoFlying(RespawnLocation, FRotator::MakeFromX(RespawnDirection));
		Bird.MoveComp.SetVelocity(FVector::ZeroVector);
		Bird.RemoveBoost();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartDeath(AClockworkBird Bird, AHazePlayerCharacter Player)
	{
		DeathIsFinished();
	}

	UFUNCTION()
	void DeathIsFinished()
	{
		bDeathDone = true;
	}
};