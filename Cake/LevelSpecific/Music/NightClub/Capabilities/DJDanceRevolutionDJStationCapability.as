import Cake.LevelSpecific.Music.NightClub.DJDanceRevolutionManager;

class UDJDanceRevolutionDJStationCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;
	
	ADJDanceRevolutionManager DanceRevolutionManager;

	float DelayBeforeStart = 0.0f;
	float DelayBeforeStop = 0.0f;
	float Elapsed = 0.0f;
	EDJDanceRevolutionState DJState = EDJDanceRevolutionState::Inactive;
	bool bStoppedDJTurn = false;
	
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
		
		if(DanceRevolutionManager.RoundTarget != EDJDanceRevolutionTargetRound::DJStation)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DanceRevolutionManager.RoundCurrent = EDJDanceRevolutionTargetRound::DJStation;
		DelayBeforeStart = DanceRevolutionManager.CurrentRoundInfo.TimeBeforeStart;
		DelayBeforeStop = DanceRevolutionManager.CurrentRoundInfo.TimeBeforeStop;
		Elapsed = 0.0f;
		DJState = EDJDanceRevolutionState::PreparingToStart;
		bStoppedDJTurn = false;

#if !RELEASE
		FString DJStationsString = "Preparing to start: ";
		for(EDJStandType StandType : DanceRevolutionManager.CurrentRoundInfo.StationType)
		{
			DJStationsString += " / " + StandType;
		}

		DJDanceCommon::DebugPrint(DJStationsString);
#endif // !RELEASE
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if(bStoppedDJTurn)
			return EHazeNetworkDeactivation::DeactivateLocal;

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
		if(DJState == EDJDanceRevolutionState::PreparingToStart)
		{
			Elapsed += DeltaTime;

			if(Elapsed > DelayBeforeStart)
			{
				DJState = EDJDanceRevolutionState::Active;
				Elapsed = 0.0f;
				DanceRevolutionManager.StartCurrentDJStations();
				DJDanceCommon::DebugPrint("Starting DJ Stations");
			}
		}
		else if(DJState == EDJDanceRevolutionState::Active)
		{
			if(!DanceRevolutionManager.HasActiveDJStations())
			{
				Elapsed = 0.0f;
				DJState = EDJDanceRevolutionState::DoneWaitingToStop;
				DJDanceCommon::DebugPrint("All DJStations completed, wating to stop.");
			}
		}
		else if(DJState == EDJDanceRevolutionState::DoneWaitingToStop)
		{
			Elapsed += DeltaTime;
			if(Elapsed > DelayBeforeStop)
			{
				DJState = EDJDanceRevolutionState::Inactive;
				bStoppedDJTurn = true;
				DJDanceCommon::DebugPrint("DJ Stations stopped.");
			}
		}
	}
}
