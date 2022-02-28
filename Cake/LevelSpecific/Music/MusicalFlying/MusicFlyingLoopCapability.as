import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

class UMusicFlyingLoopCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicFlying");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 2;

	UMusicalFlyingComponent FlyingComp;
	AHazePlayerCharacter Player;
	UMusicalFlyingSettings Settings;

	float PitchStart = 0.0f;
	float PitchCurrent = 0.0f;
	float PitchTarget = 0.0f;

	float Elapsed = 0.0f;

	bool bFinishedRotating = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(Elapsed > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.bIsHovering)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.FlyingVelocity < 1500.0f)
			return EHazeNetworkActivation::DontActivate;

		if(!FlyingComp.bWantsToDoLoop)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.bIsReturningToVolume)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingComp.bIsPerformingLoop = true;
		PitchCurrent = Player.Mesh.RelativeRotation.Pitch;
		PitchTarget = 360.0f - PitchCurrent;
		bFinishedRotating = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PitchCurrent += Settings.LoopPitchSpeed * DeltaTime;
		FlyingComp.LoopingPitch = PitchCurrent;

		if(PitchCurrent > PitchTarget)
			bFinishedRotating = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(FlyingComp.bIsReturningToVolume)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!bFinishedRotating)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.bIsPerformingLoop = false;
		if(!FlyingComp.bIsReturningToVolume)
			FlyingComp.bWantsToFly = true;
		Elapsed = Settings.BoostCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Elapsed -= DeltaTime;
	}
}
