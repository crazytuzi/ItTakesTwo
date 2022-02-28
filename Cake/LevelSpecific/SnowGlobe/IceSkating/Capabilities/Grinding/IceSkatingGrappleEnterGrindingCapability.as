import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.UserGrindGrappleComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Grinding.GrindingActivationPointComponent;
import Vino.Movement.Grinding.GrindingReasons;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Camera.Components.CameraUserComponent;

class UIceSkatingGrappleCableComponent : UHazeCableComponent
{
	default bAutoActivate = true;
	default EndLocation = FVector::ZeroVector;
	default CableLength = 1000.f;
	default SolverIterations = 4;
	default NumSegments = 20;
	default NumSides = 5;
	default bEnableStiffness = true;
	default CableWidth = 6.f;
	default TileMaterial = 32;
	default SubstepTime = 0.001f;

	float DestroyTimer = 3.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DestroyTimer -= DeltaTime;
		if (DestroyTimer <= 2.6f)
		{
			bAttachEnd = false;
		}
		if (DestroyTimer <= 0.f)
		{
			DestroyComponent(this);
		}
	}
}

class UIceSkatingGrappleEnterGrindingCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Grapple);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Enter);
	default CapabilityTags.Add(GrindingCapabilityTags::Grapple);

	default CapabilityDebugCategory = n"IceSkating";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 99;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UUserGrindGrappleComponent GrappleComp;
	UIceSkatingComponent SkateComp;
	UCameraUserComponent CameraUser;

	FVector GrappleVelocity;
	FGrindSplineData GrapplePoint;
	FIceSkatingGrindSettings GrindSettings;

	FVector JumpVelocity;
	float JumpTimer;
	float ForwardSpeed;

	// Is used when something extraordinary happens (ran out of railing, railing underground etc.)
	// and we need to just exit.
	bool ForceExit = false;

	AHazeActor CableActor;
	UHazeCableComponent CableComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		GrappleComp = UUserGrindGrappleComponent::GetOrCreate(Owner);
		SkateComp = UIceSkatingComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
        	return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
        	return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsFast)
        	return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.HasTargetGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

        if (!GrappleComp.FrameEvaluatedGrappleTarget.IsValid())
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::SwingAttach))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateLocal;

       	if (ForceExit)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (!SkateComp.bIsIceSkating)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (JumpTimer <= 0.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (!UserGrindComp.HasTargetGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.BecameGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FGrindSplineData SplineData = GrappleComp.FrameEvaluatedGrappleTarget;

		UHazeSplineComponentBase SplineComp;
		float Distance = 0.f;
		bool bForward = true;
		SplineData.SystemPosition.BreakData(SplineComp, Distance, bForward);
		
		AGrindspline TargetGrindSpline = SplineData.GrindSpline;
		ActivationParams.AddObject(n"TargetGrindSpline", SplineData.GrindSpline);
		ActivationParams.AddObject(n"TargetSplineComp", SplineComp);
		ActivationParams.AddValue(n"TargetSplineDistance", Distance);
		if (bForward)
			ActivationParams.AddActionState(n"TargetSplineForward");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		AGrindspline GrindSpline = Cast<AGrindspline>(Params.GetObject(n"TargetGrindSpline"));
		UHazeSplineComponentBase SplineComp = Cast<UHazeSplineComponentBase>(Params.GetObject(n"TargetSplineComp"));
		float Distance = Params.GetValue(n"TargetSplineDistance");
		bool bForward = Params.GetActionState(n"TargetSplineForward");

		GrapplePoint = FGrindSplineData(GrindSpline, SplineComp, Distance, bForward);

		FVector TargetLocation = GrapplePoint.SystemPosition.WorldLocation;
		FVector TargetDelta = TargetLocation - Player.ActorLocation;
		float HeightDelta = TargetDelta.DotProduct(MoveComp.WorldUp);

		UserGrindComp.UpdateTargetGrindSpline(GrapplePoint);

		ForwardSpeed = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).Size();
		JumpVelocity = CalculateVelocityForPathWithHeight(Player.ActorLocation, TargetLocation, GrindSettings.GrappleGravity, FMath::Max(HeightDelta, 0.f) + GrindSettings.GrappleExtraHeight, -1.f, MoveComp.WorldUp);
		TrajectoryTimeToReachHeight(JumpVelocity.DotProduct(MoveComp.WorldUp), GrindSettings.GrappleGravity, HeightDelta, JumpTimer);

		/* Attach effects */
		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleAttachRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleAttachRumble, false, true, NAME_None);

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble, false, true, NAME_None);

		/* Cable boyo */
		// We want to attach the cable a little bit ahead of where we grapple
		FHazeSplineSystemPosition CableAttach = GrapplePoint.SystemPosition;
		CableAttach.Move(1400.f);

		// Create a grabble component on the spline
		auto PlayerCableComp = UHazeCableComponent::Get(Player);

		CableComp = UIceSkatingGrappleCableComponent::Create(GrapplePoint.GrindSpline);
		for(int i=0; i<CableComp.NumMaterials; ++i)
			CableComp.SetMaterial(i, PlayerCableComp.Materials[i]);

		CableComp.WorldLocation = CableAttach.WorldLocation;
		CableComp.SetAttachEndTo(Owner, n"Mesh", n"RightHand");

		// Align all the cable particles in a line towards the player, and make then "whip" upwards with up-velocity
		FVector ParticleDelta = (Owner.ActorLocation - CableComp.WorldLocation) / CableComp.NumSegments;
		for(int i=0; i<CableComp.NumSegments; ++i)
		{
			CableComp.SetParticlePosition(i, CableComp.WorldLocation + ParticleDelta * i);
			CableComp.SetParticleVelocity(i, MoveComp.WorldUp * 1900.f);
		}

		// Camera does very weird things with lazy chase, so block for now
		Player.BlockCapabilities(GrindingCapabilityTags::Camera, this);

		ForceExit = false;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& Params)
	{
		if (JumpTimer <= 0.f)
			Params.AddActionState(n"ShouldStartGrinding");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{	
		if (Params.GetActionState(n"ShouldStartGrinding"))
		{
			// Jump was successful
			float HorizontalSpeed = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).Size();

			UserGrindComp.StartGrinding(GrapplePoint.GrindSpline, EGrindAttachReason::Grapple, FVector::ZeroVector);
			UserGrindComp.CurrentSpeed = ForwardSpeed;
			UserGrindComp.DesiredSpeed = ForwardSpeed;

			/* Land Effects */
			if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleLandRumble != nullptr)
				Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleLandRumble, false, true, NAME_None);

			if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble != nullptr)
				Player.StopForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble, NAME_None);
		}
		else
		{
			// If the capability was aborted for some other reason (before we reached the target point), just reset and get out
			UserGrindComp.ResetTargetGrindSpline();
		}
		Player.UnblockCapabilities(GrindingCapabilityTags::Camera, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"IceSkatingGrindingGrapple");
		FrameMove.OverrideCollisionSolver(n"NoCollisionSolver");

		if (HasControl())
		{
			JumpTimer -= DeltaTime;

			FVector OldTargetLocation = GrapplePoint.SystemPosition.WorldLocation;
			bool MoveResult = GrapplePoint.SystemPosition.Move(ForwardSpeed * DeltaTime);

			FVector TargetLocation = GrapplePoint.SystemPosition.WorldLocation;
			FVector ToTarget = TargetLocation - Player.ActorLocation;

			FQuat TargetRotation = GrapplePoint.SystemPosition.WorldRotation.Quaternion();

			JumpVelocity += FVector::UpVector * -GrindSettings.GrappleGravity * DeltaTime;

			FVector DeltaMove;
			DeltaMove += JumpVelocity * DeltaTime;
			DeltaMove += TargetLocation - OldTargetLocation;

			if (ToTarget.SizeSquared() < DeltaMove.SizeSquared() || JumpTimer < 0.f)
			{
				JumpTimer = 0.f;
				FrameMove.ApplyDelta(ToTarget);
			}
			else
			{
				FrameMove.ApplyDelta(DeltaMove);
				FrameMove.OverrideStepDownHeight(0.f);
				FrameMove.OverrideStepUpHeight(0.f);
			}

			MoveCharacter(FrameMove, n"IceSkatingGrindGrapple");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"IceSkatingGrindGrapple");
		}
	}
}
