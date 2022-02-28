import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;

class UCharacterGrindingCancelGrindCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Jump);
	default CapabilityTags.Add(GrindingCapabilityTags::Cancel);
	default CapabilityTags.Add(GrindingCapabilityTags::GrindMoveAction);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 25;

	float JumpDuration = 0.4f;

	bool bUpsideDownActivation = false;

	UUserGrindComponent UserGrindComp;
	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Super::Setup(Params);

		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.ActiveGrindSpline.bCanCancel)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (bUpsideDownActivation)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration < JumpDuration)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		bUpsideDownActivation = MoveComp.WorldUp.DotProduct(UserGrindComp.SplinePosition.WorldUpVector) < 0.f;
		if (bUpsideDownActivation)
		{
			UserGrindComp.StartGrindSplineCooldown(UserGrindComp.ActiveGrindSplineData.GrindSpline);
			UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Cancel);
			SetMutuallyExclusive(MovementSystemTags::Grinding, true);
			return;
		}

		FVector InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector GrindRightVector = UserGrindComp.SplinePosition.WorldRightVector;

		FHazeSplineSystemPosition CancelDirectionTest = UserGrindComp.SplinePosition;
		CancelDirectionTest.Move(50.f);

		float CancelDirection = -FMath::Sign(GrindRightVector.DotProduct(CancelDirectionTest.WorldForwardVector));
		if (InputVector.Size() > 0.5f)
			CancelDirection = FMath::Sign(InputVector.SafeNormal.DotProduct(GrindRightVector));

		
		FVector VelocityFromGrind = UserGrindComp.SplinePosition.WorldForwardVector * UserGrindComp.CurrentSpeed;
		FVector JumpImpulse = MoveComp.WorldUp * 1250.f;
		FVector SideImpulse = GrindRightVector * 400.f * CancelDirection;
		MoveComp.Velocity = VelocityFromGrind + JumpImpulse + SideImpulse;

		UserGrindComp.StartGrindSplineCooldown(UserGrindComp.ActiveGrindSplineData.GrindSpline);
		UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Cancel);
		SetMutuallyExclusive(MovementSystemTags::Grinding, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(MovementSystemTags::Grinding, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bUpsideDownActivation)
			return;

 		FHazeFrameMovement GrindCancelMove = MoveComp.MakeFrameMovement(n"GrindCancel");
		if (HasControl())
			ControlSideMove(GrindCancelMove, DeltaTime);
		else
			RemoteSideMove(GrindCancelMove, DeltaTime);

		MoveCharacter(GrindCancelMove, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();
	}

	void ControlSideMove(FHazeFrameMovement& ControlMove, float DeltaTime)
	{
		ControlMove.ApplyActorHorizontalVelocity();
		ControlMove.ApplyActorVerticalVelocity();
		ControlMove.ApplyGravityAcceleration();
		ControlMove.ApplyTargetRotationDelta();
	}

	void RemoteSideMove(FHazeFrameMovement& RemoteMove, float DeltaTime)
	{
		FHazeActorReplicationFinalized CrumbData;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
		RemoteMove.ApplyConsumedCrumbData(CrumbData);
	}

}
