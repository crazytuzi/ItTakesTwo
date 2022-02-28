import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarManagerComponent;
import Peanuts.ButtonMash.Default.ButtonMashDefault;

class UTugOfWarButtonMashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 50;

	ATugOfWarActor ActiveInteraction;
	UTugOfWarManagerComponent ManagerComp;
	AHazePlayerCharacter Player;

	UButtonMashDefaultHandle ButtonMashHandle;

	bool bIsLeftPlayer = false;
	bool bBothPlayersInteracting = false;

	float ButtonMashProgressSpeed = 3.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"ButtonMashing") && IsActioning(n"EnterFinished"))
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"ButtonMashing"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveInteraction = Cast<ATugOfWarActor>(GetAttributeObject(n"TugOfWarActor"));
		ManagerComp = Cast<UTugOfWarManagerComponent>(GetAttributeObject(n"ManagerComp"));

		if(IsActioning(n"TugOfWarPlayer1"))
		{
			bIsLeftPlayer = true;
			ButtonMashHandle = ManagerComp.Player1Handle;
		}
		else if(IsActioning(n"TugOfWarPlayer2"))
		{
			bIsLeftPlayer = false;
			ButtonMashHandle = ManagerComp.Player2Handle;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopButtonMash(ButtonMashHandle);
		Player.SetCapabilityActionState(n"ButtonMashing", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!IsActioning(n"ButtonMashBlocked") && !ManagerComp.bMoveInProgress)
		{
			const float ButtonMash = ButtonMashHandle.MashRateControlSide * ButtonMashProgressSpeed * DeltaTime;

			if(bIsLeftPlayer)
				ActiveInteraction.HandlePlayer1Input(Player, ButtonMash);
			else
				ActiveInteraction.HandlePlayer2Input(Player, ButtonMash);
		}
	}
}