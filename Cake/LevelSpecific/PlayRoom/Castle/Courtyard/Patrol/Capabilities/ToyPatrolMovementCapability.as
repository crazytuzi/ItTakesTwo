import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrol;

import void UpdateSplineMapping(AToyPatrol, UConnectedHeightSplineComponent, UConnectedHeightSplineComponent) from "Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrolManager";

class UToyPatrolMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"ToyPatrolMovement");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 90;

	AToyPatrol ToyPatrol;
	UConnectedHeightSplineFollowerComponent SplineFollowerComp;
	UHazeCrumbComponent CrumbComp;
	float InterpolationTimer;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		ToyPatrol = Cast<AToyPatrol>(Owner);
		SplineFollowerComp = UConnectedHeightSplineFollowerComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);

		InterpolationTimer = ToyPatrol.TransitionLerpTime;

		SplineFollowerComp.OnReachedSplineEnd.AddUFunction(this, n"HandleReachedSplineEnd");
		SplineFollowerComp.OnSplineTransition.AddUFunction(this, n"HandleSplineTransition");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ToyPatrol.SplineFollowerComponent.Spline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ToyPatrol.SplineFollowerComponent.Spline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		Speed = 0.f;
		ToyPatrol.BlockCapabilities(n"ToyPatrolIdle", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams& DeactivationParams)
	{
		ToyPatrol.UnblockCapabilities(n"ToyPatrolIdle", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float Alpha = 0.f;
			if (InterpolationTimer > 0.f)
			{
				InterpolationTimer -= DeltaTime;
				Alpha = FMath::Clamp(InterpolationTimer / ToyPatrol.TransitionLerpTime, 0.f, 1.f);
			}

			Speed = FMath::FInterpTo(Speed, ToyPatrol.MovementSpeed * (1.f + ToyPatrol.AvoidanceSpeedScale), DeltaTime, ToyPatrol.SpeedInterpRate);
			ToyPatrol.AccumulativeOffset += ToyPatrol.OffsetCoefficient * DeltaTime;

			float SplineOffset = SplineFollowerComp.DistanceOnSpline + Speed * DeltaTime;
			float DeltaOffset = SplineFollowerComp.Spline.GetTransformAtDistanceAlongSpline(SplineOffset, ESplineCoordinateSpace::World, true).Scale3D.Y *
				ToyPatrol.GetSineOffset(SplineOffset) * SplineFollowerComp.Spline.BaseWidth + ToyPatrol.AvoidanceOffset;
			DeltaOffset = FMath::Lerp(DeltaOffset, ToyPatrol.EntryOffset, Alpha) - SplineFollowerComp.Offset;

			// Consume avoidance offset and speed, set by manager
			ToyPatrol.AvoidanceOffset /= 2.f;
			ToyPatrol.AvoidanceSpeedScale = 0.f;

			SplineFollowerComp.AddMovementVector(FVector(Speed * DeltaTime, DeltaOffset, 0.f));
		}
		else
		{
			FHazeActorReplicationFinalized Params;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, Params);

			SplineFollowerComp.Transform.Location = Params.Location;
			SplineFollowerComp.Transform.Rotation = Params.Rotation.Quaternion();

			if (DeltaTime != 0.f)
			{
				FVector Direction = SplineFollowerComp.bUseActorForwardDirection ? ToyPatrol.ActorForwardVector : SplineFollowerComp.Velocity.GetSafeNormal();
				SplineFollowerComp.Velocity = (SplineFollowerComp.Transform.Location - ToyPatrol.ActorLocation) / DeltaTime;
				SplineFollowerComp.AngularVelocity = SplineFollowerComp.Transform.Rotation.ForwardVector.CrossProduct(Direction) / DeltaTime;
			}
		}

		FVector DeltaMovement = (SplineFollowerComp.Transform.Location - ToyPatrol.ActorLocation);
		FQuat TargetRotation = Math::MakeQuatFromZX(FVector::UpVector, SplineFollowerComp.Transform.Rotation.ForwardVector);

		ToyPatrol.SetActorLocationAndRotation(SplineFollowerComp.Transform.Location,
			FMath::QInterpTo(ToyPatrol.ActorQuat, TargetRotation, DeltaTime, ToyPatrol.RotationInterpRate));

		if (HasControl())
			CrumbComp.LeaveMovementCrumb();

		// Make sure we can actually request locomotion
		if (!ToyPatrol.Mesh.CanRequestLocomotion() || DeltaTime == 0.f)
			return;

		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"Movement";
		AnimRequest.MoveSpeed = ToyPatrol.MovementSpeed;
		AnimRequest.LocomotionAdjustment.DeltaTranslation = DeltaMovement;
 		AnimRequest.WantedVelocity = DeltaMovement / DeltaTime;
		ToyPatrol.RequestLocomotion(AnimRequest);
	}

	UFUNCTION()
	void HandleReachedSplineEnd(bool bForward)
	{
		ToyPatrol.MovementSpeed *= -1.f;
	}

	UFUNCTION()
	void HandleSplineTransition(UConnectedHeightSplineFollowerComponent ConnectedHeightSplineFollowerComponent, bool bForward)
	{
		InterpolationTimer = ToyPatrol.TransitionLerpTime;
		ToyPatrol.EntryOffset = SplineFollowerComp.Offset;

		UpdateSplineMapping(ToyPatrol, SplineFollowerComp.PreviousSpline, SplineFollowerComp.Spline);
	}
}