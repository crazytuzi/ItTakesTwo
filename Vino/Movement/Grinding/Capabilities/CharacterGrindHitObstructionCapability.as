import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.GrindingNetworkNames;

class UCharacterGrindHitObstructionCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);
	default RespondToEvent(GrindingActivationEvents::TargetGrind);

	default CapabilityTags.Add(GrindingCapabilityTags::Obsctruction);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 50;

	UUserGrindComponent UserGrindComp;
	FVector FlingDirection = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		UserGrindComp = UUserGrindComponent::Get(Owner);
		ensure(UserGrindComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline() && !UserGrindComp.HasTargetGrindSpline())
			return EHazeNetworkActivation::DontActivate;

		// Depending on the grind angle, downhits could be taken as forward hits.
		// "Down hit" should be a combination of the velocity, and the impact normal
		TArray<FVector> HitNormals;

		// Add all normals if they are blocking hits
		if (MoveComp.DownHit.bBlockingHit)
			HitNormals.Add(MoveComp.DownHit.ImpactNormal);
		if (MoveComp.ForwardHit.bBlockingHit)
			HitNormals.Add(MoveComp.ForwardHit.ImpactNormal);
		if (MoveComp.UpHit.bBlockingHit)
			HitNormals.Add(MoveComp.UpHit.ImpactNormal);

		for (FVector Normal : HitNormals)
		{
			FVector Right = MoveComp.WorldUp.CrossProduct(MoveComp.Velocity).GetSafeNormal();
			FVector Up = MoveComp.Velocity.CrossProduct(Right).GetSafeNormal();

			float Angle = Normal.AngularDistance(Up);
			Angle *= RAD_TO_DEG;

			// If any hit is above 45 degrees from straight down, it is an obstruction
			if (Angle > 45.f)
				return EHazeNetworkActivation::ActivateUsingCrumb;
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= 0.5f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FHitResult ObstructionHit = MoveComp.ForwardHit;
		if (!ObstructionHit.bBlockingHit)
		{
			ObstructionHit = MoveComp.UpHit;
			if (!ObstructionHit.bBlockingHit)
				ObstructionHit = MoveComp.DownHit;
		}

		ensure(ObstructionHit.bBlockingHit);	
		

		FVector FlattenedObstruction = ObstructionHit.Normal.ConstrainToPlane(UserGrindComp.SplinePosition.WorldUpVector);
		FlattenedObstruction.Normalize();

		float ObstructionDot = FMath::Abs(FlattenedObstruction.DotProduct(UserGrindComp.SplinePosition.WorldForwardVector));
		float ObstructionAngle = Math::DotToDegrees(ObstructionDot);

		if (ObstructionAngle < GrindSettings::Obstruction.MinAngle)
		{
			FVector Axis = FlattenedObstruction.CrossProduct(UserGrindComp.SplinePosition.WorldRightVector);
			if (FlattenedObstruction.DotProduct(UserGrindComp.SplinePosition.WorldRightVector) < 0.f)
				Axis *= -1;
			float Angle = GrindSettings::Obstruction.MinAngle - ObstructionAngle;
			FQuat RotationQuat = FQuat(Axis, Angle * DEG_TO_RAD);

			FlattenedObstruction = RotationQuat * FlattenedObstruction;
		}

		ActivationParams.AddVector(GrindingNetworkNames::ObstructionNormal, FlattenedObstruction);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(GrindingCapabilityTags::Evaluate, this);

		float FlingSpeed = (UserGrindComp.HasActiveGrindSpline() ? FMath::Min(GrindSettings::Obstruction.MaxAddedForce, UserGrindComp.CurrentSpeed) : GrindSettings::Obstruction.GrapplingeForce) + GrindSettings::Obstruction.MinForce;

		FlingDirection = ActivationParams.GetVector(GrindingNetworkNames::ObstructionNormal);
		MoveComp.Velocity = FlingDirection * FlingSpeed;
		MoveComp.Velocity += MoveComp.WorldUp * GrindSettings::Obstruction.UpwardsForce;

		if (UserGrindComp.HasActiveGrindSpline())
			UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Obstructed);

		UserGrindComp.ResetTargetGrindSpline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams ActivationParams)
	{
		Owner.UnblockCapabilities(GrindingCapabilityTags::Evaluate, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement Move = MoveComp.MakeFrameMovement(GrindingCapabilityTags::Obsctruction);
		if (HasControl())
			CalculateControlMove(Move);
		else
			CalculateRemoteMove(Move, DeltaTime);
		
		MoveCharacter(Move, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();
	}

	void CalculateControlMove(FHazeFrameMovement& ControlMove)
	{
		ControlMove.OverrideStepDownHeight(0.f);
		ControlMove.OverrideStepUpHeight(0.f);
		ControlMove.ApplyAndConsumeImpulses();
		ControlMove.ApplyActorVerticalVelocity();
		ControlMove.ApplyActorHorizontalVelocity();
		ControlMove.ApplyGravityAcceleration();
	}

	void CalculateRemoteMove(FHazeFrameMovement& RemoteMove, float DeltaTime)
	{
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		RemoteMove.ApplyConsumedCrumbData(ConsumedParams);
	}
}
