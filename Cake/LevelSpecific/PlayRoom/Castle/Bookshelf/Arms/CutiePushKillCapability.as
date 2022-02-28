import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Cutie;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFightCutieComponent;


class CutiePushKillCapability: UHazeCapability
{
	default CapabilityTags.Add(n"CutiePushKill");
	default CapabilityDebugCategory = n"Cutie";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 101;

	ACutie Cutie;
	UCutieFightCutieComponent CutieFightCutieComponent;
	bool bPhaseComplete = false;

	UPROPERTY(BlueprintReadOnly)
	float CutieTotalArmProgress = 0;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cutie = Cast<ACutie>(Owner);
		CutieFightCutieComponent = UCutieFightCutieComponent::GetOrCreate(Cutie);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Cutie.PhaseGlobal == 6.f)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Cutie.PhaseGlobal != 6.f)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"EdgeHang";
		Cutie.RequestLocomotion(Locomotion);

		if(Cutie.PhaseGlobal != 6)
			return;

		CutieTotalArmProgress = (CutieFightCutieComponent.CutieLeftArmProgress + CutieFightCutieComponent.CutieRightArmProgress) / 2;
		CutieFightCutieComponent.CutieTotalArmProgress = CutieTotalArmProgress;

			if(CutieFightCutieComponent.PlayersFinishedButtonMashingArms[Game::GetCody()] && CutieFightCutieComponent.PlayersFinishedButtonMashingArms[Game::GetMay()])
			{
				Cutie.LeftProgressnetworked.Value = 0;
				Cutie.RightProgressnetworked.Value = 0;
				NetPlayersButtonMashComplete();
			}
	}

	UFUNCTION(NetFunction)
	void NetPlayersButtonMashComplete()
	{
		if(bPhaseComplete)
			return;
		
		bPhaseComplete = true;
		Cutie.LeftArm.Disable(n"PhaseEnded");
		Cutie.RightArm.Disable(n"PhaseEnded");
		Cutie.SetPhase(6.5f);
	}
}
