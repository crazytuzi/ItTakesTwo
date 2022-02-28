import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

UCLASS(Deprecated)
class UMusicalFlyingTightTurnRightCapability : UHazeCapability
{
	UMusicalFlyingComponent FlyingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!FlyingComp.bFlyingValid)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.TightTurnState != EMusicalFlyingTightTurn::None)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::MusicFlyingTightTurnRight))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!FlyingComp.bFlyingValid)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.TightTurnState != EMusicalFlyingTightTurn::Right)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::MusicFlyingTightTurnRight))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingComp.TightTurnState = EMusicalFlyingTightTurn::Right;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.TightTurnState = EMusicalFlyingTightTurn::None;
	}
}
