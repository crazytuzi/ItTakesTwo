import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Peanuts.Outlines.Outlines;

class UClockworkBirdMountedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdMounted");

	default CapabilityDebugCategory = n"ClockworkBirdMounted";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	//default TickGroupOrder = 100;

	AClockworkBird Bird;
	bool bPlayerWantsToQuit = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bird = Cast<AClockworkBird>(Owner);
	}


	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bPlayerWantsToQuit = false;
		EActionStateStatus Status = ConsumeAction(ClockworkBirdTags::ClockworkBirdQuitRiding);
		if(Status == EActionStateStatus::Active)
		{
			bPlayerWantsToQuit = true;
		}
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!Bird.AnyPlayerIsUsingBird())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Bird.AnyPlayerIsUsingBird())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		if(bPlayerWantsToQuit && Bird.PlayerCanQuitRiding())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Bird.AnyPlayerIsUsingBird())
			Bird.MakeActivePlayerNotUseBird();
	}
}