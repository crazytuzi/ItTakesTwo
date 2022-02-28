import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeAnimNotifies;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UTrapezeUnmountCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::Unmount);

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PickupComponent;
	UTrapezeComponent TrapezeInteractionComponent;

	ATrapezeActor TrapezeActor;

	bool bReleaseAnimationDone;
	bool bPlayerIsOnSwing;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
		TrapezeInteractionComponent = UTrapezeComponent::Get(Owner);

		TrapezeActor = Cast<ATrapezeActor>(TrapezeInteractionComponent.GetTrapezeActor());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TrapezeInteractionComponent.PlayerWantsOut())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPlayerIsOnSwing = true;

		// Play exit animation
		PlayerOwner.PlaySlotAnimation(OnBlendingOut = FHazeAnimationDelegate(this, n"OnReleaseAnimationDone"), Animation = TrapezeActor.GetExitSequence(PlayerOwner));
		PlayerOwner.BindOneShotAnimNotifyDelegate(UAnimNotify_TrapezeUnmount::StaticClass(), FHazeAnimNotifyDelegate(this, n"OnPlayerReleasedSwing"));

		// Start resetting rotation offset
		PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bPlayerIsOnSwing)
		{
			// Glue player character to trapeze as long as it's still on the swing
			PlayerOwner.SetActorLocation(TrapezeActor.SwingMesh.GetWorldLocation());
		}
		else
		{
			// Gimme some of that sweet air movement
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"TrapezeUnmount");
			MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

			if(HasControl())
			{
				FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

				MoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, Input, MoveComp.HorizontalAirSpeed));
				MoveData.ApplyAndConsumeImpulses();
				MoveData.ApplyActorVerticalVelocity();
				MoveData.ApplyGravityAcceleration();
				MoveData.ApplyTargetRotationDelta();
				MoveData.FlagToMoveWithDownImpact();

				MoveComp.Move(MoveData);
				CrumbComp.LeaveMovementCrumb();
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				MoveData.ApplyConsumedCrumbData(ConsumedParams);
				MoveComp.Move(MoveData);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return bReleaseAnimationDone ?
			EHazeNetworkDeactivation::DeactivateLocal :
			EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bReleaseAnimationDone = false;
		bPlayerIsOnSwing = false;

		// Push normal pickup locomotion asset when getting off (giggity)
		if(PickupComponent.CurrentPickup != nullptr)
			PlayerOwner.AddLocomotionAsset(PickupComponent.CurrentPickupDataAsset.CarryLocomotion, PickupComponent);

		// Start synching movement normally
		// Eman TODO: Restart synching once player reaches floor, or maybe activate using crumb somehow?
		if(Network::IsNetworked())
			PlayerOwner.UnblockMovementSyncronization(PlayerOwner);

		// End it all...
		TrapezeInteractionComponent.Finalize();
	}

	UFUNCTION()
	void OnPlayerReleasedSwing(AHazeActor PlayerActor, UHazeSkeletalMeshComponentBase PlayerMesh, UAnimNotify AnimNotify)
	{
		// Fire release event
        TrapezeActor.OnPlayerReleasedSwingEvent.Broadcast(PlayerOwner);
		bPlayerIsOnSwing = false;
	}

	UFUNCTION()
	void OnReleaseAnimationDone()
	{
		bReleaseAnimationDone = true;
	}
}