import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;

class UIceSkatingLocomotionCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 21;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
	}
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.AddLocomotionAsset(Player.IsMay() ? SkateComp.StateMachineAsset_May : SkateComp.StateMachineAsset_Cody, this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearLocomotionAssetByInstigator(this);
	}
}