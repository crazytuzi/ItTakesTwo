import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.SequenceCloneActor;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerCloneAutoDirectionVolume;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

class UCharacterSequenceTeleportCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TimeControlCapabilityTags::TimeSequenceCapability);
	default CapabilityTags.Add(n"Sequence");
	default CapabilityTags.Add(n"SequenceTeleport");

	default BlockExclusionTags.Add(BlockExclusionTags::UsableDuringGroundPound);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UTimeControlSequenceComponent SeqComp;
	UHazeJumpToComponent JumpToComp;

    bool bReachedDestination = true;
	const float DelayBeforeCameraBlend = 0.1f;
	const float DelayBeforeTeleport = 0.45f;
	const float DelayBeforeLaunch = 0.2f;
	float Time = 0;
	bool TeleportCalled = false;
	bool LaunchCalled = false;
	bool bStartedCameraBlend = false;
	FTransform CloneTransform = FTransform::Identity;
	bool WasTeleportValid = true;
	int TickCount = 0;
	bool bHasCalledPostTeleport = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);
        SeqComp = UTimeControlSequenceComponent::Get(Player);
		JumpToComp = UHazeJumpToComponent::GetOrCreate(Owner);
		ensure(SeqComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.1f))
			return EHazeNetworkActivation::DontActivate;

		if(!SeqComp.IsCloneActive())
			return EHazeNetworkActivation::DontActivate;

		// Slight hack not to teleport if we have a pending jumpto,
		// can happen if we press interact and teleport at the same
		// time, because this capability ticks before the jumpto capability.
		if (JumpToComp.ActiveJumpTos.Num() != 0)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (LaunchCalled)
		    return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SeqComp.bIsCurrentlyTeleporting = true;
		CloneTransform = SeqComp.GetCloneTransform();
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(n"CameraNonControlled", this);
		// Player.BlockCapabilities(CapabilityTags::Collision, this);
		Niagara::SpawnSystemAtLocation(SeqComp.TeleportStartEffect, Player.ActorLocation, Player.ActorRotation);

		FTransform OriginalCameraTransform = Player.CurrentlyUsedCamera.WorldTransform;

		WasTeleportValid = true;

		// Try to resolve collision before moving the actor
		if (SeqComp.bValidateTeleport)
			WasTeleportValid = PreValidateTeleport();

		Player.MeshOffsetComponent.FreezeAndResetWithSpeed(0.f, 0.f);

		// Lock the current camera position the player has, to blend from
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 0.f;
			SeqComp.CloneCamera_Start.ActorTransform = OriginalCameraTransform;
			SeqComp.CloneCamera_Start.ActivateCamera(Player, Blend);
		}
		bStartedCameraBlend = false;

		// Make sure the capability that leaves the clone understands that we need to land
		// before we can actually leave another one.
		Owner.SetCapabilityActionState(n"DisableLeaveCloneUntilLanding", EHazeActionState::Active);

		Player.PlayForceFeedback(SeqComp.TeleportForceFeedback, false, true, n"Teleport");

		// No damage during teleportation, else very weird stuff might happen
		AddPlayerInvulnerability(Player, this);

		SeqComp.CallCloneOnEvent(ESequenceEventType::OnStartedTeleport);
		Player.TeleportActor(CloneTransform.Location, CloneTransform.Rotator());
		Player.SnapCameraBehindPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(n"CameraNonControlled", this);
		// Player.UnblockCapabilities(CapabilityTags::Collision, this);
        bReachedDestination = false;
		Time = 0.f;
		TickCount = 0;

		if(!bHasCalledPostTeleport)
			SeqComp.CallCloneOnEvent(ESequenceEventType::OnPostStartedTeleport);

		if (!TeleportCalled)
		{
			SeqComp.DeactiveClone(Player);
			SeqComp.CallCloneOnEvent(ESequenceEventType::OnTeleportExecuted);
			Player.MeshOffsetComponent.FreezeAndResetWithTime(0.f);
		}

		if (!LaunchCalled)
			SeqComp.CallCloneOnEvent(ESequenceEventType::OnTeleportFinished);

		TeleportCalled = false;
		LaunchCalled = false;
		bHasCalledPostTeleport = false;
		//Material::SetScalarParameterValue(SeqComp.WorldShaderParameters, n"MayInflation", 0.f);

		// Snap the player's camera behind the player and blend out the locked camera
		if (!bStartedCameraBlend)
			SeqComp.CloneCamera_Start.DeactivateCamera(Player);
		else
			SeqComp.CloneCamera.DeactivateCamera(Player, 0.1f);

		SeqComp.bIsCurrentlyTeleporting = false;

		RemovePlayerInvulnerability(Player, this);
		
		// If pre-validation failed, let the movement component
		// depenetrate and ensure we didn't pass through objects
		if (SeqComp.bValidateTeleport && !WasTeleportValid && !PostValidateTeleport())
			KillPlayer(Player);
	}

	void TeleportPlayer()
	{
		if(!bHasCalledPostTeleport)
		{
			bHasCalledPostTeleport = true;
			SeqComp.CallCloneOnEvent(ESequenceEventType::OnPostStartedTeleport);
		}

		TeleportCalled = true;
		Player.MeshOffsetComponent.FreezeAndResetWithTime(0.f);
		SeqComp.CallCloneOnEvent(ESequenceEventType::OnTeleportExecuted);
		SeqComp.DeactiveClone(Player);
		Niagara::SpawnSystemAtLocation(SeqComp.TeleportEndEffect, CloneTransform.Location, CloneTransform.Rotator());
		Player.PlayCameraShake(SeqComp.TeleportCameraShake);
	}

	void LaunchPlayer()
	{
		if(!bHasCalledPostTeleport)
		{
			bHasCalledPostTeleport = true;
			SeqComp.CallCloneOnEvent(ESequenceEventType::OnPostStartedTeleport);
		}

		SeqComp.CallCloneOnEvent(ESequenceEventType::OnTeleportFinished);
		if (SeqComp.bCloneWasAirborne)
			Player.AddImpulse(SeqComp.AirborneCloneImpulse);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Sequence");
		MoveData.ApplyAndConsumeImpulses();
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveCharacter(MoveData, n"Movement");

		LaunchCalled = true;
	}

	void AnimatePlayer()
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Sequence");
		Player.SetAnimVectorParam(n"CloneLocation", CloneTransform.Location);
		MoveCharacter(MoveData, n"DigitalWatch", TeleportCalled ? n"TeleportEnter" : n"TeleportExit");
	}

	// Should be called prior to moving the actor.
	bool PreValidateTeleport()
	{
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(Player.MovementComponent);

		FVector CloneUpVector = CloneTransform.Rotation.UpVector;

		// Check if we'd overlap anything at clone location
		TArray<FOverlapResult> Overlaps;
		TraceParams.From = CloneTransform.Location;
		if (!TraceParams.Overlap(Overlaps))
			return true;

		// Step-down trace to see if we can solve the collision
		FHazeHitResult Hit;
		TraceParams.From = CloneTransform.Location + (CloneUpVector * 100.f);
		TraceParams.To = CloneTransform.Location;
		if (TraceParams.Trace(Hit) && !Hit.bStartPenetrating)
		{
			// Move clone transform to the new location
			CloneTransform.Location = Hit.ActorLocation + CloneUpVector;
			return true; 
		}

		return false;
	}

	// Should be called after moving the actor if the pre-validation step fails.
	bool PostValidateTeleport()
	{
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(Player.MovementComponent);
		TraceParams.SetToLineTrace();

		// Movement component has depenetrated at this point
		// make sure we haven't moved through any objects
		FHazeHitResult Hit;
		TraceParams.From = CloneTransform.Location;
		TraceParams.To = Player.ActorLocation;
		if (!TraceParams.Trace(Hit))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasCalledPostTeleport && TickCount >= 1)
		{
			bHasCalledPostTeleport = true;
			SeqComp.CallCloneOnEvent(ESequenceEventType::OnPostStartedTeleport);
		}

		// Snap the player's camera behind the player and blend out the locked camera
		if (!bStartedCameraBlend && Time >= DelayBeforeCameraBlend)
		{
			SeqComp.CloneCamera_Start.DeactivateCamera(Player, DelayBeforeTeleport - DelayBeforeCameraBlend);

			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = DelayBeforeTeleport - DelayBeforeCameraBlend;
			SeqComp.CloneCamera.ActivateCamera(Player, Blend);

			bStartedCameraBlend = true;
		}

		Time += DeltaTime;

		if (Time >= DelayBeforeTeleport && !TeleportCalled)
			TeleportPlayer();

		if (Time >= DelayBeforeLaunch + DelayBeforeTeleport && !LaunchCalled && MoveComp.CanCalculateMovement())
			LaunchPlayer();
		else if (MoveComp.CanCalculateMovement())
			AnimatePlayer();

		TickCount++;
	}
}
