import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarActor;

class UTugOfWarCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ATugOfWarActor ActiveInteraction;
	UTugOfWarManagerComponent ManagerComp;
	AHazePlayerCharacter Player;

	bool bBothPlayersInteracting = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ActiveInteraction = Cast<ATugOfWarActor>(GetAttributeObject(n"TugOfWarActor"));
		ManagerComp = Cast<UTugOfWarManagerComponent>(GetAttributeObject(n"ManagerComp"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ActiveInteraction != nullptr && IsActioning(n"EnterFinished") && !ActiveInteraction.bBothPlayersInteracting)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ActiveInteraction == nullptr || !IsActioning(n"EnterFinished") || ActiveInteraction.bBothPlayersInteracting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ShowCancelPrompt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WasActionStarted(ActionNames::Cancel) && ActiveInteraction.DoubleInteract.CanPlayerCancel(Player) && HasControl())
		{
			ActiveInteraction.CancelInteraction(Player);
			Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		}
	}
}