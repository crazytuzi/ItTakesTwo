import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;

class UAxeThrowingPlayerPrepareAxeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingPlayerPrepareAxeCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UAxeThrowingPlayerComp PlayerComp;

	float AnimationTimer;
	AIceAxeActor AxeToPrepare;
	int Nmbr = 0;

	float PickUpTime;
	float PickUpRate = 0.4f;

	FHazeAnimNotifyDelegate IcicleThrowReturnDelegate;

	bool bFirstThrow;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UAxeThrowingPlayerComp::Get(Player);

		bFirstThrow = true;
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.PlayerAxeState != EPlayerAxeState::PickingUpAxe)
			return EHazeNetworkActivation::DontActivate;

    	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.PlayerAxeState == EPlayerAxeState::PickingUpAxe)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"AxeToPrepare", PlayerComp.AxeManager.GetAvailableAxe(Player));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		if (PlayerComp.IcicleProp.IsActorDisabled(Player))
			PlayerComp.IcicleProp.EnableActor(Player);

		PlayerComp.StartInteraction.ActivateIcicleNiagara(Player);

		AxeToPrepare = Cast<AIceAxeActor>(Params.GetObject(n"AxeToPrepare"));
		ensure(AxeToPrepare != nullptr);
		PlayerComp.ChosenAxe = AxeToPrepare;
		PickUpTime = Time::GameTimeSeconds + PickUpRate;

		System::SetTimer(this, n"AttachAxeToHand", 0.3f, false);
	}

	// UFUNCTION(BlueprintOverride)
	// void OnRemoved()
	// {
	// 	System::SetTimer(this, n"ReturnAxeToLocation", 0.25f, false);
	// }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PickUpTime <= Time::GameTimeSeconds)
			PlayerComp.PlayerAxeState = EPlayerAxeState::AxeReady;
	}

	UFUNCTION()
	void AttachAxeToHand()
	{
		PlayerComp.IcicleProp.DisableActor(Player);

		// On remote side, this axe might not have deactivated yet, so make sure to deactivate
		if (AxeToPrepare.bIsActive)
			AxeToPrepare.DeactivateAxe();

		AxeToPrepare.ActivateAxe(Player);

		AxeToPrepare.AttachToActor(Player, n"RightAttach", EAttachmentRule::SnapToTarget);
		AxeToPrepare.IceAxeState = EIceAxeState::Ready;
	}
}