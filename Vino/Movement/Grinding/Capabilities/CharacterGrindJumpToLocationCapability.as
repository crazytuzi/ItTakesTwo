import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.GrindJumpToLocationRegionComponent;
import Vino.Movement.Grinding.GrindingNetworkNames;

class UCharacterGrindJumpToLocationCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Enter);
	default CapabilityTags.Add(GrindingCapabilityTags::Grapple);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UGrindJumpToLocationRegionComponent ActivationRegion;

	FTransform StartTransform;
	FTransform JumpToTarget;
	bool bTargetReached = false;

	float JumpDuration = 0.f;

	float VerticalVelocity = 0.f;
	
	FVector HorizontalVelocity = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		ensure(Player != nullptr);

		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		if (IsBlocked())
			return;

		if (IsActive())
			return;

		ActivationRegion = nullptr;
		if (!UserGrindComp.HasActiveGrindSpline())
			return;

		ActivationRegion = Cast<UGrindJumpToLocationRegionComponent>(UserGrindComp.FollowComp.GetRegionTypeThatWasExitedLastUpdate(UGrindJumpToLocationRegionComponent::StaticClass()));
		if (ActivationRegion != nullptr)		
			return;

		if (!WasActionStarted(ActionNames::MovementJump))
			return;

		ActivationRegion = Cast<UGrindJumpToLocationRegionComponent>(UserGrindComp.FollowComp.GetActiveRegionType(UGrindJumpToLocationRegionComponent::StaticClass()));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if  (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;

		if (ActivationRegion == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if  (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (bTargetReached)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActivationRegion == nullptr)
			return RemoteLocalControlCrumbDeactivation();

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(Blueprintoverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Outparams)
	{
		Outparams.AddObject(GrindingNetworkNames::RegionJumpToLocation, ActivationRegion);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		ActivationRegion = Cast<UGrindJumpToLocationRegionComponent>(Params.GetObject(GrindingNetworkNames::RegionJumpToLocation));

		// While resetting the game, ActivationRegion might've streamed out, so just skip here
		if (ActivationRegion != nullptr)
		{
			bTargetReached = false;
			JumpToTarget = ActivationRegion.WorldJumpToTransform;
			StartTransform = Owner.ActorTransform;

			if (ActivationRegion.VelocityType == EJumpToVelocityType::KeepCurrentVelocity)
				CalculateImpulseWithTargetHorizontalVelocity(JumpDuration);
			else
				CalculateImpulseWithTargetHeight(JumpDuration, ActivationRegion.JumpHeight);
		}

		UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Jump);
		SetMutuallyExclusive(MovementSystemTags::Grinding, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		JumpToTarget = FTransform::Identity;
		bTargetReached = false;

		SetMutuallyExclusive(MovementSystemTags::Grinding, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement JumpToMove = MoveComp.MakeFrameMovement(n"CharacterGrindJumpTo");

		// While resetting the game, ActivationRegion might've streamed out, so just skip here
		if (ActivationRegion != nullptr)
		{
			if (HasControl())
				ControlCalculateMove(JumpToMove, DeltaTime);
			else
				RemoteCalculateMove(JumpToMove, DeltaTime);
		}

		//MoveCharacter(JumpToMove, n"CharacterGrindJumpTo");
		MoveCharacter(JumpToMove, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();

		bTargetReached = ActiveDuration >= JumpDuration;
	}

	FVector ConstantHorizontalDelta(float DeltaTime) const
	{
		return HorizontalVelocity * DeltaTime;
	}

	FVector LinearHorizontalDelta() const
	{
		// For horizontal translation, we lerp from the jumps start location to the target, then snap (horizontally) to that lerped location
		FVector TargetLerpLocation = FMath::Lerp(StartTransform.Location, JumpToTarget.Location, ActiveDuration / JumpDuration);
		FVector CurrentLocation = Owner.ActorLocation;
		FVector Difference = TargetLerpLocation - CurrentLocation;
		Difference = Difference.ConstrainToPlane(MoveComp.WorldUp);

		return Difference;
	}

	void ControlCalculateMove(FHazeFrameMovement& ControlMove, float DeltaTime)
	{
		ControlMove.OverrideStepUpHeight(0.f);
		ControlMove.OverrideStepDownHeight(0.f);

		FVector HorizontalDelta;
		if (ActivationRegion.VelocityType == EJumpToVelocityType::SpecifyHeight)
			HorizontalDelta = LinearHorizontalDelta();
		else
			HorizontalDelta = ConstantHorizontalDelta(DeltaTime);

		ControlMove.ApplyDelta(HorizontalDelta);

		// Integrate gravity
		float GravityMag = MoveComp.GravityMagnitude;
		float VerticalMove = VerticalVelocity * DeltaTime - GravityMag * DeltaTime * DeltaTime * 0.5f;

		VerticalVelocity -= GravityMag * DeltaTime;
		ControlMove.ApplyDelta(MoveComp.WorldUp * VerticalMove);

		//Rotation (just lerp to target)
		FQuat Rotation = FQuat::Slerp(StartTransform.Rotation, JumpToTarget.Rotation, ActiveDuration / JumpDuration);
		ControlMove.SetRotation(Rotation);
	}

	void RemoteCalculateMove(FHazeFrameMovement& RemoteMove, float DeltaTime)
	{
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		RemoteMove.ApplyConsumedCrumbData(ConsumedParams);
	}

	void CalculateImpulseWithTargetHorizontalVelocity(float& OutDuration)
	{
		const FVector CurrentTangentVelocity = UserGrindComp.SplinePosition.WorldForwardVector * UserGrindComp.CurrentSpeed;
		HorizontalVelocity = CurrentTangentVelocity.ConstrainToPlane(MoveComp.WorldUp);
		VerticalVelocity = CalculateVelocityForPathWithHorizontalSpeed(MoveComp.OwnerLocation, JumpToTarget.Location, MoveComp.GravityMagnitude, HorizontalVelocity.Size(), MoveComp.WorldUp).Size();

		float HorizontalDistance = (JumpToTarget.Location - MoveComp.OwnerLocation).ConstrainToPlane(MoveComp.WorldUp).Size();
		OutDuration = HorizontalDistance / HorizontalVelocity.Size();
	}

	void CalculateImpulseWithTargetHeight(float& OutDuration, float TargetHeight)
	{
		FVector TargetLoc = JumpToTarget.Location;
		FVector Loc = Owner.GetActorLocation();

		float Gravity = MoveComp.GravityMagnitude;
		float VerticalDistance = (TargetLoc - Loc).DotProduct(MoveComp.WorldUp);

		float WorkHeight = TargetHeight;
		if (WorkHeight < VerticalDistance)
			WorkHeight = VerticalDistance + 0.1f;

		/*
		Calculate how long it will take to reach the target height, with given impulse

		Parabola:
		-G/2 * (X - V/G)^2 + V^2/2G = A

		(-2A / G) + (V / G)^2
		*/

		float Impulse = FMath::Sqrt(2.f * WorkHeight * Gravity);

		float ValueToSqrt = (-2.f * VerticalDistance) / Gravity +
			((Impulse / Gravity) * (Impulse / Gravity));

		// This shouldn't be possible, but just to safe up, make sure we dont error
		if (!ensure(ValueToSqrt >= 0.f))
			ValueToSqrt = 0.001f;

		// X = V / G + sqrt((-2A / G) + (V / G)^2)
		float FlyTime = Impulse / Gravity +
			FMath::Sqrt(ValueToSqrt);

		OutDuration = FlyTime;
		VerticalVelocity = Impulse;
	}
}
