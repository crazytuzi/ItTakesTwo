// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetWheelComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

// class UPlayerMagneticWheelCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 1;

// 	AHazePlayerCharacter Player;
// 	UMagneticPlayerComponent PlayerMagnetComp;

// 	UPROPERTY()
// 	TSubclassOf<UCameraShakeBase> CamShake;

// 	UPROPERTY()
// 	UForceFeedbackEffect ChargeRumble;

// 	UMagnetWheelComponent ActivatedMagnet;

// 	bool bHasLetGoTriggerSinceActivated = true;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(!HasControl())
// 			return EHazeNetworkActivation::DontActivate;

// 		UMagnetWheelComponent CurrentTargetedMagnet = Cast<UMagnetWheelComponent>(PlayerMagnetComp.GetTargetedMagnet());
// 		if(CurrentTargetedMagnet == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
// 			return EHazeNetworkActivation::DontActivate;
		

// 		return EHazeNetworkActivation::ActivateUsingCrumb;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		// if(!FindMagnetComponent.CurrentActivationInstigatorIs(this))
// 		// 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
// 		//If a grind point is activated, you lose contact to the wheel

// 		if(!IsActioning(ActionNames::PrimaryLevelAbility))
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
// 		if(!PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet) && IsMagneticPathBlocked())
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		if(ActivatedMagnet.bIsDisabled)
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	bool IsMagneticPathBlocked() const
// 	{
// 		FHitResult Hit;
// 		TArray<AActor> ActorsToIgnore;
// 		ActorsToIgnore.Add(ActivatedMagnet.Owner);
// 		ActorsToIgnore.Add(Game::GetCody());
// 		ActorsToIgnore.Add(Game::GetMay());
// 		System::LineTraceSingle(ActivatedMagnet.WorldLocation, PlayerMagnetComp.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true, FLinearColor::Green);

// 		if(Hit.bBlockingHit)
// 		{
// 			return true;
// 		}
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
// 	{
// 		ActivationParams.AddObject(n"CurrentMagnet", PlayerMagnetComp.GetTargetedMagnet());
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		bHasLetGoTriggerSinceActivated = false;
// 		Player.BlockCapabilities(FMagneticTags::MagneticControl, this);
// 		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);

// 		ActivatedMagnet = Cast<UMagnetWheelComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
// 		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);
		
// 		bool IsOpposite = false;

// 		if (!PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet))
// 		{
// 			IsOpposite = true;
// 		}

// 		ActivatedMagnet.ActivateMagneticInteraction(Player, IsOpposite);
		
// 		//AHazeActor MagnetOwner = Cast<AHazeActor>(ActivatedMagnet.Owner);
// 		// MagnetOwner.SetCapabilityActionState(n"UsingMagneticWheel", EHazeActionState::Active);
		
// 		Player.PlayForceFeedback(ChargeRumble, false, true, n"UsingMagneticWheel");
// 	}
 
// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		PlayerMagnetComp.DeactivateMagnetLockon(this);
// 		ActivatedMagnet.DeactivateMagneticInteraction(Player);
// 		Player.ClearCameraSettingsByInstigator(ActivatedMagnet);
// 		Player.ClearPointOfInterestByInstigator(ActivatedMagnet);
// 		ActivatedMagnet = nullptr;
		
// 		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{
// 		if(!bHasLetGoTriggerSinceActivated)
// 		{
// 			if(!IsActioning(ActionNames::PrimaryLevelAbility))
// 			{
// 				Player.UnblockCapabilities(FMagneticTags::MagneticControl, this);
// 				bHasLetGoTriggerSinceActivated = true;
// 			}
// 		}
// 	}
// }