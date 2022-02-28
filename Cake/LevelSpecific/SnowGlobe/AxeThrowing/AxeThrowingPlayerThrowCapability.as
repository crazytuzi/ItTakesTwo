import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;

class AxeThrowingPlayerThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingPlayerTargetingCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;
	UAxeThrowingPlayerComp PlayerComp;

	float Power = 2700.f;

	FVector EndLocation;
	AAxeThrowingTarget Target;
	int Nmbr = 0;

	float NextPickupTime;

	AIceAxeActor AxeToThrow;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UAxeThrowingPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::WeaponFire) 
		&& PlayerComp.PlayerAxeState == EPlayerAxeState::AxeReady 
		&& PlayerComp.bCanShoot 
		&& PlayerComp.AxePlayerGameState == EAxePlayerGameState::InPlay)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddVector(n"EndLocation", PlayerComp.EndLocation);
		Params.AddObject(n"Target", PlayerComp.CurrentTarget);
		Params.AddObject(n"AxeToThrow", PlayerComp.ChosenAxe);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		// Ordering of capabilities is not guaranteed when activating from control
		// So we always need to send over which axe we're throwing, since PrepareAxe maybe wasn't called
		AxeToThrow = Cast<AIceAxeActor>(Params.GetObject(n"AxeToThrow"));

		EndLocation = Params.GetVector(n"EndLocation");
		Target = Cast<AAxeThrowingTarget>(Params.GetObject(n"Target"));
		
		Player.SetAnimBoolParam(n"bIcicleThrow", true);
		PlayerComp.ThrowIcicleFeedback(Player);
		PlayerComp.PlayerAxeState = EPlayerAxeState::Throwing;

		System::SetTimer(this, n"OnRelease", 0.14f, false);
		PlayerComp.ChosenAxe = nullptr;
	}

	UFUNCTION()
	void OnRelease()
	{		
		if (AxeToThrow != nullptr)
		{
			AxeToThrow.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			AxeToThrow.ThrowAxe(EndLocation, Power, Target);

			if (PlayerComp.bShowingTutorial)
				PlayerComp.RemoveRightTrigger(Player);
			
			AxeToThrow = nullptr;
		}
		
		PlayerComp.PlayerAxeState = EPlayerAxeState::PickingUpAxe;
	}
}