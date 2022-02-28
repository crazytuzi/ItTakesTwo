import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.SprintingEvent.ClockworkLastBossJumpToGrindInteraction;

class UClockworkLastBossJumpToGrindCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossJumpToGrindCapability");

	default CapabilityDebugCategory = n"ClockworkLastBossJumpToGrindCapability";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AClockworkLastBossJumpToGrindInteraction JumpToGrindActor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"ClockworkJumpToGrindActor") == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"CanJumpToGrind"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"CanJumpToGrind"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"JumpActor", GetAttributeObject(n"ClockworkJumpToGrindActor"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		JumpToGrindActor = Cast<AClockworkLastBossJumpToGrindInteraction>(ActivationParams.GetObject(n"JumpActor"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(WasActionStarted(ActionNames::SwingAttach))
		{
			JumpToGrindActor.StartJumpToLocation(Player);
		}
	}
}