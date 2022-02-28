import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongChargeBaseCapability;

class UPowerfulSongChargeWhileFlyingCapability : UPowerfulSongChargeBaseCapability
{
	default CapabilityTags.Add(n"PowerfulSongChargeFlying");
	
	UMusicalFlyingComponent FlyingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		FlyingComp = UMusicalFlyingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(FMath::IsNearlyZero(SingingComp.SongOfLifeCurrent))
			return EHazeNetworkActivation::DontActivate;
		
		if (FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkActivation::DontActivate;
		
		if (!WasActionStarted(ActionNames::PowerfulSongCharge))
        	return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bChargeFinished)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Cooldown > 0.0f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (!IsActioning(ActionNames::PowerfulSongCharge))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
