import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

class UMusicFlyingBoostCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicFlying");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 3;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UHazeCrumbComponent CrumbComp;

	UMusicalFlyingSettings Settings;

	private float Elapsed = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (!FlyingComp.bIsFlying)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed -= DeltaTime;

		if(Elapsed < 0.0f && FlyingComp.bWantsToFly && !FlyingComp.bIsPerformingLoop)
		{
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_TriggerBoost"), FHazeDelegateCrumbParams());
			Elapsed = Settings.BoostCooldown;
		}
	}

	UFUNCTION()
	private void Crumb_TriggerBoost(FHazeDelegateCrumbData CrumbData)
	{
		FlyingComp.TriggerBoost();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!FlyingComp.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
