import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.GrindJumpToLocationRegionComponent;
import Vino.Movement.Grinding.GrindingNetworkNames;
import Vino.Movement.Grinding.GrindJumpToGrindSplineRegionComponent;

class UCharacterGrindJumpGrindSplineCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Enter);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UGrindJumpToGrindSplineRegionComponent ActivationRegion;

	FTransform StartTransform;
	bool bTargetReached = false;

	float JumpDuration = 0.f;

	float VerticalVelocity = 0.f;

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

		if (UserGrindComp.HasTargetGrindSpline())
			return;

		ActivationRegion = Cast<UGrindJumpToGrindSplineRegionComponent>(UserGrindComp.FollowComp.GetRegionTypeThatWasExitedLastUpdate(UGrindJumpToGrindSplineRegionComponent::StaticClass()));			
		if (ActivationRegion != nullptr)
		{
			if (!ActivationRegion.bForceJumpAtEnd)
				ActivationRegion = nullptr;
			else
				return;
		}	

		if (!WasActionStarted(ActionNames::MovementJump))
			return;

		ActivationRegion = Cast<UGrindJumpToGrindSplineRegionComponent>(UserGrindComp.FollowComp.GetActiveRegionType(UGrindJumpToGrindSplineRegionComponent::StaticClass()));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if  (!MoveComp.CanCalculateMovement())
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

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(Blueprintoverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Outparams)
	{
		Outparams.AddObject(GrindingNetworkNames::RegionJumpToGrindSpline, ActivationRegion);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		ActivationRegion = Cast<UGrindJumpToGrindSplineRegionComponent>(Params.GetObject(GrindingNetworkNames::RegionJumpToGrindSpline));

		bTargetReached = false;
		StartTransform = Owner.ActorTransform;		
		
		bool bIsForward = ActivationRegion.TravelDirectionWhenLanded == EGrindSplineTravelDirection::Forwards ? true : false;
		FGrindSplineData TargetGrindSplineData = FGrindSplineData(ActivationRegion.TargetSpline, ActivationRegion.TargetSpline.Spline, ActivationRegion.TargetDistance, bIsForward);
		UserGrindComp.UpdateTargetGrindSpline(TargetGrindSplineData);

		CalculateImpulse(JumpDuration, ActivationRegion.JumpHeight);

		UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Jump);
		SetMutuallyExclusive(MovementSystemTags::Grinding, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		bTargetReached = false;

		if (ActivationRegion.TargetSpline != nullptr)
			UserGrindComp.StartGrinding(ActivationRegion.TargetSpline, EGrindAttachReason::Transfer, FVector::ZeroVector);
		
		SetMutuallyExclusive(MovementSystemTags::Grinding, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement JumpToMove = MoveComp.MakeFrameMovement(n"CharacterGrindJumpTo");
		if (HasControl())
			ControlCalculateMove(JumpToMove, DeltaTime);
		else
			RemoteCalculateMove(JumpToMove, DeltaTime);

		//MoveCharacter(JumpToMove, n"CharacterGrindJumpTo");
		MoveCharacter(JumpToMove, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();

		bTargetReached = ActiveDuration >= JumpDuration;
	}

	void ControlCalculateMove(FHazeFrameMovement& ControlMove, float DeltaTime)
	{
		ControlMove.OverrideStepUpHeight(0.f);
		ControlMove.OverrideStepDownHeight(0.f);

		// For horizontal translation, we lerp from the jumps start location to the target, then snap (horizontally) to that lerped location
		FVector TargetLerpLocation = FMath::Lerp(StartTransform.Location, UserGrindComp.TargetPosition.WorldLocation, ActiveDuration / JumpDuration);
		FVector CurrentLocation = Owner.ActorLocation;
		FVector Difference = TargetLerpLocation - CurrentLocation;
		Difference = Difference.ConstrainToPlane(MoveComp.WorldUp);

		ControlMove.ApplyDelta(Difference);

		// Integrate gravity
		float GravityMag = MoveComp.GravityMagnitude;
		float VerticalMove = VerticalVelocity * DeltaTime - GravityMag * DeltaTime * DeltaTime * 0.5f;

		VerticalVelocity -= GravityMag * DeltaTime;
		ControlMove.ApplyDelta(MoveComp.WorldUp * VerticalMove);

		//Rotation (just lerp to target)
		FQuat Rotation = FQuat::Slerp(StartTransform.Rotation, UserGrindComp.TargetPosition.WorldOrientation, ActiveDuration / JumpDuration);
		ControlMove.SetRotation(Rotation);
	}

	void RemoteCalculateMove(FHazeFrameMovement& RemoteMove, float DeltaTime)
	{
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		RemoteMove.ApplyConsumedCrumbData(ConsumedParams);
	}

	void CalculateImpulse(float& OutDuration, float TargetHeight)
	{
		FVector TargetLoc = UserGrindComp.TargetPosition.WorldLocation;
		FVector Loc = Owner.GetActorLocation();

		float Gravity = MoveComp.GravityMagnitude;
		float VerticalDistance = (TargetLoc - Loc).DotProduct(MoveComp.WorldUp);
	
		FVector PlayerToEndPoint = ActivationRegion.GetEndPointLocation() - Owner.ActorLocation;
		float HeightDifference = MoveComp.WorldUp.DotProduct(PlayerToEndPoint);

		if (IsDebugActive())
		{
			System::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + PlayerToEndPoint, FLinearColor::Red, 10.f);
			System::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + (MoveComp.WorldUp * HeightDifference), FLinearColor::Blue, 10.f);
		}

		float WorkHeight = TargetHeight + HeightDifference;
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
