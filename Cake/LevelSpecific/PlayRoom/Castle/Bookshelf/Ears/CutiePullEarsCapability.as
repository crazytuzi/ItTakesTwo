import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Cutie;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFightCutieComponent;

class CutiePullEarsCapablity: UHazeCapability
{
	default CapabilityTags.Add(n"CutiePullEarsCapablity");
	default CapabilityDebugCategory = n"Cutie";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 101;
	
	UCutieFightCutieComponent CutieFightCutieComponent;
	ACutie Cutie;

	UPROPERTY(BlueprintReadOnly)
	float CutieTotalEarProgress = 0;
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
		if(Cutie.PhaseGlobal == 2.f)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(ActionNames::Cancel))
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		if(Cutie.PhaseGlobal != 2.f)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"TowerHang";
		Cutie.RequestLocomotion(Locomotion);

		if(Cutie.PhaseGlobal != 2)
			return;

		CutieTotalEarProgress = (CutieFightCutieComponent.CutieLeftEarProgress + CutieFightCutieComponent.CutieRightEarProgress) / 2;
		CutieFightCutieComponent.CutieTotalEarProgress = CutieTotalEarProgress;
		//Cutie.SetBlendSpaceValues(0.f, CutieTotalEarProgress);

		if(CutieFightCutieComponent.PlayersFinishedButtonMashingEars[Game::GetCody()] && CutieFightCutieComponent.PlayersFinishedButtonMashingEars[Game::GetMay()])
		{
			if(Cutie.HasControl())
			{
				Cutie.LeftProgressnetworked.Value = 0;
				Cutie.RightProgressnetworked.Value = 0;
				NetPlayersButtonMashComplete();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayersButtonMashComplete()
	{
		if(bPhaseComplete)
			return;
		
		bPhaseComplete = true;
		Cutie.LeftEar.Disable(n"PhaseEnded");
		Cutie.RightEar.Disable(n"PhaseEnded");
		Cutie.SetPhase(2.5f);
	}
}