import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeAnimNotifies;

/* IMPORTANT! This animation previously lived in the Trapeze ABP but it had to be turned into
   slot animation since ABPs don't support root motion */
class UTrapezeMountCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::Mount);

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UTrapezeComponent TrapezeInteractionComponent;
	UHazeMovementComponent MovementComponent;

	ATrapezeActor TrapezeActor;

	bool bDoneMounting;
	bool bShouldRequestRootMotion;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeInteractionComponent = UTrapezeComponent::Get(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);

		TrapezeActor = Cast<ATrapezeActor>(TrapezeInteractionComponent.GetTrapezeActor());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MovementComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeInteractionComponent.TrapezeActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeInteractionComponent.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeInteractionComponent.PlayerWantsOut())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);

		// Play enter animation as slot animation
		FHazeAnimationDelegate MountAnimationDoneDelegate;
		MountAnimationDoneDelegate.BindUFunction(this, n"OnMountAnimationFinished");
		PlayerOwner.PlaySlotAnimation(FHazeAnimationDelegate(), MountAnimationDoneDelegate, TrapezeActor.GetEnterSequence(PlayerOwner));

		// Listen to notify
		PlayerOwner.BindOneShotAnimNotifyDelegate(UAnimNotify_TrapezeMount::StaticClass(), FHazeAnimNotifyDelegate(this, n"OnPlayerMountedTrapeze"));

		// Switch attach socket if player is holding marble
		if(TrapezeInteractionComponent.PlayerHasMarble())
		{
			TrapezeInteractionComponent.Marble.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld);
			TrapezeInteractionComponent.Marble.AttachToComponent(USkeletalMeshComponent::Get(PlayerOwner), TrapezeActor.CatchSocketName);
		}

		bShouldRequestRootMotion = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return bDoneMounting ? EHazeNetworkDeactivation::DeactivateLocal : EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		bDoneMounting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bShouldRequestRootMotion)
			return;

		FHazeLocomotionTransform LocomotionTransform;
		PlayerOwner.RequestRootMotion(DeltaTime, LocomotionTransform);

		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(n"TrapezeMount");
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveData.ApplyRootMotion(LocomotionTransform);

		MovementComponent.Move(MoveData);
	}

	UFUNCTION()
	void OnPlayerMountedTrapeze(AHazeActor PlayerActor, UHazeSkeletalMeshComponentBase PlayerSkeletalMesh, UAnimNotify AnimNotify)
	{
		TrapezeActor.OnPlayerMountedSwingEvent.Broadcast(PlayerOwner);
		bShouldRequestRootMotion = false;
	}

	UFUNCTION()
	void OnMountAnimationFinished()
	{
		bDoneMounting = true;
	}
}
