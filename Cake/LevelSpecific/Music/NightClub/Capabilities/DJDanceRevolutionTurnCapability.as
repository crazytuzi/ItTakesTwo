import Cake.LevelSpecific.Music.NightClub.DJDanceRevolutionManager;
import Cake.LevelSpecific.Music.NightClub.BassDropOMeter;

/*
	Start next turn with this capability. It will trigger one of two other capabilities
*/

class ADJDanceRevolutionTurnCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 0;
	
	ADJDanceRevolutionManager DanceRevolutionManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DanceRevolutionManager = Cast<ADJDanceRevolutionManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(DanceRevolutionManager.DJRounds.Num() == 0)
			return EHazeNetworkActivation::DontActivate;
		
		if(!DanceRevolutionManager.bStartDJ)
			return EHazeNetworkActivation::DontActivate;
		
		if(DanceRevolutionManager.HasActiveDJStations())
			return EHazeNetworkActivation::DontActivate;
		
		if(DanceRevolutionManager.HasActiveDanceStations())
			return EHazeNetworkActivation::DontActivate;

		if(DanceRevolutionManager.RoundCurrent != EDJDanceRevolutionTargetRound::None)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;	// Use this to make sure that all stations also has exited on the remote.
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bool bRestarted = false;

		const bool bStartSuperDanceMode = ActivationParams.GetActionState(n"SuperDanceMode");	// Super dance mode is when the drop o meter is high, then we want to force dance turns

		if(bStartSuperDanceMode)
		{
			DJDanceCommon::DebugPrint("Starting Super Dance Mode");
			// Check next round, so we can clear it if it is also a dance round. Remember that we are forcing dance now because of the DROP O METER.
			if(DanceRevolutionManager.IsNextRoundDanceRound())
			{
				DanceRevolutionManager.IncrementRoundIndex();
			}

			DanceRevolutionManager.RoundTarget = EDJDanceRevolutionTargetRound::Dance;
			DanceRevolutionManager.CurrentRoundInfo.bIsDanceRound = true;
			DanceRevolutionManager.CurrentRoundInfo.DanceStationActiveTime = 10.0f;
		}
		else
		{
			DanceRevolutionManager.CurrentRoundInfo = DanceRevolutionManager.TriggerNextRound(bRestarted);
			DanceRevolutionManager.RoundTarget = DanceRevolutionManager.CurrentRoundInfo.bIsDanceRound ? EDJDanceRevolutionTargetRound::Dance : EDJDanceRevolutionTargetRound::DJStation;

#if !RELEASE
			if(DanceRevolutionManager.DebugState != EDJDanceDebugState::None)
			{
				EDJDanceRevolutionTargetRound Target = DanceRevolutionManager.DebugState == EDJDanceDebugState::DJStation ? EDJDanceRevolutionTargetRound::DJStation : EDJDanceRevolutionTargetRound::Dance;
				
				while(DanceRevolutionManager.RoundTarget != Target)
				{
					DanceRevolutionManager.CurrentRoundInfo = DanceRevolutionManager.TriggerNextRound(bRestarted);
					DanceRevolutionManager.RoundTarget = DanceRevolutionManager.CurrentRoundInfo.bIsDanceRound ? EDJDanceRevolutionTargetRound::Dance : EDJDanceRevolutionTargetRound::DJStation;
				}
			}
#endif // RELEASE
		}

#if !RELEASE

		DJDanceCommon::DebugPrint("Next round is: " + DanceRevolutionManager.RoundTarget);

#endif // !RELEASE

		DanceRevolutionManager.DJState = EDJDanceRevolutionState::PreparingToStart;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
