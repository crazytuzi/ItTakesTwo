import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

UCLASS(abstract, Deprecated)
class UMusicalFlyingBarrelRollCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"MusicalFlyingInput");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 5;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;

	UMusicalFlyingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.CurrentBoostCooldown > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"ActivateBarrellRoll"))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if(IsActioning(n"ActivateBarrellRollNoBoost"))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if(IsActioning(n"ActivateBarrellRollNoBoost"))
			OutParams.AddActionState(n"ActivateBarrellRollNoBoost");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(!ActivationParams.GetActionState(n"ActivateBarrellRollNoBoost"))
		{
			FlyingComp.CurrentBoost = Settings.BoostImpulse;
			FlyingComp.CurrentBoostCooldown = Settings.BoostCooldown;
			FlyingComp.BarrellRollState = FMath::RandRange(0, 1) > 0 ? EMusicalFlyingBarrelRoll::Left : EMusicalFlyingBarrelRoll::Right;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.BarrellRollState = EMusicalFlyingBarrelRoll::None;
	}
}
