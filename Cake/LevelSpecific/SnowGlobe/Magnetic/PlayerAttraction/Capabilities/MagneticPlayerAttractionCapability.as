import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.Capabilities.MagneticPlayerAttractionAudioEventHandler;
import Vino.PlayerHealth.PlayerHealthComponent;

class UMagneticPlayerAttractionCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionMasterCapability);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 90;

	default CapabilityDebugCategory = n"LevelSpecific";

	UPROPERTY()
	TSubclassOf<UMagneticPlayerAttractionAudioEventHandler> MagnetEventHandlerClass;

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent PlayerMagnet;
	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;
	UMagneticPlayerAttractionComponent OtherPlayerMagneticPlayerAttraction;

	UHazeMovementComponent MovementComponent;

	// Used to keep velocity when transitioning from MPA to normal movement
	FVector JumpFromPlayerDeactivationVelocity;

	const float JumpFromPlayerDuration = 0.5f;
	float JumpFromPlayerElapsedTime;

	float ElapsedTime;

	bool bStunDeactivation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnet = UMagneticPlayerComponent::Get(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		OtherPlayerMagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(Owner);

		// Add magnetic player attraction audio event handler to the player magnet actor
		if(MagnetEventHandlerClass.IsValid())
			PlayerMagnet.PlayerMagnet.AddCapability(MagnetEventHandlerClass);
		else
			Warning("MagnetEventHandlerClass in " + Name + " is NULL!");

		// Bind death event
		if(HasControl())
		{
			UPlayerHealthComponent::Get(PlayerOwner).OnPlayerDied.BindUFunction(this, n"OnPlayerDying");
			UPlayerHealthComponent::Get(PlayerOwner.OtherPlayer).OnPlayerDied.BindUFunction(this, n"OnPlayerDying");
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Avoid spamming
		if(WasActionStartedDuringTime(FMagneticTags::MagnetAttractionJustDeactivated, 0.2f))
			return EHazeNetworkActivation::DontActivate;

		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!MagneticPlayerAttractionComponent.IsInfluencedBy(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Inactive)
			return EHazeNetworkActivation::DontActivate;

		// Don't activate if other player is already launching towards us
		if(OtherPlayerMagneticPlayerAttraction.bChargingIsDone && !OtherPlayerMagneticPlayerAttraction.IsPerchingOnObstacle())
			return EHazeNetworkActivation::DontActivate;

		// Don't activate if other player is interacting with super magnets
		if(OtherPlayerIsInteractingWithSuperMagnet())
			return EHazeNetworkActivation::DontActivate;

		// Don't activate if other player is dying-respawning
		if(UPlayerRespawnComponent::Get(PlayerOwner.OtherPlayer).bIsRespawning || UPlayerHealthComponent::Get(PlayerOwner.OtherPlayer).bIsDead)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControlWithValidation;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ValidationParams) const
	{
		// Don't activate if other player is interacting with super magnets
		if(OtherPlayerIsInteractingWithSuperMagnet())
			return false;

		// Don't activate if other player is dying-respawning
		if(UPlayerRespawnComponent::Get(PlayerOwner.OtherPlayer).bIsRespawning || UPlayerHealthComponent::Get(PlayerOwner.OtherPlayer).bIsDead)
			return false;

		// Don't activate if other player is already launching towards us
		return !OtherPlayerMagneticPlayerAttraction.bChargingIsDone || OtherPlayerMagneticPlayerAttraction.IsPerchingOnObstacle();
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.EnableTransformSynchronizationWithTime();
		SyncParams.AddVector(n"PlayerToOtherPlayer", (PlayerOwner.OtherPlayer.GetActorLocation() - PlayerOwner.GetActorLocation()).GetSafeNormal());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(FMagneticTags::MagnetAttractionJustDeactivated);

		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);

		PlayerOwner.TriggerMovementTransition(this);

		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		MagneticPlayerAttraction.AttractionState = EMagneticPlayerAttractionState::Charging;

		PlayerOwner.SetCapabilityAttributeVector(n"PlayerToOtherPlayer", ActivationParams.GetVector(n"PlayerToOtherPlayer"));
		PlayerMagnet.ActivateMagnetLockon(MagneticPlayerAttraction, this);

		// Remove them player and magnet outlines!
		RemovePlayerOutlines(PlayerOwner);
		RemovePlayerOutlines(PlayerOwner.OtherPlayer);

		// Bind other player's magnet activation delegate
		if(HasControl())
			UMagneticPlayerComponent::Get(PlayerOwner.OtherPlayer).PlayerMagnet.OnMagnetActivated.AddUFunction(this, n"OnOtherPlayerActivatedMagnet");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Remote side is my bitch
		if(!HasControl())
			return;

		switch(MagneticPlayerAttraction.AttractionState)
		{
			case EMagneticPlayerAttractionState::Charging:
				TickCharging();
				break;

			case EMagneticPlayerAttractionState::Launching:
				TickLaunching();
				break;

			case EMagneticPlayerAttractionState::Perching:
				TickPerching();
				break;

			case EMagneticPlayerAttractionState::DoubleLaunchStun:
				TickDoubleLaunchStun();
				break;

			case EMagneticPlayerAttractionState::LeavingPerch:
				TickLeavingPerch(DeltaTime);
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::Inactive)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Ticking stun state deactivation has already unblocked movement capability
		if(!bStunDeactivation)
			PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);

		// Deactivate magnet component
		PlayerMagnet.DeactivateMagnetLockon(this);

		// Consume magnet input and clear trail
		PlayerOwner.CleanupCurrentMovementTrail();
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		// Add momentum if player jumped from other player
		if(!JumpFromPlayerDeactivationVelocity.IsZero())
		{
			MovementComponent.SetVelocity(JumpFromPlayerDeactivationVelocity);
			JumpFromPlayerDeactivationVelocity = FVector::ZeroVector;
		}

		// Fallback in case some MPA capability did an oopsie
		PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();

		// Restore them outlines
		RestorePlayerOutlines(PlayerOwner);
		RestorePlayerOutlines(PlayerOwner.OtherPlayer);

		if(HasControl())
		{
			// Unbind other player's magnet activation delegate
			UMagneticPlayerComponent::Get(PlayerOwner.OtherPlayer).PlayerMagnet.OnMagnetActivated.Unbind(this, n"OnOtherPlayerActivatedMagnet");

			// Fire launch done event if capability deactivated before launch was done
			// Could happen that state is inactive this frame if player died, check action state too
			if(MagneticPlayerAttraction.IsLaunching() || IsActioning(n"WasLaunching"))
				NetFireLaunchDoneEvent();
		}

		// Cleanup
		MagneticPlayerAttraction.AttractionState = EMagneticPlayerAttractionState::Inactive;
		MagneticPlayerAttraction.AttractionLaunchType = EMagneticPlayerAttractionLaunchType::None;
		MagneticPlayerAttraction.BreakableObstacle = nullptr;

		MagneticPlayerAttraction.bChargingIsDone = false;
		MagneticPlayerAttraction.bLaunchingIsDone = false;
		MagneticPlayerAttraction.bIsPerchingOnObstacle = false;

		MagneticPlayerAttraction.bIsCarryingPlayer = false;
		MagneticPlayerAttraction.bIsPiggybacking = false;

		MagneticPlayerAttraction.bWaitingForOtherPlayer = false;
		OtherPlayerMagneticPlayerAttraction.bWaitingForOtherPlayer = false;

		MagneticPlayerAttraction.bIsReadyToSmashBreakable = false;

		bStunDeactivation = false;

		// Set deactivated action to avoid spamming
		PlayerOwner.SetCapabilityActionState(FMagneticTags::MagnetAttractionJustDeactivated, EHazeActionState::Active);
	}

	void TickCharging()
	{
		// Return if we're still charging (the charge capability will set this boolean)
		if(!MagneticPlayerAttraction.bChargingIsDone)
		{
			if(!IsActioning(ActionNames::PrimaryLevelAbility))
				MagneticPlayerAttraction.NetSetAttractionState(EMagneticPlayerAttractionState::Inactive);

			return;
		}

		// Other player is not charging, let's launch!
		if((!OtherPlayerMagneticPlayerAttraction.IsCharging() && !MagneticPlayerAttraction.IsWaitingForOtherPlayer()))
		{
			// Check if there is a breakable obstacle in the way
			FVector HitLocation, HitNormal;
			AMagneticPlayerAttractionBreakableObstacle BreakableObstacle;
			if(IsBreakableInTheWay(BreakableObstacle, HitLocation, HitNormal, FVector(), FVector()))
			{
				// Communicate obstacle to other side and do fail launch
				MagneticPlayerAttraction.NetSetBreakableObstacleParams(BreakableObstacle, HitLocation, HitNormal);
				NetSetLaunchState(EMagneticPlayerAttractionLaunchType::SingleLaunchFail);
			}
			else
			{
				// Do normal single launch
				NetSetLaunchState(EMagneticPlayerAttractionLaunchType::SingleLaunch);
			}

			return;
		}

		// Other plalyer is charging and we're currently not waiting for him
		if(OtherPlayerMagneticPlayerAttraction.IsCharging() && !MagneticPlayerAttraction.IsWaitingForOtherPlayer())
		{
			// Notify of this side's charge completion and wait
			MagneticPlayerAttraction.NetSetWaitingForOtherPlayer(true);

			// Set meeting point since we are the first player to finish charging
			FVector PlayerToOtherPlayer = PlayerOwner.OtherPlayer.ActorLocation - PlayerOwner.ActorLocation;
			NetSetMeetingPoint(PlayerOwner.ActorLocation + PlayerToOtherPlayer * 0.5f);
		}

		// We're waiting for other player and he's done
		if(MagneticPlayerAttraction.IsWaitingForOtherPlayer() && OtherPlayerMagneticPlayerAttraction.bChargingIsDone && MagneticPlayerAttraction.AttractionLaunchType == EMagneticPlayerAttractionLaunchType::None)
		{
			// Check if there is a breakable obstacle in the way
			FVector HitLocation, HitNormal, OtherPlayerHitLocation, OtherPlayerHitNormal;
			AMagneticPlayerAttractionBreakableObstacle BreakableObstacle;
			if(IsBreakableInTheWay(BreakableObstacle, HitLocation, HitNormal, OtherPlayerHitLocation, OtherPlayerHitNormal))
			{
				// Communicate breakable obstacle to other side and smash launch to that fucker
				MagneticPlayerAttraction.NetSetBreakableObstacleParams(BreakableObstacle, HitLocation, HitNormal);
				OtherPlayerMagneticPlayerAttraction.NetSetBreakableObstacleParams(BreakableObstacle, OtherPlayerHitLocation, OtherPlayerHitNormal);

				NetSetLaunchState(EMagneticPlayerAttractionLaunchType::DoubleLaunchSmash);
			}
			else
			{
				// Carry on with normal double launch
				NetSetLaunchState(EMagneticPlayerAttractionLaunchType::DoubleLaunch);
			}

			// No need to network other player, capabilities activate locally
			OtherPlayerMagneticPlayerAttraction.AttractionState = EMagneticPlayerAttractionState::Launching;
			OtherPlayerMagneticPlayerAttraction.AttractionLaunchType = MagneticPlayerAttraction.AttractionLaunchType;

			// Consume trigger input
			PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		}
	}

	void TickLaunching()
	{
		// Launching cannot be cancelled
		if(!MagneticPlayerAttraction.bLaunchingIsDone)
			return;

		NetFireLaunchDoneEvent();

		// If this was a double launch then we proceed to stun state
		if(MagneticPlayerAttraction.AttractionLaunchType >= EMagneticPlayerAttractionLaunchType::DoubleLaunch)
		{
			MagneticPlayerAttraction.NetSetAttractionState(EMagneticPlayerAttractionState::DoubleLaunchStun);
			return;
		}

		// Progress state to perching
		MagneticPlayerAttraction.NetSetAttractionState(EMagneticPlayerAttractionState::Perching);
	}

	void TickPerching()
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
		{
			// Player was perching on other player
			if(MagneticPlayerAttraction.bIsPiggybacking)
			{
				// Set actor location to other player's totem bone and leave state transition crumb
				PlayerOwner.SetActorLocation(PlayerOwner.OtherPlayer.Mesh.GetSocketLocation(n"Totem"));
				LeavePlayerPerch(-PlayerOwner.OtherPlayer.ActorForwardVector, true);
				return;
			}

			// Player was perching on breakable obstacle and is allowed to stahp
			if(CanStopPerchingOnObstacle())
			{
				LeavePlayerPerch(MagneticPlayerAttraction.BreakableObstaclePerchPointNormal, false);
				return;
			}
		}

		// This was a botched single launch, both players are perching on breakable obstacle, smash it!
		if(MagneticPlayerAttraction.bIsReadyToSmashBreakable && OtherPlayerMagneticPlayerAttraction.bIsReadyToSmashBreakable)
		{
			MagneticPlayerAttraction.NetSmashBreakableObstacle(MagneticPlayerAttraction.BreakableObstacle);
			MagneticPlayerAttraction.NetSetAttractionState(EMagneticPlayerAttractionState::DoubleLaunchStun);

			// Spawn merge effect between players
			MagneticPlayerAttraction.OnBothPlayersAttractedEvent.Broadcast(FMath::Lerp(PlayerOwner.ActorLocation, PlayerOwner.OtherPlayer.ActorLocation, 0.5f), PlayerOwner.CurrentlyUsedCamera.RightVector.Rotation(), true);
		}
	}

	void TickDoubleLaunchStun()
	{
		if(MagneticPlayerAttraction.bDoubleLaunchStunIsDone)
		{
			MagneticPlayerAttraction.bDoubleLaunchStunIsDone = false;
			MagneticPlayerAttraction.NetSetAttractionState(EMagneticPlayerAttractionState::Inactive);

			bStunDeactivation = true;
			PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);

			PlayerOwner.SetCapabilityActionState(n"MPA_MovementUnblockedAfterStun", EHazeActionState::ActiveForOneFrame);
		}
	}

	void TickLeavingPerch(float DeltaTime)
	{
		JumpFromPlayerElapsedTime += DeltaTime;
		if(ShouldDeactivateLeavingPerch())
		{
			SetAttractionStateWithCrumb(EMagneticPlayerAttractionState::Inactive);
			JumpFromPlayerDeactivationVelocity = MovementComponent.ActualVelocity;
		}
	}

	void LeavePlayerPerch(FVector JumpDirection, bool bCrumbify)
	{
		JumpFromPlayerElapsedTime = 0.f;
		PlayerOwner.SetCapabilityAttributeVector(FMagneticTags::MagneticPlayerAttractionLeavePerchHorizontalDirection, JumpDirection);

		if(bCrumbify)
			SetAttractionStateWithCrumb(EMagneticPlayerAttractionState::LeavingPerch);
		else
			MagneticPlayerAttraction.NetSetAttractionState(EMagneticPlayerAttractionState::LeavingPerch);
	}

	bool ShouldDeactivateLeavingPerch()
	{
		if(!MovementComponent.IsAirborne())
			return true;

		if(MovementComponent.UpHit.bBlockingHit)
			return true;
		
		// If any impulses are applied, cancel the jump
		FVector Impulse = FVector::ZeroVector;
		MovementComponent.GetAccumulatedImpulse(Impulse);
		if(!Impulse.IsNearlyZero())
			return true;

		if(JumpFromPlayerElapsedTime >= JumpFromPlayerDuration)
			return true;

		return false;
	}

	bool IsBreakableInTheWay(AMagneticPlayerAttractionBreakableObstacle& BreakableObstacle, FVector& EntryHitLocation, FVector& EntryHitNormal, FVector& ExitHitLocation, FVector& ExitHitNormal)
	{
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(MovementComponent);
		TraceParams.IgnoreActor(Owner);
		TraceParams.IgnoreActor(PlayerOwner.OtherPlayer);
		TraceParams.TraceShape = MovementComponent.CollisionShape;
		TraceParams.UnmarkToTraceWithOriginOffset();

		// Set to line to avoid tracing against other shit
		// Maybe do multi tracing instead?
		TraceParams.SetToLineTrace();

		TraceParams.From = PlayerOwner.ActorCenterLocation;
		TraceParams.To = PlayerOwner.OtherPlayer.ActorCenterLocation;

		FHazeHitResult HitResult;
		if(TraceParams.Trace(HitResult))
		{
			if(HitResult.Actor.IsA(AMagneticPlayerAttractionBreakableObstacle::StaticClass()))
			{
				// Fill-in properties and return obstacle
				BreakableObstacle = Cast<AMagneticPlayerAttractionBreakableObstacle>(HitResult.Actor);
				EntryHitLocation = HitResult.ShapeLocation;
				EntryHitNormal = HitResult.Normal;

				// Now flip trace to get other player's hit info
				TraceParams.From = PlayerOwner.OtherPlayer.ActorCenterLocation;
				TraceParams.To = PlayerOwner.ActorCenterLocation;
				TraceParams.Trace(HitResult);

				ExitHitLocation = HitResult.ShapeLocation;
				ExitHitNormal = HitResult.Normal;

				return true;
			}
		}

		return false;
	}

	bool CanStopPerchingOnObstacle()
	{
		if(!MagneticPlayerAttraction.IsPerchingOnObstacle())
			return false;

		if(OtherPlayerMagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::Launching || OtherPlayerMagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::Charging || OtherPlayerMagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::Perching)
			return false;

		return true;
	}

	bool OtherPlayerIsInteractingWithSuperMagnet() const
	{
		if(PlayerOwner.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunch))
			return true;

		if(PlayerOwner.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetBoost))
			return true;

		return false;
	}

	void RemovePlayerOutlines(AHazePlayerCharacter PlayerCharacter)
	{
		USkeletalMeshComponent MagnetMesh = UMagneticPlayerComponent::Get(PlayerCharacter.OtherPlayer).PlayerMagnet.MagnetMesh;
		UOutlinesComponent OutlinesComponent = UOutlinesComponent::Get(PlayerCharacter);

		OutlinesComponent.SetOutlineViewport(PlayerCharacter.OtherPlayer.Mesh, EOutlineViewport::Neither);
		OutlinesComponent.SetOutlineViewport(MagnetMesh, EOutlineViewport::Neither);
	}

	void RestorePlayerOutlines(AHazePlayerCharacter PlayerCharacter)
	{
		USkeletalMeshComponent MagnetMesh = UMagneticPlayerComponent::Get(PlayerCharacter.OtherPlayer).PlayerMagnet.MagnetMesh;
		UOutlinesComponent OutlinesComponent = UOutlinesComponent::Get(PlayerCharacter);

		EOutlineViewport OutlineViewport = PlayerCharacter.OtherPlayer.IsCody() ? EOutlineViewport::May : EOutlineViewport::Cody;
		OutlinesComponent.SetOutlineViewport(PlayerCharacter.OtherPlayer.Mesh, OutlineViewport);
		OutlinesComponent.SetOutlineViewport(MagnetMesh, OutlineViewport);
	}

	void SetAttractionStateWithCrumb(EMagneticPlayerAttractionState AttractionState)
	{
		UHazeCrumbComponent CrumbComponent = UHazeCrumbComponent::Get(Owner);

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddValue(n"NextAttractionState", AttractionState);
		CrumbParams.Movement = EHazeActorReplicationSyncTransformType::SmoothTeleport;

		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetAttractionState"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_SetAttractionState(const FHazeDelegateCrumbData& CrumbData)
	{
		if(CrumbData.IsStale())
			return;

		MagneticPlayerAttraction.AttractionState = EMagneticPlayerAttractionState(CrumbData.GetValue(n"NextAttractionState"));
	}

	UFUNCTION(NotBlueprintCallable)
	void OnOtherPlayerActivatedMagnet(UMagneticComponent Magnet, bool bEqualPolarities)
	{
		if(MagneticPlayerAttraction == nullptr)
			return;

		// Deactivate MPA if other player is engaging with a super magnet
		if(Magnet.IsA(UMagneticPerchAndBoostComponent::StaticClass()))
			MagneticPlayerAttraction.NetSetAttractionState(EMagneticPlayerAttractionState::Inactive);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerDying(AHazePlayerCharacter PlayerCharacter)
	{
		if(MagneticPlayerAttraction != nullptr)
		{
			if(MagneticPlayerAttraction.IsLaunching())
				PlayerOwner.SetCapabilityActionState(n"WasLaunching", EHazeActionState::ActiveForOneFrame);

			MagneticPlayerAttraction.AttractionState = EMagneticPlayerAttractionState::Inactive;
		}
	}

	// Net Functions /////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////

	UFUNCTION(NetFunction)
	void NetSetLaunchState(EMagneticPlayerAttractionLaunchType NetLaunchType)
	{
		MagneticPlayerAttraction.AttractionState = EMagneticPlayerAttractionState::Launching;
		MagneticPlayerAttraction.AttractionLaunchType = NetLaunchType;
	}

	UFUNCTION(NetFunction)
	void NetSetMeetingPoint(FVector NetMeetingPoint)
	{
		MagneticPlayerAttraction.DoubleLaunchMeetingPoint = NetMeetingPoint;
		OtherPlayerMagneticPlayerAttraction.DoubleLaunchMeetingPoint = NetMeetingPoint;
	}

	UFUNCTION(NetFunction)
	void NetFireLaunchDoneEvent()
	{
		PlayerMagnet.PlayerMagnet.OnLaunchDone.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(MagneticPlayerAttraction == nullptr)
			return "N/A";

		switch(MagneticPlayerAttraction.AttractionState)
		{
			case EMagneticPlayerAttractionState::Charging:
				return "AttractionState: Charging";

			case EMagneticPlayerAttractionState::Launching:
				return "AttractionState: Launching";

			case EMagneticPlayerAttractionState::Perching:
				return "AttractionState: Perching";

			case EMagneticPlayerAttractionState::DoubleLaunchStun:
				return "AttractionState: DoubleLaunchStun";

			case EMagneticPlayerAttractionState::LeavingPerch:
				return "AttractionState: LeavingPerch";
		}

		return "AttractionState: Inactive";
	}
}