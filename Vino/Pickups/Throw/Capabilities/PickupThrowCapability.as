import Vino.Movement.Components.MovementComponent;

import Vino.Pickups.Throw.PickupThrowComponent;
import Vino.Pickups.PlayerPickupComponent;
import Vino.Pickups.AnimNotifies.AnimNotify_ThrowPickupable;
import Vino.Pickups.Throw.MoveProjectileAlongCurveComponent;
import Vino.Pickups.PickupActor;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.MovementSystemTags;

class UPickupThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
    default CapabilityTags.Add(PickupTags::PickupThrowCapability);

    default TickGroup = ECapabilityTickGroups::GamePlay;

	default CapabilityDebugCategory = PickupTags::PickupSystem;

	UPROPERTY()
	UForceFeedbackEffect ThrowForceFeedback;

    UPlayerPickupComponent PickupComponent;
	UPickupThrowComponent ThrowComponent;
    UHazeMovementComponent MovementComponent;
    AHazePlayerCharacter PlayerOwner;

    APickupActor ThrownObject;

	FHazeAnimNotifyDelegate OnThrowPickupEvent;

	FVector AimTarget;
	float AimPeak;

	bool bAnimationEnded;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        PickupComponent = UPlayerPickupComponent::Get(Owner);
		ThrowComponent = UPickupThrowComponent::GetOrCreate(Owner);
        MovementComponent = UHazeMovementComponent::Get(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		// Action state is set by PickupAimCapability
		if(!IsActioning(n"ThrowPickup"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.AddVector(n"AimTarget", GetAttributeVector(n"AimTarget"));
		SyncParams.AddValue(n"AimTrajectoryPeak", GetAttributeValue(n"AimTrajectoryPeak"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		// Capabilities are removed when the object stops bouncing
		ThrownObject = Cast<APickupActor>(PickupComponent.CurrentPickup);
		ThrownObject.AddCapability(PickupTags::PickupablePostThrowCollisionEnabler);

		PlayThrowAnimation();

		AimTarget = ActivationParams.GetVector(n"AimTarget");
		AimPeak = ActivationParams.GetValue(n"AimTrajectoryPeak");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MovementComponent.SetTargetFacingDirection((AimTarget - PlayerOwner.ActorLocation).GetSafeNormal(), 1.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(HasControl() && bAnimationEnded)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		OnThrowPickupEvent.Clear();
		bAnimationEnded = false;
	}

  	void PlayThrowAnimation()
    {
        FHazeAnimationDelegate OnAnimationEnded;
        OnAnimationEnded.BindUFunction(this, n"OnAnimationEnded");
        OnThrowPickupEvent.BindUFunction(this, n"OnThrowPickup");

        FHazePlaySlotAnimationParams ThrowAnimationParams;
        ThrowAnimationParams.Animation = PickupComponent.CurrentPickupDataAsset.ThrowAnimation;
		ThrowAnimationParams.BlendTime = 0.1f;

        PlayerOwner.PlaySlotAnimation(FHazeAnimationDelegate(), OnAnimationEnded, ThrowAnimationParams);
        PlayerOwner.BindOrExecuteOneShotAnimNotifyDelegate(PickupComponent.CurrentPickupDataAsset.ThrowAnimation, UAnimNotify_ThrowPickupable::StaticClass(), OnThrowPickupEvent);
    }

	// Called when animation releases object
	UFUNCTION(NotBlueprintCallable)
	void OnThrowPickup(AHazeActor HazeActor, UHazeSkeletalMeshComponentBase SkeletalMeshComponent, UAnimNotify AnimNotify)
	{
		// Release object and throw!
		ThrowComponent.Throw(ThrownObject, ThrownObject.ActorLocation, AimTarget, AimPeak, ThrownObject.OnCollisionAfterThrowEvent);
		PickupComponent.ThrowRelease();

		// Back the feed of my force, bro!
		PlayerOwner.PlayForceFeedback(ThrowForceFeedback, false, false, n"PickupThrow");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnAnimationEnded()
	{
		bAnimationEnded = true;
	}

	 void BlockCapabilities()
    {
        PlayerOwner.BlockCapabilities(PickupTags::PutdownStarterCapability, this);
        PlayerOwner.BlockCapabilities(PickupTags::PickupCapability, this);

        PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
        PlayerOwner.BlockCapabilities(CapabilityTags::GameplayAction, this);

		PlayerOwner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::TurnAround, this);
    }

    void UnblockCapabilities()
    {
        PlayerOwner.UnblockCapabilities(PickupTags::PutdownStarterCapability, this);
        PlayerOwner.UnblockCapabilities(PickupTags::PickupCapability, this);

        PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
        PlayerOwner.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		PlayerOwner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::TurnAround, this);
    }
}