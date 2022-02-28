import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.UserGrindGrappleComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Grinding.GrindingActivationPointComponent;
import Vino.Movement.Grinding.GrindingReasons;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Vino.Movement.Swinging.SwingComponent;

class UCharacterGrappleEnterGrindingCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::PotentialGrinds);
	default RespondToEvent(GrindingActivationEvents::GrappledForced);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Enter);
	default CapabilityTags.Add(GrindingCapabilityTags::Grapple);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UUserGrindGrappleComponent GrappleComp;
	UHazeCableComponent GrappleCableComp;
	UPlayerMovementAudioComponent AudioMoveComp;
	UPlayerHazeAkComponent PlayerHazeAkComp;

	UPrimitiveComponent StartFloor;
	
	USwingingComponent SwingingComponent;

	TArray<AActor> TargetSplineSystemActors;
	bool bReachedTarget = false;
	FVector EnteredVelocity;

	//FGrindSplineData GrappleGrindSplineData;
	bool bForceGrapple = false;
	float GrappleSpeed = 0.f;

	FVector GrappleLocation;
	FVector GrappleTangent;

	float CurrentSpeed;
	TArray<FName> ActiveBlocks;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		GrappleComp = UUserGrindGrappleComponent::GetOrCreate(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);
		PlayerHazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		GrappleCableComp = UHazeCableComponent::Get(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
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

		if (bReachedTarget)
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
		if (SwingingComponent.SwingRope.RopeIsActive())
			SwingingComponent.SwingRope.DetachFromSwingPoint();

		Owner.BlockCapabilities(MovementSystemTags::Swinging, this);
		Owner.BlockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);	

		EnteredVelocity = MoveComp.Velocity;

		bForceGrapple = false;		
		bReachedTarget = false;
		GrappleSpeed = GrindSettings::Grapple.InitialSpeed;

		StartFloor = nullptr;
		if (MoveComp.DownHit.bBlockingHit)
		{
			StartFloor = MoveComp.DownHit.Component;
			MoveComp.StartIgnoringComponent(StartFloor);
		}

		Player.SetCapabilityActionState(GrindingActivationEvents::Grappling, EHazeActionState::Active);

		// Get target spline from grapple comp
		FGrindSplineData GrappleGrindSplineData;
		if (HasControl())
			GrappleGrindSplineData = GrappleComp.FrameEvaluatedGrappleTarget;
		else
			ActivationParams.GetStruct(n"TargetSpline", GrappleGrindSplineData);
		UserGrindComp.UpdateTargetGrindSpline(GrappleGrindSplineData);

		ActiveBlocks = UserGrindComp.TargetGrindSplineData.GrindSpline.CapabilityBlocks;
		for (FName CapabilityTag : UserGrindComp.TargetGrindSplineData.GrindSpline.CapabilityBlocks)
		{
			Player.BlockCapabilities(CapabilityTag, this);
		}

		GrappleLocation = UserGrindComp.TargetGrindSplineData.HeightOffsetedWorldLocation;

		FVector ToGrappleLocation = (GrappleLocation - Owner.ActorLocation).SafeNormal;
		GrappleTangent = UserGrindComp.TargetGrindSplineData.ReverseTowardsDirection(ToGrappleLocation);

		GrappleGrindSplineData.SystemPosition.GetActorsInSystem(TargetSplineSystemActors);
		MoveComp.StartIgnoringActors(TargetSplineSystemActors);

		SetGrappleCableWorldLocation(GrappleLocation);
		GrappleCableComp.ResetParticleForces();
		GrappleCableComp.ResetParticleVelocities();
		GrappleCableComp.SetVisibility(true);
		GrappleCableComp.Activate();

		/* Attach Effects */
		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleAttachRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleAttachRumble, false, true, NAME_None);

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble, false, true, NAME_None);

		// Consume the grapple evaluation, so nothing else does any funny business
		GrappleComp.ConsumeFrameEvaluation();

		PlayerHazeAkComp.HazePostEvent(AudioMoveComp.GrindingEvents.DefaultGrappleAttachEvent);

		GrappleGrindSplineData.GrindSpline.OnPlayerTargeted.Broadcast(Player, EGrindTargetReason::Grapple);
		UserGrindComp.OnGrindSplineTargeted.Broadcast(GrappleGrindSplineData.GrindSpline, EGrindTargetReason::Transfer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Swinging, this);
		Owner.UnblockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);	
		for (FName CapabilityTag : ActiveBlocks)
		{
			Player.UnblockCapabilities(CapabilityTag, this);
		}

		MoveComp.StopIgnoringActors(TargetSplineSystemActors);
		GrappleCableComp.SetVisibility(false);
		GrappleCableComp.Deactivate();

		ConsumeAction(GrindingActivationEvents::Grappling);

		if (StartFloor != nullptr)
			MoveComp.StopIgnoringComponent(StartFloor);

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble != nullptr)
			Player.StopForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleConstantRumble, NAME_None);

		if (!UserGrindComp.IsValidToStartGrinding())
			return;

		UserGrindComp.StartGrinding(UserGrindComp.TargetGrindSplineData.GrindSpline, EGrindAttachReason::Grapple, FVector::ZeroVector);
		UserGrindComp.CurrentSpeed = FMath::Max(UserGrindComp.ActiveGrindSplineData.SystemPosition.WorldForwardVector.DotProduct(MoveComp.Velocity), UserGrindComp.DesiredSpeed);

		/* Land Effects */
		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrappleLandRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrappleLandRumble, false, true, NAME_None);

		PlayerHazeAkComp.HazePostEvent(AudioMoveComp.GrindingEvents.DefaultGrappleDettachEvent);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			// Update Rope.
			SetGrappleCableWorldLocation(GrappleLocation);

			// Move Character.
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"GrindingGrapple");
			FrameMove.OverrideCollisionSolver(n"NoCollisionSolver");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"Grind", n"Grapple");
			
			CrumbComp.LeaveMovementCrumb();	
		}	
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			// Update Grapple Speed
			GrappleSpeed += GrindSettings::Grapple.Acceleration * DeltaTime;
			GrappleSpeed -= GrappleSpeed * GrindSettings::Grapple.DragScale * DeltaTime;

			GrappleLocation = UserGrindComp.TargetGrindSplineData.HeightOffsetedWorldLocation;
			FVector ToGrapple = GrappleLocation - Owner.ActorLocation;

			float BackLocationDirectionDot = FMath::Sign(ToGrapple.DotProduct(GrappleTangent));

			FVector ToLine = ToGrapple.ConstrainToPlane(GrappleTangent);
			float DistanceToBackLocation = ToLine.Size();

			FVector TargetLocation = GrappleLocation - (GrappleTangent * DistanceToBackLocation * 0.8f) + ((MoveComp.WorldUp * ToLine.ConstrainToPlane(MoveComp.WorldUp).Size() * 0.4f));
			FVector ToTarget = (TargetLocation - Owner.ActorLocation).GetSafeNormal();

			EnteredVelocity = FMath::VInterpTo(EnteredVelocity, FVector::ZeroVector, DeltaTime, 12.f);
			EnteredVelocity = Math::RotateVectorTowards(EnteredVelocity, ToTarget, GrindSettings::Grapple.EnterVelocityRotationRate * DeltaTime);

			FVector DeltaMove = (ToTarget * GrappleSpeed * DeltaTime) + (EnteredVelocity * DeltaTime);

			if (ToGrapple.Size() < DeltaMove.Size())
			{
				FrameMove.ApplyDeltaWithCustomVelocity(ToGrapple, GrappleTangent.GetSafeNormal() * GrappleSpeed);
				bReachedTarget = true;
			}
			else
				FrameMove.ApplyDelta(DeltaMove);

			FVector TargetFacingDirection = Owner.ActorForwardVector;
			if (!MoveComp.Velocity.IsNearlyZero())
				TargetFacingDirection = MoveComp.Velocity.GetSafeNormal();
			MoveComp.SetTargetFacingDirection(TargetFacingDirection);
			
			FrameMove.OverrideStepDownHeight(0.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}
	
	void SetGrappleCableWorldLocation(FVector InWorldLocation) 
	{
		GrappleCableComp.EndLocation = GetRopeEndTransform().InverseTransformPosition(InWorldLocation);
	}

	FTransform GetRopeEndTransform() const
	{
		USceneComponent EndComponent = GrappleCableComp.GetAttachedComponent();
		if (EndComponent != nullptr)
		{
			if (GrappleCableComp.GetAttachEndToSocketName() != NAME_None)
				return EndComponent.GetSocketTransform(GrappleCableComp.GetAttachEndToSocketName());
			else
				return EndComponent.GetWorldTransform();
		}

		return FTransform::Identity;
	}
}

// struct FGrappleTargetData
// {
// 	float DistanceToIdeal = BIG_NUMBER;
// 	FHazeSplineSystemPosition RegionStart;
// 	FHazeSplineSystemPosition RegionEnd;
// }
