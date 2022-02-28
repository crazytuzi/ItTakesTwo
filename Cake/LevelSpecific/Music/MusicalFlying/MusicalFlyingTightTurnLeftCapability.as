import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

UCLASS(Deprecated)
class UMusicalFlyingTightTurnLeftCapability : UHazeCapability
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

		if(!IsActioning(ActionNames::MusicFlyingTightTurnLeft))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!FlyingComp.bFlyingValid)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.TightTurnState != EMusicalFlyingTightTurn::Left)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::MusicFlyingTightTurnLeft))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingComp.TightTurnState = EMusicalFlyingTightTurn::Left;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.TightTurnState = EMusicalFlyingTightTurn::None;
	}
}
