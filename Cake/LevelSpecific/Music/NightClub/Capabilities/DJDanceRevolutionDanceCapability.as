import Cake.LevelSpecific.Music.NightClub.DJDanceRevolutionManager;

class UDJDanceRevolutionDanceCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;
	
	ADJDanceRevolutionManager DanceRevolutionManager;

	float DelayBeforeStart = 0.0f;
	float DelayBeforeStop = 0.0f;
	float DanceTime = 0.0f;
	float Elapsed = 0.0f;
	bool bStopDancing = false;

	EDJDanceRevolutionState DanceState = EDJDanceRevolutionState::Inactive;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DanceRevolutionManager = Cast<ADJDanceRevolutionManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(DanceRevolutionManager.RoundCurrent != EDJDanceRevolutionTargetRound::None)
			return EHazeNetworkActivation::DontActivate;

		if(DanceRevolutionManager.RoundTarget != EDJDanceRevolutionTargetRound::Dance)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DanceRevolutionManager.RoundCurrent = EDJDanceRevolutionTargetRound::Dance;
		DelayBeforeStart = DanceRevolutionManager.CurrentRoundInfo.TimeBeforeStart;
		DelayBeforeStop = DanceRevolutionManager.CurrentRoundInfo.TimeBeforeStop + DanceRevolutionManager.DelayAfterDance;
		DanceTime = DanceRevolutionManager.CurrentRoundInfo.DanceStationActiveTime;
		Elapsed = 0.0f;
		DanceState = EDJDanceRevolutionState::PreparingToStart;
		bStopDancing = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if(bStopDancing)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DanceRevolutionManager.RoundTarget = EDJDanceRevolutionTargetRound::None;
		DanceRevolutionManager.RoundCurrent = EDJDanceRevolutionTargetRound::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(DanceState == EDJDanceRevolutionState::PreparingToStart)
		{
			Elapsed += DeltaTime;
			if(Elapsed > DelayBeforeStart)
			{
				DanceRevolutionManager.bStopDancing = false;
				Elapsed = 0.0f;
				DanceState = EDJDanceRevolutionState::Active;
				DanceRevolutionManager.StartDanceRound();	// calls a NetFunction
			}
		}
		else if(DanceState == EDJDanceRevolutionState::Active)
		{
			Elapsed += DeltaTime;

			if((Elapsed > DanceTime && DanceRevolutionManager.GetBassDropOMeterValue() < DanceRevolutionManager.UnlimitedDanceAtBassDrop) || DanceRevolutionManager.bStopDancing)
			{
				Elapsed = 0.0f;
				DanceState = EDJDanceRevolutionState::DoneWaitingToStop;
				DanceRevolutionManager.StopDanceRound();	// calls a NetFunction
				DJDanceCommon::DebugPrint("Dancing done, waiting to stop.");
			}
		}
		else if(DanceState == EDJDanceRevolutionState::DoneWaitingToStop)
		{
			Elapsed += DeltaTime;

			if(Elapsed > DelayBeforeStop)
			{
				bStopDancing = true;
				DJDanceCommon::DebugPrint("Dancing Stopped");
			}
		}
	}
}
