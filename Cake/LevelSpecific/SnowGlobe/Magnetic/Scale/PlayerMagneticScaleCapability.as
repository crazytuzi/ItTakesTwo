// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Scale.MagneticScaleActor;

// class UPlayerMagneticScaleCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 1;

// 	AHazePlayerCharacter Player;
// 	UMagneticPlayerComponent PlayerMagnetComp;

// 	AMagneticScaleActor ScaleActor;

// 	UPROPERTY()
// 	UForceFeedbackEffect ChargeRumble;

// 	// UPROPERTY()
// 	// UHazeCameraSpringArmSettingsDataAsset CamSettings;

// 	UMagneticScaleComponent ActivatedMagnet;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
// 	}

// 	// bool IsMagneticPathBlocked() const
// 	// {
// 	// 	FHitResult Hit;
// 	// 	TArray<AActor> ActorsToIgnore;
// 	// 	ActorsToIgnore.Add(Game::GetCody());
// 	// 	ActorsToIgnore.Add(Game::GetMay());
// 	// 	System::LineTraceSingle(ActivatedMagnet.WorldLocation, PlayerMagnetComp.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true, FLinearColor::Green);

// 	// 	if(Hit.bBlockingHit)
// 	// 	{
// 	// 		return true;
// 	// 	}
// 	// 	return false;
// 	// }


// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(!HasControl())
// 			return EHazeNetworkActivation::DontActivate;

// 		UMagneticScaleComponent CurrentTargetedMagnet = Cast<UMagneticScaleComponent>(PlayerMagnetComp.GetTargetedMagnet());
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

// 		// if(!PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet) && IsMagneticPathBlocked())
// 		// 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;		
	
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

// 		ActivatedMagnet = Cast<UMagneticScaleComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
// 		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);

// 		ScaleActor = Cast<AMagneticScaleActor>(ActivatedMagnet.Owner);

// 		if(PlayerMagnetComp == nullptr)
// 			PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);

// 		// FHazeCameraBlendSettings CamBlend;
// 		// CamBlend.BlendTime = 0.5f;
// 		// Player.ApplyCameraSettings(CamSettings, CamBlend, this, EHazeCameraPriority::Medium);


// 		ActivatedMagnet.ActivateMagneticInteraction(Player, PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet));		
// 		ScaleActor.ActivateScale();

// 		// FHazePointOfInterest PoISettings;
// 		// PoISettings.Blend.BlendTime = 1.f;
// 		// PoISettings.FocusTarget.Component = SnowCannon.Head;
// 		// Player.ApplyPointOfInterest(PoISettings, this);

// 		//SnowCannon.SetCapabilityActionState(n"UsingSnowCannon", EHazeActionState::Active);
// 	}
 
// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Player.UnblockCapabilities(FMagneticTags::MagneticControl, this);
// 		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
// 		PlayerMagnetComp.DeactivateMagnetLockon(this);

// 		//SnowCannon.SetCapabilityActionState(n"UsingSnowCannon", EHazeActionState::Inactive);
// 		ActivatedMagnet.DeactivateMagneticInteraction(Player);
// 		ScaleActor.DeactivateScale();
// 		ScaleActor = nullptr;
		
// 		//Player.ClearCameraSettingsByInstigator(this);
// 		//Player.ClearPointOfInterestByInstigator(this);

// 		ActivatedMagnet = nullptr;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		//Player.SetFrameForceFeedback(0.025f, 0.025f, 0.025f, 0.025f);		
// 	}
// }