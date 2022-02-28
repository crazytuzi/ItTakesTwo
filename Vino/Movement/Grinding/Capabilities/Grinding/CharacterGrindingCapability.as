import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Grinding.GrindingNetworkNames;

class UCharacterGrindingCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default CapabilityDebugCategory = n"Grinding";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 115;
	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 111);

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	bool bReachedEndOfSpline = false;

	FVector Offset = FVector::ZeroVector;
	FHazeAcceleratedVector AcceleratedOffset;

	EHazeUpdateSplineStatusType CurrentSplineStatus = EHazeUpdateSplineStatusType::Invalid;

	FHazeSplineSystemPosition CurrentSplinePosition;
	UNiagaraComponent GrindEffectCompLeft;
	UNiagaraComponent GrindEffectCompRight;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);	
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{		
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (CurrentSplineStatus == EHazeUpdateSplineStatusType::AtEnd)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentSplineStatus = EHazeUpdateSplineStatusType::Valid;
		FTransform SplineLocationTransform = UserGrindComp.SplinePosition.WorldTransform;
		FVector WorldOffset = Owner.ActorLocation - (UserGrindComp.SplinePosition.WorldLocation + UserGrindComp.CurrentHeigtOffset);
		Offset = SplineLocationTransform.InverseTransformVector(WorldOffset);

		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(CameraTags::FindOtherPlayer, this);
		Player.BlockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);

		FVector ToSplineLocation = (UserGrindComp.SplinePosition.WorldLocation - Owner.ActorLocation).GetSafeNormal();
		FVector VelocityToSplineLocation = ToSplineLocation * ToSplineLocation.DotProduct(MoveComp.Velocity);
		FVector InitialVelocity = VelocityToSplineLocation;
		float VerticalSpeed = FMath::Min(0.f, UserGrindComp.SplinePosition.WorldUpVector.DotProduct(MoveComp.Velocity));
		if (ToSplineLocation.DotProduct(UserGrindComp.SplinePosition.WorldUpVector) < 0.f)
			InitialVelocity -= UserGrindComp.SplinePosition.WorldUpVector * VerticalSpeed;
		
		AcceleratedOffset.SnapTo(Offset, InitialVelocity);

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrindRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrindRumble, true, true, NAME_None, 1.f);

		if (UserGrindComp.ActiveGrindSpline.GrindingEffectsData != nullptr && UserGrindComp.ActiveGrindSpline.GrindingEffectsData.GrindEffect != nullptr)
		{
			if (GrindEffectCompRight == nullptr)
			{
				GrindEffectCompRight = Niagara::SpawnSystemAtLocation(UserGrindComp.ActiveGrindSpline.GrindingEffectsData.GrindEffect, Player.Mesh.GetSocketLocation(n"RightFoot"), bAutoDestroy = false);
			}
			else
				GrindEffectCompRight.Activate(true);

			if (GrindEffectCompLeft == nullptr)
				GrindEffectCompLeft = Niagara::SpawnSystemAtLocation(UserGrindComp.ActiveGrindSpline.GrindingEffectsData.GrindEffect, Player.Mesh.GetSocketLocation(n"LeftFoot"), bAutoDestroy = false);
			else
				GrindEffectCompLeft.Activate(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		OutParams.AddActionState(GrindingNetworkNames::EndOfSpline);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrindRumble != nullptr)
			Player.StopForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrindRumble, NAME_None);

		if (UserGrindComp.HasActiveGrindSpline() && DeactivationParams.GetActionState(GrindingNetworkNames::EndOfSpline))
		{
			UserGrindComp.StartGrindSplineCooldown(UserGrindComp.ActiveGrindSplineData.GrindSpline);
			UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::EndOfSpline);			
		}

		if (GrindEffectCompRight != nullptr)
			GrindEffectCompRight.Deactivate();
		if (GrindEffectCompLeft != nullptr)
			GrindEffectCompLeft.Deactivate();

		MoveComp.ResetColliderOrientation(this);

		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(CameraTags::FindOtherPlayer, this);
		Player.UnblockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (GrindEffectCompRight != nullptr)
		{
			GrindEffectCompRight.DestroyComponent(this);
			GrindEffectCompLeft = nullptr;
		}
		if (GrindEffectCompLeft != nullptr)
		{
			GrindEffectCompLeft.DestroyComponent(this);
			GrindEffectCompLeft = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		ReduceOffset(DeltaTime);
		UpdateCollision();
		// The collision update could trigger a overlap callback that resets grinding.
		if (!UserGrindComp.HasActiveGrindSpline())
			return;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(GrindingCapabilityTags::Movement);
		if (HasControl())
		{
			CurrentSplinePosition = UserGrindComp.FollowComp.Position;
			CalculateControlSideMove(FrameMove, DeltaTime, CurrentSplineStatus);
			CheckSplineBroadcasts();
		}
		else
		{
			// If the crumb trail hit a delegate that ends grinding then we need out.
			CalculateRemoteSideMove(FrameMove, DeltaTime);
			if (!UserGrindComp.HasActiveGrindSpline())
				return;
		}

		MoveCharacter(FrameMove, n"Grind");
		CrumbComp.LeaveMovementCrumb();

		if (GrindEffectCompRight != nullptr)
			GrindEffectCompRight.SetWorldLocation(Player.Mesh.GetSocketLocation(n"RightFoot"));
		if (GrindEffectCompLeft != nullptr)
			GrindEffectCompLeft.SetWorldLocation(Player.Mesh.GetSocketLocation(n"LeftFoot"));
	}

	void CheckSplineBroadcasts()
	{
		if (CurrentSplinePosition.Spline == UserGrindComp.FollowComp.Position.Spline)
			return;

		FHazeDelegateCrumbParams Params;
		Params.AddObject(n"LeaveGrind", CurrentSplinePosition.Spline.Owner);
		Params.AddObject(n"AttachGrind", UserGrindComp.ActiveGrindSpline);

		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"TriggerGrindConnection"), Params);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerGrindConnection(FHazeDelegateCrumbData Data)
	{			
		AGrindspline LeaveGrind = Cast<AGrindspline>(Data.GetObject(n"LeaveGrind"));
		AGrindspline AttachGrind = Cast<AGrindspline>(Data.GetObject(n"AttachGrind"));

		if (!Data.IsStale())
		{
			devEnsure(LeaveGrind != nullptr, "TriggerGrindConnection: LeaveGrind is null while Data crumb is not stale");
			devEnsure(AttachGrind != nullptr, "TriggerGrindConnection: AttachGrind is null while Data crumb is not stale");
		}

		// Data can be stale on remote which will return null Leave and Attach grind references
		if (LeaveGrind != nullptr)
			LeaveGrind.OnPlayerDetached.Broadcast(Player, EGrindDetachReason::Connection);
		if (AttachGrind != nullptr)
			AttachGrind.OnPlayerAttached.Broadcast(Player, EGrindAttachReason::Connection);
	}

	void CalculateControlSideMove(FHazeFrameMovement& FrameMove, float DeltaTime, EHazeUpdateSplineStatusType& OutSplineStatus)
	{
		FHazeSplineSystemPosition FuturePosition;
		OutSplineStatus = UserGrindComp.FollowComp.UpdateSplineMovement(UserGrindComp.CurrentSpeed * DeltaTime, FuturePosition);
		FVector FacingDirection;
		if (OutSplineStatus == EHazeUpdateSplineStatusType::Valid)
		{
			FVector EndLocation = FuturePosition.WorldLocation;
			FVector PlayerStart = Owner.ActorLocation;
			FVector PlayerEnd = EndLocation + GetOffsetInWorldSpace();			

			FVector MoveDelta = PlayerEnd - PlayerStart;
			FacingDirection = MoveDelta.GetSafeNormal();		

			FrameMove.ApplyDelta(MoveDelta);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Grounded);	
		}
		else
		{
			FVector Velocity = FuturePosition.WorldForwardVector * UserGrindComp.CurrentSpeed;
			float TangentWorldUpDot = FuturePosition.WorldForwardVector.GetSafeNormal().DotProduct(MoveComp.WorldUp);
			if (TangentWorldUpDot < 0.f)
			{
				const float MaxAngleIncrease = 60.f;
				FVector VelocityDirection = Velocity.GetSafeNormal();
				FVector Axis = FuturePosition.WorldForwardVector.CrossProduct(MoveComp.WorldUp);
				float Angle = MaxAngleIncrease * FMath::Abs(TangentWorldUpDot) * DEG_TO_RAD;
				FQuat RotationQuat = FQuat(Axis, Angle);
				Velocity = RotationQuat * Velocity;
			}

			FacingDirection = Velocity.GetSafeNormal();
			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
		}

		MoveComp.SetTargetFacingDirection(FacingDirection.IsNearlyZero() ? MoveComp.OwnerRotation.ForwardVector : FacingDirection);
		FrameMove.ApplyTargetRotationDelta();
		FrameMove.OverrideStepDownHeight(0.f);
		FrameMove.OverrideStepUpHeight(100.f);
	}

	void CalculateRemoteSideMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{

		// Fix for IsGrounded() not being 'replicated'. 
		// This should perhaps be handled via ConsumedCrumbs down below 
		if(CurrentSplineStatus == EHazeUpdateSplineStatusType::Valid)
			FrameMove.OverrideGroundedState(EHazeGroundedState::Grounded);
		else
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);

		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		FrameMove.ApplyConsumedCrumbData(ConsumedParams);

		// If the crumb trail hit a delegate that ends grinding then we need out.
		if (UserGrindComp.HasActiveGrindSpline())
			UserGrindComp.UpdateRemoteSplineLocation(ConsumedParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		if (UserGrindComp.HasActiveGrindSpline())
		{
			UserGrindComp.StartGrindSplineCooldown(UserGrindComp.ActiveGrindSplineData.GrindSpline);
			UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::CapabilityBlocked);
		}
	}

	void UpdateCollision()
	{
		FVector NewUpVector = UserGrindComp.SplinePosition.WorldUpVector;
		MoveComp.SetColliderOrienation(NewUpVector, this);
	}

	void ReduceOffset(float DeltaTime)
	{
		Offset = FMath::VInterpTo(Offset, FVector::ZeroVector, DeltaTime, GrindSettings::GrindingOffsetInterpSpeed);
		AcceleratedOffset.AccelerateTo(FVector::ZeroVector, 0.5f, DeltaTime);
	}

	FVector GetOffsetInWorldSpace()
	{
		FVector WorldOffset =  UserGrindComp.SplinePosition.WorldTransform.TransformVector(AcceleratedOffset.Value);
		return WorldOffset + UserGrindComp.CurrentHeigtOffset;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		if (UserGrindComp == nullptr)
			return "Error: No GrindUserComponent.";

		FString Output = UserGrindComp.GetDebugString();
		return Output;
	}
}
