import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.DoublePull.DoublePullComponent;
import Vino.DoublePull.DoublePullActor;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;

class UWindWalkDoublePullMagnetAttractionEffectCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::MagnetAttractionEffect);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UPROPERTY()
	UStaticMesh EffectMesh;

	UPROPERTY()
	UMaterialInterface EffectMaterial;
	UMaterialInstanceDynamic DynamicEffectMaterial;

	AHazePlayerCharacter PlayerOwner;
	UDoublePullComponent DoublePullComponent;

	APlayerMagnetActor PlayerMagnet;
	APlayerMagnetActor OtherPlayerMagnet;

	USplineMeshComponent EffectSplineMesh;

	// Scaling vars
	const float ScaleLerpDuration = 0.5f;
	const float InactiveScale = 0.06;
	const float ActiveScale = 0.5f;

	bool PlayerIsChargingMagnet;
	bool OtherPlayerIsChargingMagnet;
	bool bPlayerScaleIsLerping;
	bool bOtherPlayerScaleIsLerping;

	float PlayerScaleLerpTarget;
	float PlayerScaleLerpStart;
	float PlayerScaleLerpElapsedTime;

	float OtherPlayerScaleLerpTarget;
	float OtherPlayerScaleLerpStart;
	float OtherPlayerScaleLerpElapsedTime;

	// Opacity vars
	const float ActivationOpacityLerpDuration = 0.4f;
	const float DeactivationOpacityLerpDuration = 0.1f;

	float OpacityLerpDuration;
	float OpacityLerpElapsedTime;

	bool bIsLerpingOpacity;
	bool bOpacityLerpOutDone;
	bool bShouldDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		// Get magnet mesh actors
		PlayerMagnet = UMagneticPlayerComponent::Get(PlayerOwner).PlayerMagnet;
		OtherPlayerMagnet = UMagneticPlayerComponent::Get(PlayerOwner.OtherPlayer).PlayerMagnet;

		// Create spline
		EffectSplineMesh = USplineMeshComponent::GetOrCreate(Owner);
		EffectSplineMesh.SetMobility(EComponentMobility::Movable);

		// Setup material
		DynamicEffectMaterial = Material::CreateDynamicMaterialInstance(EffectMaterial);
		if(PlayerOwner.IsMay())
			DynamicEffectMaterial.SetScalarParameterValue(n"StartIsBlue", 1.f);
		else
			DynamicEffectMaterial.SetScalarParameterValue(n"EndIsBlue", 1.f);

		// Setup effect spline mesh
		EffectSplineMesh.SetStaticMesh(EffectMesh);
		EffectSplineMesh.SetMaterial(0, DynamicEffectMaterial);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UDoublePullComponent DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		if(DoublePull == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(SceneView::GetFullScreenPlayer() != PlayerOwner)
			return EHazeNetworkActivation::DontActivate;

		// Activate if players are not interacting with each other
		if(BothPlayersAreHoldingTrigger())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DoublePullComponent = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		EffectSplineMesh.SetStartScale(FVector2D(InactiveScale, InactiveScale));
		EffectSplineMesh.SetEndScale(FVector2D(InactiveScale, InactiveScale));
		EffectSplineMesh.SetHiddenInGame(false);

		// Opacity engage!
		bIsLerpingOpacity = true;
		OpacityLerpDuration = ActivationOpacityLerpDuration;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update effect spline points
		EffectSplineMesh.SetStartAndEnd(PlayerMagnet.GetMagnetEffectWorldLocation(), OtherPlayerMagnet.GetMagnetEffectWorldLocation() - PlayerMagnet.GetMagnetEffectWorldLocation(),
										OtherPlayerMagnet.GetMagnetEffectWorldLocation(), OtherPlayerMagnet.GetMagnetEffectWorldLocation() - PlayerMagnet.GetMagnetEffectWorldLocation());

		// Update effect's scale depending on players' input
		UpdatePlayerEndScale(DeltaTime);
		UpdateOtherPlayerEndScale(DeltaTime);

		// Update effect's direction
		DynamicEffectMaterial.SetScalarParameterValue(n"IsPulling", PlayerIsHoldingTrigger(PlayerOwner.OtherPlayer) ? 0.f : 1.f);

		// Handle effect opacity (changed when (de)activated)
		UpdateOpacity(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bOpacityLerpOutDone)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		EffectSplineMesh.SetHiddenInGame(true);

		DoublePullComponent = nullptr;
		OpacityLerpElapsedTime = 0.f;
		OpacityLerpDuration = 0.f;
		PlayerScaleLerpElapsedTime = 0.f;
		OtherPlayerScaleLerpElapsedTime = 0.f;

		bShouldDeactivate = false;
		bOpacityLerpOutDone = false;
		bIsLerpingOpacity = false;

		PlayerIsChargingMagnet = false;
	    OtherPlayerIsChargingMagnet = false;
	    bPlayerScaleIsLerping = false;
	    bOtherPlayerScaleIsLerping = false;
	}

	void UpdatePlayerEndScale(float DeltaTime)
	{
		if(PlayerIsHoldingTrigger(PlayerOwner) != PlayerIsChargingMagnet)
		{
			bPlayerScaleIsLerping = true;
			PlayerScaleLerpElapsedTime = 0.f;
			PlayerScaleLerpStart = EffectSplineMesh.GetStartScale().X;

			if(PlayerIsChargingMagnet = PlayerIsHoldingTrigger(PlayerOwner))
				PlayerScaleLerpTarget = ActiveScale;
			else
				PlayerScaleLerpTarget = InactiveScale;
		}

		if(bPlayerScaleIsLerping)
		{
			PlayerScaleLerpElapsedTime += DeltaTime;
			float Scale = FMath::Lerp(PlayerScaleLerpStart, PlayerScaleLerpTarget, Math::Saturate(PlayerScaleLerpElapsedTime / ScaleLerpDuration));

			EffectSplineMesh.SetStartScale(FVector2D(Scale, Scale));
		}
	}

	void UpdateOtherPlayerEndScale(float DeltaTime)
	{
		if(PlayerIsHoldingTrigger(PlayerOwner.OtherPlayer) != OtherPlayerIsChargingMagnet)
		{
			bOtherPlayerScaleIsLerping = true;
			OtherPlayerScaleLerpElapsedTime = 0.f;
			OtherPlayerScaleLerpStart = EffectSplineMesh.GetStartScale().X;

			if(OtherPlayerIsChargingMagnet = PlayerIsHoldingTrigger(PlayerOwner.OtherPlayer))
				OtherPlayerScaleLerpTarget = ActiveScale;
			else
				OtherPlayerScaleLerpTarget = InactiveScale;
		}

		if(bOtherPlayerScaleIsLerping)
		{
			OtherPlayerScaleLerpElapsedTime += DeltaTime;
			float Scale = FMath::Lerp(OtherPlayerScaleLerpStart, OtherPlayerScaleLerpTarget, Math::Saturate(OtherPlayerScaleLerpElapsedTime / ScaleLerpDuration));

			EffectSplineMesh.SetEndScale(FVector2D(Scale, Scale));
		}
	}

	void UpdateOpacity(float DeltaTime)
	{
		if(!bShouldDeactivate && ShouldDeactivate())
		{
			bShouldDeactivate = true;
			bIsLerpingOpacity = true;
			OpacityLerpElapsedTime = 0.f;
			OpacityLerpDuration = DeactivationOpacityLerpDuration;
		}

		if(!bIsLerpingOpacity)
			return;

		OpacityLerpElapsedTime += DeltaTime;
		if(OpacityLerpElapsedTime < OpacityLerpDuration)
		{
			float Opacity = Math::Saturate(OpacityLerpElapsedTime / OpacityLerpDuration);
			if(bShouldDeactivate)
				Opacity = 1.f - OpacityLerpElapsedTime;

			DynamicEffectMaterial.SetScalarParameterValue(n"Opacity", Opacity);
		}
		else
		{
			if(bShouldDeactivate)
			{
				bOpacityLerpOutDone = true;
				DynamicEffectMaterial.SetScalarParameterValue(n"Opacity", 0.f);
			}
			else
			{
				DynamicEffectMaterial.SetScalarParameterValue(n"Opacity", 1.f);
			}

			bIsLerpingOpacity = false;
		}
	}

	bool ShouldDeactivate()
	{
		if(SceneView::GetFullScreenPlayer() != PlayerOwner)
			return true;

		if(BothPlayersAreHoldingTrigger())
			return true;

		return false;
	}

	bool PlayerIsHoldingTrigger(AHazePlayerCharacter PlayerCharacter) const
	{
		return !PlayerCharacter.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger) || PlayerCharacter.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullMagnetCharge);
	}

	bool BothPlayersAreHoldingTrigger() const
	{
		return !PlayerOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger) && !PlayerOwner.OtherPlayer.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger);
	}
}