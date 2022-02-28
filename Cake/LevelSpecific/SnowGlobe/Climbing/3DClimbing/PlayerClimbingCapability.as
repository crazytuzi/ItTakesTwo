import Cake.LevelSpecific.SnowGlobe.Climbing.3DClimbing.PlayerClimbingComponent;
class UPlayerClimbingCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UPlayerClimbingComponent ClimbingComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ClimbingComponent = UPlayerClimbingComponent::GetOrCreate(Player);
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