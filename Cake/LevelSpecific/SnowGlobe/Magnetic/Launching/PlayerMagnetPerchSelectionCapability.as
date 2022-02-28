import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticEffects;

class UPlayerMagnetPerchSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunch);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 90;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	UPROPERTY()
	TSubclassOf<AMagneticEffects> MagneticEffectClass;
	AMagneticEffects MagneticEffect;

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent MagneticPlayerComponent;

	UMagneticPerchAndBoostComponent ActiveMagnet;
	UMagneticPerchAndBoostComponent TargetedMagnet;

	FHazePointOfInterest PointOfInterest;
	FVector PoiOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);

		// Create and initialize magnet effect
		MagneticEffect = Cast<AMagneticEffects>(SpawnActor(MagneticEffectClass, PlayerOwner.ActorLocation, PlayerOwner.ActorRotation));
		MagneticEffect.AttachToActor(PlayerOwner, NAME_None, EAttachmentRule::KeepWorld);
		MagneticEffect.Initialize(PlayerOwner, MagneticPlayerComponent.HasPositivePolarity());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MagneticPlayerComponent.ActivatedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		UMagneticPerchAndBoostComponent SuperMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.ActivatedMagnet);
		if(SuperMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlayerOwner.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchPerchCapability))
			return EHazeNetworkActivation::DontActivate;

		// Adds a small delay so that magnets are not queried more than once on the same frame
		// --avoids performing more than one ActivationPoint query async trace on a single frame with same instigator
		if(WasActionStartedDuringTime(n"MagnetPerchStarted", 0.2f))
			return EHazeNetworkActivation::DontActivate;

		if(!SuperMagnet.IsWallPerch())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Get currently activated magnet
		ActiveMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.ActivatedMagnet);

		// Initialize point of interest
		PointOfInterest.Duration = -1.f;
		PointOfInterest.Blend = 1.f;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.FocusTarget.WorldOffset = PlayerOwner.ActorCenterLocation;

		// Consume magnet perch action state
		ConsumeAction(n"MagnetPerchStarted");

		// Clear offset
		PoiOffset = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		FVector LeftStickInput = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		FVector RightStickInput = GetAttributeVector(AttributeVectorNames::RightStickRaw);

		// Store magnetic input bias in MagneticPlayerComponent,
		// this will be used by the super magnet when calculating its validation score alpha
		FVector RawInput = LeftStickInput.Size() > RightStickInput.Size() ? LeftStickInput : RightStickInput;
		if(RawInput.Size() > 0.2f)
		{
			FVector AdjustedInput = MagneticPlayerComponent.Owner.ActorRightVector * RawInput.X + PlayerOwner.MovementWorldUp * RawInput.Y;
			MagneticPlayerComponent.PlayerInputBias = AdjustedInput.VectorPlaneProject(ActiveMagnet.MagneticVector).GetSafeNormal();
			PoiOffset += MagneticPlayerComponent.PlayerInputBias * 360.f * RawInput.Size() * RawInput.Size();
			PoiOffset = PoiOffset.GetClampedToMaxSize(800.f);
		}

		// Apply point of interest
		PointOfInterest.FocusTarget.WorldOffset = PlayerOwner.ActorCenterLocation + PoiOffset;
		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);

		// Update them super magnets
		MagneticPlayerComponent.QueryMagnets();

		// Draw magnet effect highlight on targetted magnet
		if(MagneticPlayerComponent.TargetedMagnet != nullptr && MagneticPlayerComponent.TargetedMagnet.IsA(UMagneticPerchAndBoostComponent::StaticClass()))
		{
			TargetedMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.TargetedMagnet);

			// Activate effect for magnetic component if it wasn't active or if player switched target
			// (yeah... activate means also switch target on magnetic effect BP)
			if(!MagneticEffect.bActive || MagneticEffect.InteractingActor != TargetedMagnet.Owner)
				MagneticEffect.ActivateMagneticEffect(TargetedMagnet.Owner, MagneticPlayerComponent, TargetedMagnet, false);
		}
		else if(MagneticEffect.bActive)
		{
			MagneticEffect.DeactivateMagneticEffect();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerComponent.ActivatedMagnet == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!PlayerOwner.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchPerchCapability))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ActiveMagnet.IsWallPerch())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!HasControl())
			return;

		// Lock into targetted magnet if player is jumping away from perch
		if(IsActioning(FMagneticTags::PlayerMagnetLaunchJumpFromPerchState) && TargetedMagnet != nullptr)
			TargetedMagnet.PrioritizeForPlayerOverTime(PlayerOwner, 1.f);

		// Clear input bias vector
		MagneticPlayerComponent.PlayerInputBias = FVector::ZeroVector;

		// Deactivate effect
		if(MagneticEffect.bActive)
			MagneticEffect.DeactivateMagneticEffect();

		ActiveMagnet = nullptr;
		TargetedMagnet = nullptr;

		PlayerOwner.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(MagneticEffect != nullptr)
		{
			MagneticEffect.DeactivateMagneticEffect();
			MagneticEffect.DetachFromActor();
			MagneticEffect.DestroyActor();
			MagneticEffect = nullptr;
		}
	}
}