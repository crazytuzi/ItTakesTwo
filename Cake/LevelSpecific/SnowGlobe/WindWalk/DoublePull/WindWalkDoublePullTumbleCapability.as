import Vino.DoublePull.DoublePullGoBackCapability;
import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;

class UWindWalkDoublePullTumbleCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullTumble);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	const float FallSpeed = 500.f;
	const float TerminalSpeed = 800.f;

	AWindWalkDoublePullActor WindWalkDoublePullOwner;
	UDoublePullComponent DoublePullComponent;
	UHazeMovementComponent MovementComponent;
	UHazeCrumbComponent CrumbComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WindWalkDoublePullOwner = Cast<AWindWalkDoublePullActor>(Owner);
		DoublePullComponent = UDoublePullComponent::Get(Owner);
		MovementComponent = WindWalkDoublePullOwner.MovementComponent;
		CrumbComponent = WindWalkDoublePullOwner.CrumbComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(DoublePullComponent == nullptr || DoublePullComponent.Spline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(n"DoublePullForceGoBack"))
			return EHazeNetworkActivation::DontActivate;

		// Don't fall if actor is at the bottom
		if(WindWalkDoublePullOwner.bIsInStartZone)
			return EHazeNetworkActivation::DontActivate;

		if(!MovementComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WindWalkDoublePullOwner.BlockCapabilities(n"DoublePullEffort", this);

		WindWalkDoublePullOwner.FullscreenPlayer.ApplyIdealDistance(800.f, 2.f, this);

		FHazePointOfInterest PointOfInterest;
		PointOfInterest.Blend = 2.f;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::Object;
		PointOfInterest.FocusTarget.Actor = WindWalkDoublePullOwner;
		PointOfInterest.FocusTarget.LocalOffset = FVector(500.f, 0.f, -100.f);

		WindWalkDoublePullOwner.FullscreenPlayer.ApplyPointOfInterest(PointOfInterest, this);

		WindWalkDoublePullOwner.OnTumblingStarted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MovementComponent.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(WindWalkTags::WindWalkDoublePullTumbleRecovery);
		MoveData.OverrideCollisionProfile(n"NoCollision");

		if(HasControl())
		{
			float DistanceAlongSpline = DoublePullComponent.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
			FVector MovementDirection = -DoublePullComponent.Spline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

			// Calculate next location and constrain it to spline
			FVector NextLocation = WindWalkDoublePullOwner.ActorLocation + MovementDirection * FallSpeed * DeltaTime;
			NextLocation = DoublePullComponent.ConstrainPointToSpline(NextLocation);

			// Add spline-constrained movement to current velocity
			FVector DeltaMove = NextLocation - WindWalkDoublePullOwner.ActorLocation;
			FVector Velocity = MovementComponent.GetVelocity() + DeltaMove;
			Velocity = Velocity.ConstrainToPlane(DoublePullComponent.Spline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World));

			FQuat Rotation;
			if(IsCloseToStartingPoint())
			{
				FVector RotationDirection = DoublePullComponent.Spline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				Rotation = Math::MakeQuatFromX(RotationDirection);
			}
			else
			{
				Rotation = Math::MakeQuatFromX(-Velocity);
			}

			MovementComponent.SetTargetFacingRotation(Rotation, DeltaTime * 20.f);
			MoveData.ApplyTargetRotationDelta();

			MoveData.ApplyVelocity(Velocity.GetClampedToMaxSize(TerminalSpeed));
			CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);
		}

		MovementComponent.Move(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DoublePullComponent == nullptr || DoublePullComponent.Spline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(n"DoublePullForceGoBack"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Stop falling when reaching bottom
		if(WindWalkDoublePullOwner.bIsInStartZone)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WindWalkDoublePullOwner.UnblockCapabilities(n"DoublePullEffort", this);

		WindWalkDoublePullOwner.OnTumblingEnded.Broadcast();

		WindWalkDoublePullOwner.FullscreenPlayer.ClearIdealDistanceByInstigator(this);
		WindWalkDoublePullOwner.FullscreenPlayer.ClearPointOfInterestByInstigator(this);
	}

	bool IsCloseToStartingPoint() const
	{
		FVector SplineStart = DoublePullComponent.Spline.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World);
		return SplineStart.Distance(Owner.ActorLocation) < TerminalSpeed * 2.f;
	}

	float GetDistanceToClosestLocationInSpline(FVector ClosestLocationInSpline = FVector::ZeroVector)
	{
		FVector LocationInSpline = ClosestLocationInSpline;
		if(LocationInSpline.IsZero())
			LocationInSpline = DoublePullComponent.Spline.GetPositionClosestToWorldLocation(Owner.ActorLocation).WorldLocation;

		return LocationInSpline.Distance(Owner.ActorLocation);
	}
}