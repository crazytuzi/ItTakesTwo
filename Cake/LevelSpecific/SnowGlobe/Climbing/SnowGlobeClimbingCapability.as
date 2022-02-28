import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingComponent;
class USnowGlobeClimbingCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	USnowGlobeClimbingComponent ClimbingComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ClimbingComponent = USnowGlobeClimbingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.AddLocomotionAsset(Player.IsMay() ? ClimbingComponent.LocomotionAssetMay : ClimbingComponent.LocomotionAssetCody, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearLocomotionAssetByInstigator(this);
	}
}