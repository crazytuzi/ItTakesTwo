import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Beetle.Movement.BeetleMovementDataComponent;
import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;

class UBeetleLeapMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Leaping");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	UBeetleBehaviourComponent BehaviourComp = nullptr;
    UBeetleMovementDataComponent MoveDataComp = nullptr;
	UCapsuleComponent CollisionComp = nullptr;

    FHazeAcceleratedRotator Rotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		BehaviourComp = UBeetleBehaviourComponent::Get(Owner);
        MoveDataComp = UBeetleMovementDataComponent::Get(Owner);
		CollisionComp = UCapsuleComponent::Get(Owner);
		ensure((CollisionComp != nullptr) && (MoveDataComp != nullptr) && (BehaviourComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.State == EBeetleState::None)
    		return EHazeNetworkActivation::DontActivate;
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		if (MoveDataComp.MoveType != EBeetleMovementType::Leap)
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.State == EBeetleState::None)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		if (MoveDataComp.MoveType != EBeetleMovementType::Leap)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Rotation.SnapTo(Owner.GetActorRotation());

		// Prepare leap so we'll reach destination
		MoveComp.SetVelocity(GetLaunchVelocity(MoveDataComp.Destination, MoveDataComp.Speed));
		BehaviourComp.LogEvent("Activating leap movement.");
    }

	FVector GetLaunchVelocity(const FVector& TargetLoc, float DefaultSpeed)
	{
		FVector OwnLoc = Owner.GetActorLocation();
		FVector ToTarget = (TargetLoc - OwnLoc);
		float Speed = DefaultSpeed;
		if (MoveComp.GravityMagnitude == 0.f)
			return ToTarget.GetSafeNormal() * Speed;

		FVector WorldUp = MoveComp.WorldUp;
		float VDist = ToTarget.DotProduct(WorldUp);
		FVector ToTargetHorizontal = ToTarget - WorldUp * VDist;
		float HDist = ToTargetHorizontal.Size();
		float Gravity = MoveComp.GravityMagnitude;
		float SpeedSqr = FMath::Square(Speed);
		float SpeedQuad = FMath::Square(SpeedSqr);

		// Calculate aim height needed to hit target 
		float LaunchElevation;
		float Discriminant = SpeedQuad - Gravity * ((Gravity * FMath::Square(HDist)) + (2.f * VDist * SpeedSqr));
		if (Discriminant < 0.f)
		{
			// Can't reach target, increase velocity appropriately
			SpeedSqr = Gravity * (VDist + FMath::Sqrt(FMath::Square(VDist) + FMath::Square(HDist)));				
			Speed = FMath::Sqrt(SpeedSqr);
			LaunchElevation = SpeedSqr / Gravity;
		}
		else
		{
			// `SpeedSqr +` for high parabola
			LaunchElevation = (SpeedSqr - FMath::Sqrt(Discriminant)) / Gravity;
		}
	
		FVector LaunchDir = (ToTargetHorizontal + WorldUp * LaunchElevation).GetSafeNormal();
		return LaunchDir * Speed;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement Move = MoveComp.MakeFrameMovement(n"BeetleLeap");
		if (HasControl())
		{
			Rotation.Value = Owner.ActorRotation; // In case this is changed by outside system
			Rotation.AccelerateTo((MoveDataComp.Destination - Owner.ActorLocation).Rotation(), 3.f, DeltaTime); 
			MoveComp.SetTargetFacingRotation(Rotation.Value); 
			Move.OverrideStepUpHeight(100.f);
			Move.OverrideStepDownHeight(0.f);
			Move.ApplyActorHorizontalVelocity();
			Move.ApplyActorVerticalVelocity();
			Move.ApplyGravityAcceleration();
		}
		else
		{
			// Remote, follow crumbs
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Move.ApplyConsumedCrumbData(ConsumedParams);
		}
		MoveCharacter(Move, n"LeapTo");
		CrumbComp.LeaveMovementCrumb();

        // Consume destination and leap type
        MoveDataComp.bHasDestination = false;
		MoveDataComp.MoveType = EBeetleMovementType::Walk;
	}
};
