import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Cutie;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFightCutieComponent;

class CutiePullLegsCapability: UHazeCapability
{
	default CapabilityTags.Add(n"CutiePullLegsCapablity");
	default CapabilityDebugCategory = n"Cutie";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 101;
	
	UCutieFightCutieComponent CutieFightCutieComponent;
	ACutie Cutie;

	UPROPERTY(BlueprintReadOnly)
	float CutieTotalLegProgress = 0;
	bool bPhaseComplete = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cutie = Cast<ACutie>(Owner);
		CutieFightCutieComponent = UCutieFightCutieComponent::GetOrCreate(Cutie);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Cutie.PhaseGlobal == 4.f)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(ActionNames::Cancel))
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		if(Cutie.PhaseGlobal != 4.f)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"LegPull";
		Cutie.RequestLocomotion(Locomotion);

		if(Cutie.PhaseGlobal != 4)
			return;

		CutieTotalLegProgress = (CutieFightCutieComponent.CutieLeftLegProgress + CutieFightCutieComponent.CutieRightLegProgress) / 2;
		CutieFightCutieComponent.CutieTotalLegProgress = CutieTotalLegProgress;

			if(CutieFightCutieComponent.PlayersFinishedButtonMashingLegs[Game::GetCody()] && CutieFightCutieComponent.PlayersFinishedButtonMashingLegs[Game::GetMay()])
			{
				if(Cutie.HasControl())
				{
					//Game::GetCody().SetAnimBoolParam(n"CodyLegPullComplete", true);
					//Game::GetMay().SetAnimBoolParam(n"MayLegPullComplete", true);
					NetPlayersButtonMashComplete();
					Cutie.LeftProgressnetworked.Value = 0;
					Cutie.RightProgressnetworked.Value = 0;
				}
			}
	}

	UFUNCTION(NetFunction)
	void NetPlayersButtonMashComplete()
	{
		if(bPhaseComplete)
			return;
		
		bPhaseComplete = true;
		Cutie.LeftLeg.Disable(n"PhaseEnded");
		Cutie.RightLeg.Disable(n"PhaseEnded");
		Cutie.SetPhase(4.5f);
	}
}