import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingActivationPointComponent;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Grinding.UserGrindGrappleComponent;

const float DASH_TO_SPEED = 2900.f;
const float DASH_TO_LAND_TIME = 0.01f;
const float DASH_ANIMATE_MIN_DISTANCE = 200.f;

class UCharacterJumpToGrindEnterGrindingCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::PotentialGrinds);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Enter);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UUserGrindGrappleComponent GrappleComp;
	UGrindingActivationComponent ActivationPoint;

	FTransform StartTransform;

	FGrindSplineData JumpToGrindData;

	float VerticalVelocity = 0.f;
	FVector HorizontalVelocity = FVector::ZeroVector;
	FQuat DirectionToTarget = FQuat::Identity;

	float Duration = 0.f;
	float TravelDestinationAngleDifference = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		GrappleComp = UUserGrindGrappleComponent::GetOrCreate(Owner);
		ActivationPoint = UGrindingActivationComponent::GetOrCreate(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.HasTargetGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

        if (!GrappleComp.FrameEvaluatedGrappleTarget.IsValid())
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration >= Duration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (!UserGrindComp.HasTargetGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddStruct(n"TargetSpline", GrappleComp.FrameEvaluatedGrappleTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(MovementSystemTags::Swinging, this);

		StartTransform = Owner.ActorTransform;

		Player.SetCapabilityActionState(GrindingActivationEvents::Grappling, EHazeActionState::Active);

		ActivationParams.GetStruct(n"TargetSpline", JumpToGrindData);
		UserGrindComp.UpdateTargetGrindSpline(JumpToGrindData);

		for (FName CapabilityTag : JumpToGrindData.GrindSpline.CapabilityBlocks)
		{
			Player.BlockCapabilities(CapabilityTag, this);
		}

		CalculateDashTrajectory();
		//const FVector TargetLocation = JumpToGrindData.SystemPosition.WorldLocation;
		//const FVector HorizontalToSpline = (JumpToGrindData.SystemPosition.WorldLocation - MoveComp.OwnerLocation).ConstrainToPlane(MoveComp.WorldUp);
		//const FVector DirectionToSpline = HorizontalToSpline.SafeNormal;
		//const float HoriSpeed = FMath::Max(MoveComp.MoveSpeed * 2.f, MoveComp.HorizontalVelocity);
		//Duration = HorizontalToSpline.Size() / HoriSpeed;
		//HorizontalVelocity = DirectionToSpline * HoriSpeed;
		//VerticalVelocity = CalculateVelocityForPathWithHorizontalSpeed(MoveComp.OwnerLocation, TargetLocation, MoveComp.GravityMagnitude, HoriSpeed, MoveComp.WorldUp).Size();
	}

	void CalculateDashTrajectory()
	{
		FTransform Target = JumpToGrindData.SystemPosition.WorldTransform;
		FVector TargetLocation = Target.Location;
		FVector OwnerLocation = Owner.ActorLocation;

		FVector Delta = TargetLocation - OwnerLocation;
		FVector HorizDelta = Delta;
		HorizDelta.Z = 0.f;

		float Distance = Delta.Size();
		if (HorizDelta.Size() < DASH_ANIMATE_MIN_DISTANCE)
		{
			Duration = 0.f;
		}
		else
		{
			float TravelTime = Distance / DASH_TO_SPEED;
			Duration = TravelTime + DASH_TO_LAND_TIME;
		}

		if (HorizDelta.IsNearlyZero())
			DirectionToTarget = Target.Rotation;
		else
			DirectionToTarget = Math::MakeQuatFromXZ(HorizDelta, MoveComp.WorldUp);

		VerticalVelocity = 0.f;
		TravelDestinationAngleDifference = FMath::FindDeltaAngleDegrees(DirectionToTarget.Rotator().Yaw, Target.Rotator().Yaw);
	}

	void PerformDashMove(FHazeFrameMovement& Move, float DeltaTime)
	{
		FVector WantedPosition = FMath::VInterpConstantTo(Owner.ActorLocation, JumpToGrindData.SystemPosition.WorldLocation, DeltaTime, DASH_TO_SPEED);
		Move.ApplyDelta(WantedPosition - Owner.ActorLocation);

		const float TargetTime = Duration - DASH_TO_LAND_TIME;
		if (ActiveDuration >= TargetTime)
		{
			MoveComp.SetTargetFacingRotation(JumpToGrindData.SystemPosition.WorldOrientation, PI * 3.f);
			Move.ApplyTargetRotationDelta();
		}
		else
		{
			Move.SetRotation(DirectionToTarget);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		Owner.UnblockCapabilities(MovementSystemTags::Swinging, this);
		for (FName CapabilityTag : JumpToGrindData.GrindSpline.CapabilityBlocks)
		{
			Player.UnblockCapabilities(CapabilityTag, this);
		}

		ConsumeAction(GrindingActivationEvents::Grappling);

		UserGrindComp.StartGrinding(JumpToGrindData.GrindSpline, EGrindAttachReason::Grapple, FVector::ZeroVector);
		UserGrindComp.CurrentSpeed = FMath::Max(UserGrindComp.ActiveGrindSplineData.SystemPosition.WorldForwardVector.DotProduct(MoveComp.Velocity), UserGrindComp.DesiredSpeed);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			// Move Character.
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"GrindingGrapple");

			UpdateDashAnimParams();
			if (HasControl())
				CalculateControlSideMove(FrameMove, DeltaTime);
			else
				CalculateRemoteSideMove(FrameMove, DeltaTime);

			MoveCharacter(FrameMove, n"DashTo");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}

	void UpdateDashAnimParams()
	{
		float TravelTime = Duration - DASH_TO_LAND_TIME;
		Owner.SetAnimFloatParam(n"DashToPredictedTravelTime", TravelTime);
		Owner.SetAnimFloatParam(n"DashToRemainingDistance", UserGrindComp.TargetGrindSplineData.SystemPosition.WorldLocation.Distance(Owner.ActorLocation));
		Owner.SetAnimFloatParam(n"DashToAngleDelta", TravelDestinationAngleDifference);
		Owner.SetAnimBoolParam(n"DashToLanded", ActiveDuration >= TravelTime);
	}

	void CalculateControlSideMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FrameMove.OverrideStepDownHeight(0.f);
		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideCollisionSolver(n"NoCollisionSolver");

		PerformDashMove(FrameMove, DeltaTime);
		//FVector HorizontalDelta = HorizontalVelocity * DeltaTime;
		//FrameMove.ApplyDelta(HorizontalDelta);

		//// Integrate gravity
		//float GravityMag = MoveComp.GravityMagnitude;
		//float VerticalMove = VerticalVelocity * DeltaTime - GravityMag * DeltaTime * DeltaTime * 0.5f;

		//VerticalVelocity -= GravityMag * DeltaTime;
		//FrameMove.ApplyDelta(MoveComp.WorldUp * VerticalMove);

		////Rotation (just lerp to target)
		//FQuat Rotation = FQuat::Slerp(StartTransform.Rotation, JumpToGrindData.SystemPosition.WorldRotation.Quaternion(), ActiveDuration / Duration);
		//FrameMove.SetRotation(Rotation);
	}

	void CalculateRemoteSideMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		FrameMove.ApplyConsumedCrumbData(ConsumedParams);
	}	
}
