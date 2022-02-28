import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;

class UCharacterDashWallSlideEnterCapability : UCharacterMovementCapability
{
	default RespondToEvent(WallslideActivationEvents::Wallsliding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(WallSlideTags::WallSliding);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 49;

	UCharacterWallSlideComponent WallDataComp = nullptr;

	FHazeAcceleratedVector RelativeDeltaAccelerator;
	UPrimitiveComponent TargetPrimitive;

	float DashWallSlideEnterTime = 0.3f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Super::Setup(Params);

		WallDataComp = UCharacterWallSlideComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!WallDataComp.ShouldDashSlide())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		FVector TargetLocation = WallDataComp.TargetWallHit.ActorLocation;
		FVector WallNormal = WallDataComp.TargetWallHit.Normal;

		if (WallDataComp.PrimitiveWeWantToSlideOn.IsNetworked())		
		{
			OutParams.AddObject(WallSlideSyncing::Primitive, WallDataComp.PrimitiveWeWantToSlideOn);

			FTransform PlatformTransform = WallDataComp.PrimitiveWeWantToSlideOn.WorldTransform;
			TargetLocation = PlatformTransform.InverseTransformPosition(TargetLocation);
			WallNormal = PlatformTransform.Rotation.Inverse().RotateVector(WallNormal);
		}

		OutParams.AddVector(WallSlideSyncing::WallNormal, WallNormal);
		OutParams.AddVector(WallSlideSyncing::Location, TargetLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		FTransform ParentTransform = FTransform::Identity;
		TargetPrimitive = Cast<UPrimitiveComponent>(Params.GetObject(WallSlideSyncing::Primitive));
		if (TargetPrimitive != nullptr)
			ParentTransform = TargetPrimitive.WorldTransform;

		FVector WantedLocation = ParentTransform.TransformPosition(Params.GetVector(WallSlideSyncing::Location));
		RelativeDeltaAccelerator.Value = WantedLocation - MoveComp.OwnerLocation;
		RelativeDeltaAccelerator.Velocity = FVector::ZeroVector;

		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		FVector WallNormal = ParentTransform.Rotation.RotateVector(Params.GetVector(WallSlideSyncing::WallNormal));
		MoveComp.SetTargetFacingDirection(-WallNormal, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.ForwardHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (RelativeDeltaAccelerator.Value.IsNearlyZero())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);

		if (MoveComp.CanCalculateMovement() && !IsBlocked())
		{
			if (HasControl())
				WallDataComp.WallSlideEnterDone();
		}
		else
		{
			WallDataComp.InvalidatePendingSlide();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement EnterMove = MoveComp.MakeFrameMovement(n"WallSlideDashEnter");

		FVector PreviousRemainder = RelativeDeltaAccelerator.Value;
		RelativeDeltaAccelerator.AccelerateTo(FVector::ZeroVector, DashWallSlideEnterTime, DeltaTime);
		FVector DeltaToWall = PreviousRemainder - RelativeDeltaAccelerator.Value;
		EnterMove.ApplyDelta(DeltaToWall);
		EnterMove.ApplyTargetRotationDelta();
		if (TargetPrimitive != nullptr)
			EnterMove.SetMoveWithComponent(TargetPrimitive);

		MoveCharacter(EnterMove, FeatureName::DashIntoWallMovement);
	}
}
