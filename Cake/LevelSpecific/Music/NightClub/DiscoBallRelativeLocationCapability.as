import Cake.LevelSpecific.Music.NightClub.CharacterDiscoBallMovementComponent;
import Peanuts.Network.RelativeCrumbLocationCalculator;

class UDiscoBallRelativeLocationCapability : UHazeCapability
{
	UHazeCrumbComponent CrumbComp;
	UCharacterDiscoBallMovementComponent DiscoComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		DiscoComp = UCharacterDiscoBallMovementComponent::Get(Owner);
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
		CrumbComp.MakeCrumbsUseCustomWorldCalculator(URelativeCrumbLocationCalculator::StaticClass(), this, DiscoComp.DiscoBall.RootComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		CrumbComp.RemoveCustomWorldCalculator(this);
	}
}

