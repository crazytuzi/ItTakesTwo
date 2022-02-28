import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetPadAnimationDataAsset;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionBreakableObstacle;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.MagneticPlayerAttractionPerchAnimationDataAsset;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionEffectsDataAsset;
import Vino.PlayerHealth.PlayerHealthComponent;

event void FMagneticPlayerAttractionEvent(AHazePlayerCharacter PerchingPlayer, FVector PerchLocation);
event void FMagneticPlayerAttractionMeetingEvent(FVector SpawnLocation, FRotator SpawnRotation, bool bSmashObstacle);

enum EMagneticPlayerAttractionState
{
	Inactive,
	Charging,
	Launching,
	Perching,
	LeavingPerch,
	DoubleLaunchStun
}

enum EMagneticPlayerAttractionLaunchType
{
	None,
	SingleLaunch,
	SingleLaunchFail,
	DoubleLaunch,
	DoubleLaunchSmash
}

class UMagneticPlayerAttractionComponent : UMagneticComponent
{
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 4500.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 4000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 2500.f);

	default bUseGenericMagnetAnimation = false;

	UPROPERTY(Category = "Animation")
	UPlayerMagnetPadAnimationDataAsset AnimationStateMachineAsset;

	UPROPERTY(Category = "Animation")
	UMagneticPlayerAttractionPerchAnimationDataAsset PlayerAttractionPerchAnimationDataAsset;


	// Charge stuff =======================================
	UPROPERTY(Category = "Charging")
	UHazeCameraSpringArmSettingsDataAsset ChargeCameraSettings;

	UPROPERTY(Category = "Charging", DisplayName = "Camera Shake")
	TSubclassOf<UCameraShakeBase> ChargeCameraShakeClass;


	// Launch stuff =======================================
	UPROPERTY(Category = "Launching")
	UCurveFloat LaunchSpeedCurve;

	UPROPERTY(Category = "Launching")
	UHazeCameraSpringArmSettingsDataAsset SingleLaunchCameraSettings;

	UPROPERTY(Category = "Launching")
	UHazeCameraSpringArmSettingsDataAsset DoubleLaunchCameraSettings;

	UPROPERTY(Category = "Launching")
	UNiagaraSystem TrailEffect;


	// Perch stuff ========================================
	UPROPERTY(Category = "Perching")
	UMovementSettings PerchedMovementSettings;

	UPROPERTY(Category = "Perching")
	TSubclassOf<UCameraShakeBase> PerchCameraShakeClass;

	UPROPERTY(Category = "Perching")
	UForceFeedbackEffect PerchForceFeedback;


	// Double launch stuff ================================
	UPROPERTY(Category = "Double Launching")
	float DoubleLaunchFinalDistanceFromPlayer = 80.f;

	UPROPERTY(Category = "Double Launching")
	float DoubleLaunchStunTime = 1.1f;

	UPROPERTY(Category = "Double Launching")
	UForceFeedbackEffect DoubleLaunchCollisionFeedback;


	UPROPERTY(Category = "Visual FX")
	private UMagneticPlayerAttractionEffectsDataAsset EffectsDataAsset;


	AHazePlayerCharacter PlayerOwner;

	UPlayerPickupComponent PickupComponent;
	UPlayerHealthComponent PlayerHealthComponent;
	UPlayerRespawnComponent PlayerRespawnComponent;

	AMagneticPlayerAttractionBreakableObstacle BreakableObstacle = nullptr;

	private UNiagaraComponent PerchHoldEffectComponent;

	EMagneticPlayerAttractionState AttractionState = EMagneticPlayerAttractionState::Inactive;
	EMagneticPlayerAttractionLaunchType AttractionLaunchType = EMagneticPlayerAttractionLaunchType::None;

	FVector DoubleLaunchMeetingPoint;

	// Used by DoubleLaunchSmash and SingleLaunchPerchAndFail capabilities
	FVector BreakableObstaclePerchPointLocation;
	FVector BreakableObstaclePerchPointNormal;

 	bool bChargingIsDone;
	bool bIsPerchingOnObstacle;

	bool bLaunchingIsDone;
	bool bWaitingForOtherPlayer;

	bool bIsPiggybacking;
	bool bIsCarryingPlayer;

	bool bIsReadyToSmashBreakable;

	bool bDoubleLaunchStunIsDone;

	const float MinDistanceForLaunch = 500.f;


	// Fired as soon as player starts perching on other player's magnet
	UPROPERTY()
	FMagneticPlayerAttractionEvent OnMagneticPlayerPerchingStartedEvent;

	// Fired when player stops perching on other player's magnet
	UPROPERTY()
	FMagneticPlayerAttractionEvent OnMagneticPlayerPerchingEndedEvent;

	// Fired when both players collided after simultaneous attraction
	UPROPERTY()
	FMagneticPlayerAttractionMeetingEvent OnBothPlayersAttractedEvent;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		PickupComponent = UPlayerPickupComponent::Get(Owner);
		PlayerHealthComponent = UPlayerHealthComponent::Get(Owner);
		PlayerRespawnComponent = UPlayerRespawnComponent::Get(Owner);

		SetWorldLocation(PlayerOwner.GetActorCenterLocation());

		Polarity = PlayerOwner.IsCody() ? EMagnetPolarity::Plus_Red : EMagnetPolarity::Minus_Blue;
		ChangeValidActivator(PlayerOwner.IsCody() ? EHazeActivationPointActivatorType::May : EHazeActivationPointActivatorType::Cody);

		// Bind delegates
		OnMagneticPlayerPerchingStartedEvent.AddUFunction(this, n"OnMagneticPlayerPerchingStarted");
		OnMagneticPlayerPerchingEndedEvent.AddUFunction(this, n"OnMagneticPlayerPerchingEnded");
		OnBothPlayersAttractedEvent.AddUFunction(this, n"OnBothPlayersAttracted");
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter PlayerCharacter, FHazeQueriedActivationPoint& Query)const
	{
		if(bIsDisabled)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(DisabledForObjects.Contains(PlayerCharacter))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't allow activation if other player is not rendered in player's viewport
		if(!IsInCameraView(PlayerCharacter))
			return EHazeActivationPointStatusType::Invalid;

		// Don't interrupt normal magnet attraction interaction
		if(PlayerCharacter.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunch))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't allow player to interact with the other one if he/she is perching on player
		if(PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionPerchCapability))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't launch if other player is already launching
		if(PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionSingleLaunchCapability))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't activate MPA if player is launching towards super magnet
		if(PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunch))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't activate MPA if player is boosting from super magnet
		if(PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetBoost))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't activate if player is dying-respawning
		if(PlayerHealthComponent.bIsDead || PlayerRespawnComponent.bIsRespawning)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		TArray<AActor> IgnoredActors;
		if(PickupComponent.IsHoldingObject())
			IgnoredActors.Add(PickupComponent.CurrentPickup);

		UPlayerPickupComponent OtherPlayerPickupComponent = UPlayerPickupComponent::Get(PlayerCharacter.OtherPlayer);
		if(UPlayerPickupComponent::Get(PlayerCharacter.OtherPlayer).IsHoldingObject())
			IgnoredActors.Add(OtherPlayerPickupComponent.CurrentPickup);

		FFreeSightToActivationPointParams SightTestParams;
		SightTestParams.IgnoredActors = IgnoredActors;
		SightTestParams.IgnoredActorClass = AMagneticPlayerAttractionBreakableObstacle::StaticClass();
		SightTestParams.TraceFromPlayerBone = n"MiddleBrow";

		if(!ActivationPointsStatics::CanPlayerReachActivationPoint(PlayerCharacter, Query, ETraceTypeQuery::Visibility, SightTestParams))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{
		// Lower activation point priority
		return 0.5f;
	}

	void PlayLaunchCameraShakeAndForceFeedback(AHazePlayerCharacter PlayerCharacter, float RumbleScale)
	{
		// Handle force feedback
		PlayerCharacter.SetFrameForceFeedback(RumbleScale, RumbleScale);

		// Play camera shake
		PlayerCharacter.PlayCameraShake(PerchCameraShakeClass, 1.f);
	}

	bool IsInCameraView(AHazePlayerCharacter PlayerCharacter) const override
	{
		return SceneView::IsInView(PlayerCharacter, PlayerOwner.ActorCenterLocation);
	}

	UHazeLocomotionStateMachineAsset GetAnimationFeature()
	{
		if(PickupComponent.IsHoldingObject())
		{
			switch(PickupComponent.GetPickupType())
			{
				case EPickupType::Small:
				case EPickupType::HeavySmall:
					return AnimationStateMachineAsset.SmallPickupLocomotionStateMachine;

				case EPickupType::Big:
					return AnimationStateMachineAsset.PickupLocomotionStateMachine;
			}
		}

		return AnimationStateMachineAsset.NormalLocomotionStateMachine;
	}

	UFUNCTION(BlueprintPure)
	bool IsCharging()
	{
		return AttractionState == EMagneticPlayerAttractionState::Charging;
	}

	UFUNCTION(BlueprintPure)
	bool IsLaunching()
	{
		return AttractionState == EMagneticPlayerAttractionState::Launching;
	}

	UFUNCTION(BlueprintPure)
	bool IsPerchingOnObstacle()
	{
		return bIsPerchingOnObstacle;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerAttractionActive()
	{
		return bIsPiggybacking || bIsCarryingPlayer;
	}

	UFUNCTION(BlueprintPure)
	bool IsWaitingForOtherPlayer()
	{
		return bWaitingForOtherPlayer;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMagneticPlayerPerchingStarted(AHazePlayerCharacter PerchingPlayer, FVector PerchLocation)
	{
		// Play one shot kewl effect; render-only on the spawning player
		UNiagaraComponent MergeEffect;
		if(PerchingPlayer == PlayerOwner)
			MergeEffect = Niagara::SpawnSystemAtLocation(EffectsDataAsset.StartPerchEffect, PerchLocation, PlayerOwner.ActorRotation);

		// Start playing looping perch effect on perchee
		if(PerchingPlayer != PlayerOwner)
			PerchHoldEffectComponent = Niagara::SpawnSystemAttached(EffectsDataAsset.PerchHoldEffect, PlayerOwner.Mesh, n"Totem", FVector::ZeroVector, PlayerOwner.ActorRotation, EAttachLocation::SnapToTarget, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMagneticPlayerPerchingEnded(AHazePlayerCharacter PerchingPlayer, FVector PerchLocation)
	{
		if(PerchHoldEffectComponent != nullptr)
		{
			PerchHoldEffectComponent.Deactivate();
			PerchHoldEffectComponent.DestroyComponent(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBothPlayersAttracted(FVector SpawnLocation, FRotator Rotation, bool bSmashObstacle)
	{
		// Spawn effect and render in other player's viewport only
		UNiagaraComponent MergeEffect = Niagara::SpawnSystemAtLocation(EffectsDataAsset.DoubleLaunchCollisionEffect, SpawnLocation, Rotation);
		MergeEffect.SetRenderedForPlayer(PlayerOwner.OtherPlayer, true);
		MergeEffect.SetRenderedForPlayer(PlayerOwner, false);

		if(bSmashObstacle)
		{
			UNiagaraComponent SmashEffect = Niagara::SpawnSystemAtLocation(EffectsDataAsset.DoubleLaunchObstacleSmashEffect, SpawnLocation, Rotation);
			MergeEffect.SetRenderedForPlayer(PlayerOwner.OtherPlayer, true);
			MergeEffect.SetRenderedForPlayer(PlayerOwner, false);
		}
	}

	// Net functions /////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////

	UFUNCTION(NetFunction)
	void NetSetAttractionState(EMagneticPlayerAttractionState NetAttractionState)
	{
		AttractionState = NetAttractionState;
	}

	UFUNCTION(NetFunction)
	void NetSetChargingIsDone(bool bNetChargingIsDone)
	{
		bChargingIsDone = bNetChargingIsDone;
	}

	UFUNCTION(NetFunction)
	void NetSetLaunchingIsDone(bool bNetLaunchingIsDone)
	{
		bLaunchingIsDone = bNetLaunchingIsDone;
	}

	UFUNCTION(NetFunction)
	void NetSetWaitingForOtherPlayer(bool bNetWaitingForOtherPlayer)
	{
		bWaitingForOtherPlayer = bNetWaitingForOtherPlayer;
	}

	UFUNCTION(NetFunction)
	void NetSetIsPerchingOnObstacle(bool bNetIsPerchingOnObstacle)
	{
		bIsPerchingOnObstacle = bNetIsPerchingOnObstacle;
	}

	UFUNCTION(NetFunction)
	void NetSetBreakableObstacleParams(AMagneticPlayerAttractionBreakableObstacle NetBreakableObstacle, FVector NetBreakableObstaclePerchPointLocation, FVector NetBreakableObstaclePerchPointNormal)
	{
		BreakableObstacle = NetBreakableObstacle;
		BreakableObstaclePerchPointLocation = NetBreakableObstaclePerchPointLocation;
		BreakableObstaclePerchPointNormal = NetBreakableObstaclePerchPointNormal;
	}

	UFUNCTION(NetFunction)
	void NetSetIsReadyToSmashBreakable(bool bNetIsReadyToSmashBreakable)
	{
		bIsReadyToSmashBreakable = bNetIsReadyToSmashBreakable;
	}

	UFUNCTION(NetFunction)
	void NetSmashBreakableObstacle(AMagneticPlayerAttractionBreakableObstacle FallbackObstacle)
	{
		if(BreakableObstacle == nullptr)
		{
			if (FallbackObstacle != nullptr)
			{
				FallbackObstacle.Break(PlayerOwner.MovementWorldUp);
				return;
			}
			else
			{
				Print("Can't break nullptr breakable, chap");
				return;
			}
		}

		BreakableObstacle.Break(PlayerOwner.MovementWorldUp);
	}

	UFUNCTION(NetFunction)
	void NetSetDoubleLaunchStunIsDone(bool bNetDoubleLaunchStunIsDone)
	{
		bDoubleLaunchStunIsDone = bNetDoubleLaunchStunIsDone;
	}
}
