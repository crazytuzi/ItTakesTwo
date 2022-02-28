

import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Swinging.SwingSettings;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Movement.SplineLock.SplineLockComponent;
import Vino.Movement.PlaneLock.PlaneLockActor;
import Peanuts.Network.RelativeCrumbLocationCalculator;

class USwingRadialMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingMovement");

	default CapabilityDebugCategory = n"Movement Swinging";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 5;

	AHazePlayerCharacter OwningPlayer;
	USwingingComponent SwingingComponent;
	USplineLockComponent SplineLockComp;
	UPlaneLockUserComponent PlaneLockComp;
	USwingPointComponent ActiveSwingPoint;
	UCameraSpringArmComponent SpringArmComp;
	UHazeAkComponent HazeAKComp;

	FSwingSettings SwingSettings;
	FHazeAcceleratedFloat Radius;
	FHazeAcceleratedFloat AcceleratedDesiredDirectionAngle;

	FTransform AttachLastTransform;
	FVector FrameInheritedLocation;

	bool bVelocityGoingTowardsSwingPoint = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
		SpringArmComp = UCameraSpringArmComponent::Get(Owner);
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);
		PlaneLockComp = UPlaneLockUserComponent::GetOrCreate(Owner);
		HazeAKComp = UHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		USwingPointComponent SwingPoint = SwingingComponent.GetActiveSwingPoint();
		if (SwingPoint == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		float DistanceToSwingDistance = SwingPoint.GetDistance(EHazeActivationPointDistanceType::Selectable) - SwingPoint.RopeLength;
		if ((SwingingComponent.PlayerLocation - SwingPoint.WorldLocation).Size() < DistanceToSwingDistance)
			return EHazeNetworkActivation::DontActivate;

		FVector SwingToPlayer = SwingingComponent.PlayerLocation - SwingPoint.WorldLocation;
		float RelativeHeightDot = MoveComp.WorldUp.DotProduct(SwingToPlayer);
		if (RelativeHeightDot > 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		USwingPointComponent CurrentPoint = SwingingComponent.GetActiveSwingPoint();
		if (ActiveSwingPoint != CurrentPoint)
			return RemoteLocalControlCrumbDeactivation();

		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OwningPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
		OwningPlayer.BlockCapabilities(ActionNames::WeaponAim, this); 

		ActiveSwingPoint = SwingingComponent.GetActiveSwingPoint();

		CrumbComp.MakeCrumbsUseCustomWorldCalculator(URelativeCrumbLocationCalculator::StaticClass(), this, ActiveSwingPoint);

		SetInitialRadiusAndRadiusVelocity();

		bVelocityGoingTowardsSwingPoint = true;

		SwingingComponent.ShowRopeKnot();

		/*
			Update Desired Direction & Target Desired
		*/
		
		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);		
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		// If you are spline locked
		if (SplineLockComp.Spline != nullptr || PlaneLockComp.Constraint.IsConstrained())
		{
			FVector Tangent;
			if (SplineLockComp.Spline != nullptr)
			{
				float DistanceAlongSpline = SplineLockComp.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
				Tangent = SplineLockComp.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
			}
			else if (PlaneLockComp.Constraint.IsConstrained())
			{
				// If you are plane locked
				FVector Normal = PlaneLockComp.Constraint.Plane.Normal;
				Tangent = Normal.CrossProduct(MoveComp.WorldUp);
			}

			// Set Desired Direction
			FVector DesiredTangentDirectionComparisonVector = HorizontalVelocity.IsNearlyZero() ? PlayerToPoint : HorizontalVelocity;
			SwingingComponent.DesiredDirection = Tangent * FMath::Sign(Tangent.DotProduct(DesiredTangentDirectionComparisonVector));

			// Set Target Desired Direction
			if (MoveDirection.Size() >= 0.2f)
				SwingingComponent.TargetDesired = Tangent * FMath::Sign(Tangent.DotProduct(MoveDirection)); 
			else if (!HorizontalVelocity.IsNearlyZero())
				SwingingComponent.TargetDesired = Tangent * FMath::Sign(Tangent.DotProduct(HorizontalVelocity));
			else
				SwingingComponent.TargetDesired = SwingingComponent.DesiredDirection;

			AcceleratedDesiredDirectionAngle.SnapTo(0.f, 0.f);
		}
		else
		{

			// Set Desired Direction
			if (HorizontalVelocity.IsNearlyZero())
			{
				FRotator CameraRotation = OwningPlayer.GetPlayerViewRotation();
				CameraRotation.Pitch = 0.f;
				CameraRotation.Roll = 0.f;

				SwingingComponent.DesiredDirection = CameraRotation.ForwardVector;
			}
			else
			{
				SwingingComponent.DesiredDirection = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
				SwingingComponent.DesiredDirection.Normalize();
			}

			// Set Target Desired Direction
			if (MoveDirection.Size() >= 0.2f)
			{
				SwingingComponent.TargetDesired = MoveDirection.GetSafeNormal(); 
			}
			else
			{
				FRotator CameraRotation = OwningPlayer.GetPlayerViewRotation();
				CameraRotation.Pitch = 0.f;
				CameraRotation.Roll = 0.f;

				SwingingComponent.TargetDesired = CameraRotation.ForwardVector;
			}				

			// Calculate and set angular yaw velocity on attach
			FVector RightPointToPlayer = MoveComp.WorldUp.CrossProduct(SwingingComponent.PlayerToSwingPoint);
			RightPointToPlayer.Normalize();
			float AccelerationSpeed = -RightPointToPlayer.DotProduct(MoveComp.Velocity);
			AccelerationSpeed /= SwingingComponent.PlayerToSwingPoint.Size();

			FVector DesiredRight = MoveComp.WorldUp.CrossProduct(SwingingComponent.DesiredDirection).GetSafeNormal();
			float RotationDirection = FMath::Sign(SwingingComponent.TargetDesired.DotProduct(DesiredRight));

			float Angle = FMath::Acos(SwingingComponent.DesiredDirection.DotProduct(GetAngularClosestTargetDesiredDirection()));
			Angle *= RotationDirection;

			AcceleratedDesiredDirectionAngle.SnapTo(Angle, AccelerationSpeed);					
		}		
		

		FVector ConstrainedVelocity = MoveComp.Velocity.ConstrainToPlane(GetPlayerToPoint().GetSafeNormal());
		FVector RemainingVelocity = MoveComp.Velocity - ConstrainedVelocity;
		FVector SignedTargetDirection = (SwingingComponent.TargetDesired * FMath::Sign(SwingingComponent.TargetDesired.DotProduct(ConstrainedVelocity))).GetSafeNormal();

		MoveComp.Velocity = ConstrainedVelocity + (GetAngularClosestTargetDesiredDirection().GetSafeNormal() * RemainingVelocity.Size() * 0.5f);

		AttachLastTransform = ActiveSwingPoint.GetAttachParent().WorldTransform;
		AttachLastTransform.Scale3D = FVector::OneVector;

		// Play Sounds
		if (SwingingComponent.EffectsData.PlayerAttach != nullptr)
			HazeAKComp.HazePostEvent(SwingingComponent.EffectsData.PlayerAttach);

		if (SwingingComponent.EffectsData.SwingPointAttach != nullptr)
			UHazeAkComponent::HazePostEventFireForget(SwingingComponent.EffectsData.SwingPointAttach, SwingingComponent.ActiveSwingPoint.WorldTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CrumbComp.RemoveCustomWorldCalculator(this);

		OwningPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		OwningPlayer.UnblockCapabilities(ActionNames::WeaponAim, this);

		SwingingComponent.HideRopeKnot();

		// Play Sounds
		if (SwingingComponent.EffectsData.PlayerDetach != nullptr)
			HazeAKComp.HazePostEvent(SwingingComponent.EffectsData.PlayerDetach);

		if (SwingingComponent.ActiveSwingPoint == nullptr)
			SwingingComponent.SwingRope.DetachFromSwingPoint();

		if (SwingingComponent.IsSwinging() && SwingingComponent.GetActiveSwingPoint() == nullptr)
			SwingingComponent.StopSwinging();
		
		// Make sure the player is facing the correct direction
		FVector FacingDirection = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		MoveComp.SetTargetFacingDirection(FacingDirection);

		ActiveSwingPoint = nullptr;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			//Update audio before updating the crumb trail since that could change data we are trying to read.
			UpdateAudio();

			SwingingComponent.UpdateSwingTime(DeltaTime);

			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Swinging");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"Swinging");
			
			CrumbComp.LeaveMovementCrumb();

			SwingingComponent.UpdateRopeKnotTransform();


			const float ForceFeedbackMin = 1000.f;
			const float ForceFeedbackMax = 2400.f;
			const float Strength = FMath::Pow(FMath::Clamp((MoveComp.Velocity.Size() - ForceFeedbackMin) / (ForceFeedbackMax - ForceFeedbackMin), 0.f, 1.f), 2.5f);
			OwningPlayer.SetFrameForceFeedback(Strength * 0.05f, Strength * 0.25f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		if (SwingingComponent.ActiveSwingPoint == nullptr)
			return;

		// Clear active swing point
		SwingingComponent.StopSwinging();
	}

	bool IsVelocityGoingTowardsSwingPoint()
	{
		FVector DirectionToPoint = PlayerToPoint.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		if (DirectionToPoint.DotProduct(MoveComp.Velocity) > 0.f)
			return true;
		return false;
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector Velocity = MoveComp.Velocity;		

			// Inherit the movement and rotation of the attached parent
			FTransform AttachTransform = ActiveSwingPoint.GetAttachParent().WorldTransform;

			// Get delta rotation... (if we want it)
			if (ActiveSwingPoint.bInheritRotation)
			{
				FTransform AttachDeltaTransform = AttachTransform * AttachLastTransform.Inverse();
				SwingingComponent.TargetDesired = AttachDeltaTransform.Rotation * SwingingComponent.TargetDesired;
			}

			// Get delta location...
			FrameInheritedLocation = AttachTransform.Location - AttachLastTransform.Location;
			SwingingComponent.InheritedVelocity = FrameInheritedLocation / DeltaTime;

			AttachLastTransform = AttachTransform;

			SetTargetDesiredDirection(DeltaTime);
			RotateDesiredDirectionAndPlayer(Velocity, FrameMove, DeltaTime);
			RotateVelocityTowardsDesired(Velocity, DeltaTime);

			// Add Gravity
			Velocity += CalculateGravity() * DeltaTime;

			// Add Acceleration
			FVector CorrectionAcceleration = CalculateAcceleration(Velocity);
			Velocity += CorrectionAcceleration * DeltaTime;

			// Get corrected radius delta
			FVector CorrectionRadiusDelta = GetRadiusCorrectionDelta(DeltaTime);


			// Find out how far around a sphere the current velocity length will take you
			FVector BiTangent = Velocity.CrossProduct(GetPlayerToPoint());
			BiTangent.Normalize();

			float DeltaDistance = Velocity.Size() * DeltaTime; 
			float DeltaAngle = DeltaDistance / Radius.Value;

			FVector ToPlayer = -GetPlayerToPoint();
			FQuat DeltaQuat = FQuat(BiTangent, DeltaAngle);

			// Calculate the delta move around the sphere
			FVector NextToPlayer = DeltaQuat * ToPlayer;
			FVector DeltaMove = NextToPlayer - ToPlayer;
			// Rotate the velocity for the next frame
			Velocity = DeltaQuat * Velocity;	
			// Velocity drift protection
			Velocity = GetPlayerToPoint().CrossProduct(BiTangent).GetSafeNormal() * Velocity.Size();
			//MoveComp.Velocity = Velocity;
		
			// Move the player
			FrameMove.ApplyDeltaWithCustomVelocity(DeltaMove + CorrectionRadiusDelta + FrameInheritedLocation, Velocity);
			FrameInheritedLocation = FVector::ZeroVector;

			FrameMove.SetRotation(Math::MakeQuatFromX(SwingingComponent.DesiredDirection));

			if (IsDebugActive())
			{
				Owner.DebugDrawLineDelta(SwingingComponent.TargetDesired * 300.f, FLinearColor(0.5f, 0.5f, 0.5f), 0.f, 2.f);			
				Owner.DebugDrawLineDelta(AngularClosestTargetDesiredDirection * 300.f, FLinearColor::White, 0.f, 2.f);
				Owner.DebugDrawLineDelta(SwingingComponent.DesiredDirection * 150.f, FLinearColor::Green, 0.f, 3.f);
				Owner.DebugDrawLineDelta(CorrectionAcceleration, FLinearColor::LucBlue, 0.f, 1.f);				
				
				float RopeLengthDifference = Radius.Value - ActiveSwingPoint.RopeLength;
				FVector RopeDirection = GetPointToPlayer().GetSafeNormal();
				FVector StartRopeLocation = ActiveSwingPoint.WorldLocation;
				FVector EndRopeLocation = StartRopeLocation + RopeDirection * FMath::Min(Radius.Value, ActiveSwingPoint.RopeLength);
				OwningPlayer.DebugDrawLine(StartRopeLocation, EndRopeLocation, FLinearColor::Green, 0.f, 3.f);

				FVector RopeReaminingStartLocation = StartRopeLocation + (RopeDirection * ActiveSwingPoint.RopeLength);
				FVector RopeRemainingEndLocation = StartRopeLocation + RopeDirection * Radius.Value;

				FLinearColor RemainingColor = RopeLengthDifference > 0.f ? FLinearColor::Red : FLinearColor::Blue;
				OwningPlayer.DebugDrawLine(RopeReaminingStartLocation, RopeRemainingEndLocation, RemainingColor, 0.f, 4.f);


				// Debug radius
				//System::DrawDebugLine(SwingingComponent.PlayerLocation, SwingingComponent.PlayerLocation - GetPlayerToPoint().GetSafeNormal() * (ActiveSwingPoint.SwingRangeDistance - Radius.Value), Thickness = 5.f);
				// Velocity
				//System::DrawDebugLine(SwingingComponent.PlayerLocation, SwingingComponent.PlayerLocation + Velocity);
				
			}
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
		
		FrameMove.ApplyTargetRotationDelta(); 		
	}

	void UpdateAudio()
	{
		bool bNewVelocityGoingTowardsSwingPoint = IsVelocityGoingTowardsSwingPoint();
		if (!bVelocityGoingTowardsSwingPoint && bNewVelocityGoingTowardsSwingPoint)
		{
			if ( SwingingComponent.EffectsData.DirectionChange != nullptr)
				HazeAKComp.HazePostEvent(SwingingComponent.EffectsData.DirectionChange);
		}
		bVelocityGoingTowardsSwingPoint = bNewVelocityGoingTowardsSwingPoint;

		const float TargetApexSpeed = ActiveSwingPoint.SpeedSettings.TargetApexSpeed;
		float SpeedAlpha = Math::GetPercentageBetweenClamped(0.f, TargetApexSpeed, MoveComp.Velocity.Size());
		HazeAKComp.SetRTPCValue("Rtpc_Gadget_RopeSwing_Velocity", SpeedAlpha, 0);
	}

	void SetInitialRadiusAndRadiusVelocity()
	{
		float SpeedAwayFromSwingPoint = MoveComp.Velocity.DotProduct(GetPointToPlayer().GetSafeNormal());
		float DistanceFromPoint = GetPointToPlayer().Size();

		if (DistanceFromPoint >= ActiveSwingPoint.RopeLength)
			Radius.SnapTo(DistanceFromPoint);
		else
			Radius.SnapTo(DistanceFromPoint, SpeedAwayFromSwingPoint);
	}

	FVector GetSlopeDirection() property
	{
		FVector PlayerToActivePoint = GetPlayerToPoint();
		FVector BiTangent = PlayerToActivePoint.CrossProduct(MoveComp.WorldUp);

		return (PlayerToActivePoint.CrossProduct(BiTangent)).GetSafeNormal();
	}

	FVector GetPointToPlayer() const property
	{
		return (SwingingComponent.PlayerLocation + FrameInheritedLocation) - ActiveSwingPoint.WorldLocation ;
	}

	FVector GetPlayerToPoint() const property
	{
		return ActiveSwingPoint.WorldLocation - (SwingingComponent.PlayerLocation + FrameInheritedLocation);
	}

	FVector CalculateGravity()
	{	
		FVector PlayerToActivePoint = GetPlayerToPoint();
		PlayerToActivePoint.Normalize();
		FVector BiTangent = PlayerToActivePoint.CrossProduct(MoveComp.WorldUp);
		FVector Tangent = PlayerToActivePoint.CrossProduct(BiTangent);

		float VelocitySlope = 1.f - FMath::Clamp(MoveComp.Velocity.CrossProduct(Tangent.GetSafeNormal()).DotProduct(PlayerToActivePoint) / 5000.f, 0.0f, 0.6f);

		float GravityForce = 5200.f;
		return Tangent * GravityForce * VelocitySlope;
		//return Tangent * SwingSettings.GravityForce * VelocitySlope;
	}
	FVector CalculateAcceleration(FVector CurrentVelocity)
	{	
		float AngleDot = -MoveComp.WorldUp.GetSafeNormal().DotProduct(-PlayerToPoint.GetSafeNormal());
		float AngleDifference = FMath::RadiansToDegrees(FMath::Acos(AngleDot));
		float AngleLerp = 1 - FMath::Clamp(AngleDifference / (ActiveSwingPoint.SwingAngle), 0.f, 1.f);
		float AngleLerpCurved = FMath::Pow(AngleLerp, 0.32f);

		//float PeakSpeed = (ActiveSwingPoint.SwingAngle * 38.f * 0.6f) + (ActiveSwingPoint.RopeLength * 2.8f * 0.4f);

		float ExpectedSpeed = ActiveSwingPoint.SpeedSettings.TargetApexSpeed * AngleLerpCurved;
		float SpeedDifference = ExpectedSpeed - CurrentVelocity.Size();

		FVector VelocityChange = SwingingComponent.DesiredDirection * FMath::Sign(CurrentVelocity.DotProduct(SwingingComponent.DesiredDirection)) * (SpeedDifference * ActiveSwingPoint.SpeedSettings.SpeedCorrectionForce);
		// return FVector::ZeroVector;
		return VelocityChange; 
	}

	FVector GetRadiusCorrectionDelta(float DeltaTime)
	{
		float TargetRadius = ActiveSwingPoint.RopeLength;
		float CurrentRadius = PointToPlayer.Size();
		float RadiusAcceleration = CurrentRadius > TargetRadius ? SwingSettings.RadiusAccelerationDurationRetract : SwingSettings.RadiusAccelerationDurationExtend;
		Radius.AccelerateTo(TargetRadius, RadiusAcceleration, DeltaTime);

		FVector TargetPointToPlayer = PointToPlayer.GetSafeNormal() * Radius.Value;

		return TargetPointToPlayer - PointToPlayer;
	}

	void RotateVelocityTowardsDesired(FVector& Velocity, float DeltaTime)
	{
		FVector RotationDelta;
		RotationDelta = SwingingComponent.DesiredDirection.CrossProduct(MoveComp.WorldUp);
		RotationDelta.Normalize();

		float VelocityDot = RotationDelta.DotProduct(Velocity);
		RotationDelta = RotationDelta * VelocityDot;

		// Remove velocity away from desired direction
		Velocity += RotationDelta * -SwingSettings.VelocityToDesiredRotationSpeed * DeltaTime;
	}	

	void SetTargetDesiredDirection(float DeltaTime)
	{		
		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

		if (SplineLockComp.Spline != nullptr)
		{
			// If you are spline locked
			float DistanceAlongSpline = SplineLockComp.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
			FVector Tangent = SplineLockComp.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();

			if (Input.IsNearlyZero(0.1f))
				SwingingComponent.TargetDesired = Tangent * FMath::Sign(Tangent.DotProduct(MoveComp.Velocity));
			else
				SwingingComponent.TargetDesired = Input.GetSafeNormal();
		}
		else if (PlaneLockComp.Constraint.IsConstrained())	
		{
			// If you are plane locked
			FVector Normal = PlaneLockComp.Constraint.Plane.Normal;
			FVector Tangent = Normal.CrossProduct(MoveComp.WorldUp);

			if (Input.IsNearlyZero(0.1f))
				SwingingComponent.TargetDesired = Tangent * FMath::Sign(Tangent.DotProduct(MoveComp.Velocity));
			else
				SwingingComponent.TargetDesired = Input.GetSafeNormal();
		}
		else
		{
			if (!Input.IsNearlyZero(0.1f))		
				SwingingComponent.TargetDesired = Input.GetSafeNormal();
			else if (!GetAttributeVector(AttributeVectorNames::RightStickRaw).IsNearlyZero() || WasAttributeVectorChangedDuringTime(AttributeVectorNames::RightStickRaw, 0.1f))
			{
				FVector CameraDirection = OwningPlayer.ControlRotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
				SwingingComponent.TargetDesired = CameraDirection;
			}
		}
	}

	FVector GetAngularClosestTargetDesiredDirection() property
	{
		return SwingingComponent.TargetDesired * FMath::Sign(SwingingComponent.TargetDesired.DotProduct(SwingingComponent.DesiredDirection));
	}
	
	void RotateDesiredDirectionAndPlayer(FVector& Velocity, FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FVector TargetDesired = AngularClosestTargetDesiredDirection;
		float PlayerTargetDot = FMath::Sign(PlayerToPoint.DotProduct(TargetDesired));

		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

		FVector DesiredRight = MoveComp.WorldUp.CrossProduct(SwingingComponent.DesiredDirection).GetSafeNormal();
		float RotationDirection = FMath::Sign(TargetDesired.DotProduct(DesiredRight));

		float Angle = FMath::Acos(SwingingComponent.DesiredDirection.DotProduct(TargetDesired));
		Angle *= RotationDirection;
		AcceleratedDesiredDirectionAngle.AccelerateTo(Angle, 1.f, DeltaTime);

		FVector Axis = MoveComp.WorldUp;	

		FQuat RotationQuat = FQuat(Axis, AcceleratedDesiredDirectionAngle.Value * DeltaTime);
		SwingingComponent.DesiredDirection = RotationQuat * SwingingComponent.DesiredDirection;

		SwingingComponent.DesiredDirection = SwingingComponent.DesiredDirection.ConstrainToPlane(MoveComp.WorldUp);
		SwingingComponent.DesiredDirection.Normalize();

		Velocity = RotationQuat * Velocity;
		FVector PlayerOffset = -GetPlayerToPoint();
		FVector RotatedPlayerOffset = RotationQuat * PlayerOffset;
		FrameMove.ApplyDeltaWithCustomVelocity(RotatedPlayerOffset - PlayerOffset, FVector::ZeroVector);	
	}	
}
