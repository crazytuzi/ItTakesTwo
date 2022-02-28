import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingComponent;
class USnowGlobeClimbingMagneticCapability : UHazeCapability
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
		if(IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ClimbingComponent.PlayerMagneticComponent.bIsActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ClimbingComponent.PlayerMagneticComponent.bIsActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	//	ClimbingComponent.PlayerMagneticComponent
	}
}