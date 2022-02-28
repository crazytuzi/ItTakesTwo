// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Pullcord.MagneticPullcordActor;

// class UPlayerMagneticPullcordCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 1;

// 	AHazePlayerCharacter Player;
// 	UMagneticPlayerComponent PlayerMagnetComp;

// 	//AMagneticPullcordActor PullcordActor;

// 	UPROPERTY()
// 	UForceFeedbackEffect ChargeRumble;

// 	UMagneticPullcordComponent ActivatedMagnet;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
// 	}

// 	bool IsMagneticPathBlocked() const
// 	{
// 		FHitResult Hit;
// 		TArray<AActor> ActorsToIgnore;
// 		ActorsToIgnore.Add(Game::GetCody());
// 		ActorsToIgnore.Add(Game::GetMay());
// 		System::LineTraceSingle(ActivatedMagnet.WorldLocation, PlayerMagnetComp.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false, FLinearColor::Green);

// 		if(Hit.bBlockingHit)
// 		{
// 			return true;
// 		}
// 		return false;
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		UMagneticPullcordComponent CurrentTargetedMagnet = Cast<UMagneticPullcordComponent>(PlayerMagnetComp.GetTargetedMagnet());

// 		if(!HasControl())
// 			return EHazeNetworkActivation::DontActivate;

// 		if(CurrentTargetedMagnet == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
// 			return EHazeNetworkActivation::DontActivate;
		
// 		return EHazeNetworkActivation::ActivateUsingCrumb;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(!PlayerMagnetComp.MagnetLockonIsActivatedBy(this))
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		if(!IsActioning(ActionNames::PrimaryLevelAbility))
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		if(IsMagneticPathBlocked())
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		if(ActivatedMagnet.bIsDisabled)
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
// 	{
// 		ActivationParams.AddObject(n"CurrentMagnet", PlayerMagnetComp.GetTargetedMagnet());
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		Player.BlockCapabilities(FMagneticTags::MagneticControl, this);
// 		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);

// 		ActivatedMagnet = Cast<UMagneticPullcordComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
// 		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);

// 		//PullcordActor = Cast<AMagneticPullcordActor>(ActivatedMagnet.Owner);

// 		if(PlayerMagnetComp == nullptr)
// 			PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);

// 		ActivatedMagnet.ActivateMagneticInteraction(Player, PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet));		
// 	}
 
// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Player.UnblockCapabilities(FMagneticTags::MagneticControl, this);
// 		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
// 		PlayerMagnetComp.DeactivateMagnetLockon(this);

// 		ActivatedMagnet.DeactivateMagneticInteraction(Player);

// 		ActivatedMagnet = nullptr;
// 	}

// 	// UFUNCTION(BlueprintOverride)
// 	// void TickActive(float DeltaTime)
// 	// {
// 	// 	//Player.SetFrameForceFeedback(0.025f, 0.025f, 0.025f, 0.025f);		
// 	// }
// }