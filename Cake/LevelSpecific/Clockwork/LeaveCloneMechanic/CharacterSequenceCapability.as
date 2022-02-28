import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.SequenceCloneActor;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.MayTeleportWatch;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerCloneAutoDirectionVolume;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Pickups.PlayerPickupComponent;

class UCharacterSequenceCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Sequence");
	default CapabilityTags.Add(TimeControlCapabilityTags::TimeSequenceCapability);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 1;

	UPROPERTY()
	float ChargeDuration = 0.5f; 

	// After holding for this amount of time, the cloning is locked in and cannot be interrupted anymore
	UPROPERTY()
	float ChargeLockInAfter = 0.25f;

	UPROPERTY()
	UHazeLocomotionFeatureBase Feature;

	UPROPERTY()
	UHazeLocomotionFeatureBase Feature_Pickup;

	UTimeControlSequenceComponent SeqComp;
	UPlayerPickupComponent PickupComp;
	AMayTeleportWatch Watch;
	AHazePlayerCharacter Player;

	float FloatTimeRemaining = 0.f;
	float ChargeTimeRemaining = 0.f;
	bool bChargeComplete = false;
	bool bChargeLockedIn = false;
	bool bIsButtonStillHeld = false;
	bool bDisabledUntilLanding = false;

	float CameraShakeOffset = 0.1f;
	bool bCameraShook = false;

	bool bFeatureAddedPickup = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SeqComp = UTimeControlSequenceComponent::Get(Owner);
		PickupComp = UPlayerPickupComponent::Get(Owner);
		ensure(SeqComp != nullptr);
		Super::Setup(SetupParams);

		bFeatureAddedPickup = false;
		Player.AddLocomotionFeature(Feature);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveLocomotionFeature(Feature);
		Player.RemoveLocomotionFeature(Feature_Pickup);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!IsActioning(ActionNames::SecondaryLevelAbility))
        	return EHazeNetworkActivation::DontActivate;

		// Don't activate again until the button is released and pressed again
        if (bIsButtonStillHeld)
        	return EHazeNetworkActivation::DontActivate;

		// Sometimes we can't leave new clones until we've landed
        if (bDisabledUntilLanding)
        	return EHazeNetworkActivation::DontActivate;

        if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!IsActioning(ActionNames::SecondaryLevelAbility) && !bChargeLockedIn)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

        if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// If the charge completes we should leave a clone
		if (bChargeComplete)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Stop leaving a clone if we receive an impulse from anything
        if (MoveComp.HasAccumulatedImpulse())
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		ChargeTimeRemaining = ChargeDuration;
		bChargeComplete = false;
		bIsButtonStillHeld = true;
		bCameraShook = false;
		bChargeLockedIn = false;

		SeqComp.bStartedChargingClone = true;
		SeqComp.bCloneWasAirborne = MoveComp.IsAirborne();

		Player.PlayForceFeedback(SeqComp.LeaveCloneForceFeedback, false, false, n"LeaveClone");	
		Player.SetCapabilityActionState(n"AudioStartedChargingClone", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& Params)
	{
		if (bChargeComplete)
			Params.AddActionState(n"LeaveClone");
	}

	void ModifyCloneRotationForVolumes(FRotator& CloneRotation)
	{
		TArray<AActor> Overlaps;
		Player.GetOverlappingActors(Overlaps);

		for (AActor OverlapActor : Overlaps)
		{
			auto Volume = Cast<APlayerCloneAutoDirectionVolume>(OverlapActor);
			if (Volume == nullptr)
				continue;

			FRotator WantedDirection = Volume.AutoDirection.WorldRotation;
			FVector WantedForward = WantedDirection.ForwardVector;
			FVector CloneForward = CloneRotation.ForwardVector;

			float Distance = WantedForward.AngularDistance(CloneForward);
			if (Distance < FMath::DegreesToRadians(Volume.MaximumAngle))
			{
				CloneRotation = WantedDirection;
				return;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		SeqComp.bStartedChargingClone = false;

		Owner.StopAllSlotAnimations();

		if (Params.GetActionState(n"LeaveClone"))
		{
			FRotator CloneRotation = Params.ActorParams.Rotation;
			ModifyCloneRotationForVolumes(CloneRotation);

			SeqComp.ActiveClone(Params.ActorParams.Location, CloneRotation, Player);
			SeqComp.CallCloneOnEvent(ESequenceEventType::OnPlacedClone);
			Player.SetCapabilityActionState(n"AudioChargeWasCompleted", EHazeActionState::Active);	
		}
		else
		{
			Player.StopForceFeedback(SeqComp.LeaveCloneForceFeedback, n"LeaveClone");		
			Player.Mesh.ResetSubAnimationInstance();
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsGrounded())
		{
			FloatTimeRemaining = ChargeDuration;
			bDisabledUntilLanding = false;
		}

        if (!IsActioning(ActionNames::SecondaryLevelAbility))
			bIsButtonStillHeld = false;

        if (ConsumeAction(n"DisableLeaveCloneUntilLanding") == EActionStateStatus::Active)
			bDisabledUntilLanding = true;

		// Remove all clones when the player is dead
		if (SeqComp.IsCloneActive() && Player.IsPlayerDead())
			SeqComp.DeactiveClone(Player);

		// Update which feature is being used on pickup state
		if (bFeatureAddedPickup != PickupComp.IsHoldingObject())
		{
			bFeatureAddedPickup = PickupComp.IsHoldingObject();
			if (bFeatureAddedPickup)
			{
				Player.RemoveLocomotionFeature(Feature);
				Player.AddLocomotionFeature(Feature_Pickup);
			}
			else
			{
				Player.RemoveLocomotionFeature(Feature_Pickup);
				Player.AddLocomotionFeature(Feature);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CharacterSequenceCapability");

		ChargeTimeRemaining -= DeltaTime;

		if (ChargeTimeRemaining <= (ChargeDuration - ChargeLockInAfter))
		{
			bChargeLockedIn = true;
		}

		if (ChargeTimeRemaining <= 0.f)
		{
			bChargeComplete = true;
		}


		if (!bCameraShook && ChargeTimeRemaining <= (0.f + CameraShakeOffset))
		{
			bCameraShook = true;
			Player.PlayCameraShake(SeqComp.LeaveCloneCameraShake);
		}

		if (HasControl())
		{
			if (MoveComp.IsGrounded())
			{
				// Don't apply any movement while charging on the ground
			}
			else
			{
				// Only apply gravity once we run out of the amount of time we can float
				if (FloatTimeRemaining >= 0.f)
				{
					FloatTimeRemaining -= DeltaTime;
				}
				else
				{
					FrameMove.ApplyGravityAcceleration();
					FrameMove.ApplyActorVerticalVelocity();
				}
			}
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		Owner.SetAnimFloatParam(n"CloneChargePct", FMath::Clamp(1.f - ChargeTimeRemaining/ChargeDuration, 0.f, 1.f));
		MoveCharacter(FrameMove, n"DigitalWatch", n"Cloning");
	}
}
