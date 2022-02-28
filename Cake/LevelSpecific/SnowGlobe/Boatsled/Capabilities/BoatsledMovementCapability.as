import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSettings;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledMovementReplicationPrediction;

class UBoatsledMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledMovement);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 63;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	ABoatsled Boatsled;
	USkeletalMeshComponent BoatsledMesh;
	UHazeSplineComponent TrackSpline;

	const float Uks = 0.4f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsSleddingOnHalfPipe())
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(BoatsledTags::BoatsledBigAir))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(BoatsledTags::BoatsledTunnelEndAlignment))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		// Initialize variables
		Boatsled = BoatsledComponent.Boatsled;
		BoatsledMesh = USkeletalMeshComponent::Get(Boatsled);
		TrackSpline = BoatsledComponent.TrackSpline;

		// Initialize forward direction to match Boatsled's forward vector
		BoatsledComponent.NetBoatsledForwardRotation.Value = Boatsled.MeshComponent.ForwardVector;

		// Add UBoatsledMovementReplicationPrediction as custom crumbs world calculator and enable custom params
		Boatsled.CrumbComponent.MakeCrumbsUseCustomWorldCalculator(UBoatsledMovementReplicationPrediction::StaticClass(), this);
		Boatsled.CrumbComponent.IncludeCustomParamsInActorReplication(Boatsled.MovementComponent.Velocity, Boatsled.MeshComponent.WorldRotation, this, false);

		if(HasControl())
			if(!ensure(Boatsled.SphereCollider.CollisionProfileName != n"NoCollision"))
				BoatsledComponent.SetBoatsledCollisionEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Boatsled.MovementComponent.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(n"BoatsledMovement");
		MoveData.OverrideStepUpHeight(5.f);
		MoveData.OverrideStepDownHeight(100.f);
		MoveData.OverrideCollisionWorldUp(Boatsled.MeshComponent.UpVector);

		// Get ground normal
		FVector GroundNormal;
		bool bIsGrounded = BoatsledComponent.GetGroundNormal(GroundNormal);

		if(HasControl())
		{
			FVector Velocity = Boatsled.MovementComponent.GetVelocity();

			// Get stuff!
			bool bNeedsRubberBanding = BoatsledComponent.NeedsRubberBanding();

			FVector SplineVelocity = BoatsledComponent.GetSplineVelocity();
			FVector SlopeVector = BoatsledComponent.GetSlopeDirection(GroundNormal);
			FVector SlopeVelocity = BoatsledComponent.GetSlopeVelocity(GroundNormal);

			float Slope = FMath::Abs(SlopeVelocity.GetSafeNormal().DotProduct(-PlayerOwner.MovementWorldUp));
			float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.GetActorLocation());
			FVector SplineUpVector = TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

			float HorizontalInput = 0.f;
			if(!IsActioning(BoatsledTags::BoatsledInputBlock))
				HorizontalInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X;

			// Push down on sled if not grounded- this can happen when colliding very fast with a wall
			if(!bIsGrounded)
			{
				Print("Boatsled: Me is not grounded! Pushing d0wnw4rds");
				MoveData.OverrideCollisionWorldUp(PlayerOwner.MovementWorldUp);
				Velocity += (TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) - Boatsled.ActorLocation);
				GroundNormal = SplineUpVector;
			}

			// Add spline velocity
			Velocity += SplineVelocity * DeltaTime;

			// Get input relative to absolute right at spline point; add spline vector to reduce horizontal amount
			// Reduce input if boatsled is already moving in that general direction
			// Finally, rotate velocity towards input vector
			FVector InputVector = (BoatsledComponent.GetSplineRightVectorAdjustedToBoatsled() * HorizontalInput) + BoatsledComponent.GetSplineVector();
			float InputMultiplier = 1.5f - Velocity.GetSafeNormal().DotProduct(InputVector.GetSafeNormal());
			Velocity = Math::RotateVectorTowards(Velocity, InputVector, DeltaTime * Boatsled.SteerSpeed * InputMultiplier);

			// Add slope velocity
			float SlopeMultiplier = 1.2f - Velocity.GetSafeNormal().DotProduct(InputVector);
			Velocity = Math::RotateVectorTowards(Velocity, SlopeVector, DeltaTime * Boatsled.SteerSpeed * SlopeMultiplier);

			// Add friction to das mixen, ja; reduce it when we're using turbo
			float FrameUks = BoatsledComponent.IsBoosting() ? 0.05f : Uks;
			FVector Friction = -Velocity.GetSafeNormal() * FrameUks * BoatsledComponent.BoatsledWeight * (FrameUks + 1.f - Velocity.GetSafeNormal().DotProduct(BoatsledComponent.GetSlopeDirection(GroundNormal)));
			Velocity += Friction * DeltaTime;

			// Check for side collisions
			bool bColliding;
			FVector CollisionLocation, CollisionNormal;
			if(bColliding = BoatsledComponent.IsCollidingWithBarrier(CollisionLocation, CollisionNormal))
			{
				// Notify of collision
				float CollisionForce = Velocity.ConstrainToDirection(CollisionNormal).Size() / BoatsledComponent.GetBoatsledMaxSpeed(bNeedsRubberBanding);
				BoatsledComponent.BoatsledHitBarrier(CollisionLocation, CollisionNormal, CollisionForce);

				// Rotate current frame's velocity toward impact normal
				Velocity = Math::SlerpVectorTowards(Velocity, CollisionNormal, DeltaTime);

				// Reduce velocity a bit based on how much of it is pointing towards spline forward vector
				Velocity -= SplineVelocity.GetSafeNormal() * Velocity.GetSafeNormal().DotProduct(SplineVelocity.GetSafeNormal()) * Velocity.Size() * 0.6f * DeltaTime;

				//PlayerOwner.SetCapabilityAttributeValue(n"BoatSledImpactAudio", CollisionForce);
			}

			// Handle player collision with other boatsled
			bColliding = bColliding || BoatsledComponent.HandleCollisionWithOtherBoatsled(Velocity, DeltaTime);

			// Change mesh offset vector to reflect collision
			// Eman TODO: Get animation or make this fancier
			if(bColliding)
			 	InputVector = BoatsledComponent.GetSplineVector();

			// Tick boatsled offset rotation based on input- and ground normal vectors
			BoatsledComponent.UpdateNetBoatsledForwardRotation(InputVector, GroundNormal, 2.f, DeltaTime);

			// Push down on boatsled
			Velocity -= Boatsled.MovementWorldUp * Boatsled.MovementComponent.GravityMagnitude * DeltaTime * (bIsGrounded ? 1.f : 4.f);

			// Handle rubber banding
			if(bIsGrounded && bNeedsRubberBanding)
				Velocity *= Boatsled.RubberbandBoostMultiplier;

			// Clamp velocity
			Velocity = Velocity.GetClampedToMaxSize(BoatsledComponent.GetBoatsledMaxSpeed(bNeedsRubberBanding));

			// Rotate boatsled actor to face velocity
			Boatsled.MovementComponent.SetTargetFacingDirection(Velocity.GetSafeNormal());
			MoveData.ApplyTargetRotationDelta();

			// Apply velocity and move
			MoveData.ApplyVelocity(Velocity);
			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Play them rumbles
			BoatsledComponent.PlaySleddingForceFeedback(bColliding ? 10.f : 1.f);
		}
		else
		{
			BoatsledComponent.ConsumeMovementCrumb(MoveData, DeltaTime);
			Boatsled.MovementComponent.Move(MoveData);
		}

		// Rotate boatsled mesh offset
		BoatsledComponent.RotateBoatsledMeshOffsetToSlope(BoatsledComponent.NetBoatsledForwardRotation.Value, GroundNormal);

		// Request locomotion
		BoatsledComponent.RequestPlayerBoatsledLocomotion();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsSleddingOnHalfPipe())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BoatsledComponent.IsJumping())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Cleanup
		Boatsled = nullptr;
		TrackSpline = nullptr;

		// Remove custom world calculator
		BoatsledComponent.Boatsled.CrumbComponent.RemoveCustomWorldCalculator(this);
		BoatsledComponent.Boatsled.CrumbComponent.RemoveCustomParamsFromActorReplication(this);
	}

	FVector GetTrackForwardVectorAtLocation(FVector WorldLocation)
	{
		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(WorldLocation);
		return TrackSpline.GetRightVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).CrossProduct(TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World)).GetSafeNormal();
	}

	bool TraceSides(FVector& OutRightVector)
	{
		TArray<AActor> IgnoredActors;
		IgnoredActors.Add(PlayerOwner);
		IgnoredActors.Add(PlayerOwner.OtherPlayer);
		IgnoredActors.Add(Boatsled);

		FHitResult HitResult;

		FVector TraceOrigin = Boatsled.GetActorLocation() + Boatsled.MeshComponent.UpVector * 300.f;
		bool TrackHit = true;

		float DirectionMultiplier = 1.f;
		for(int i = 0; i < 2; i++)
		{
			FVector TraceVector = FQuat(Boatsled.MeshComponent.GetForwardVector(), FMath::DegreesToRadians(-45.f * DirectionMultiplier)) * Boatsled.MeshComponent.GetRightVector() * DirectionMultiplier;
			System::LineTraceSingle(TraceOrigin, TraceOrigin + TraceVector * 1000.f, ETraceTypeQuery::TraceTypeQuery2, false, IgnoredActors, EDrawDebugTrace::None, HitResult, true);

			if(HitResult.Actor == nullptr)
			{
				OutRightVector = Boatsled.MeshComponent.GetRightVector() * DirectionMultiplier;
				return false;
			}

			DirectionMultiplier *= -1.f;
			// TrackHit = TrackHit && HitResult.Actor != nullptr;
		}

		// return TrackHit;
		return true;
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);
	}

	void DebugDrawArrowTowards(FVector Direction, FLinearColor Color, float Duration = 0.f)
	{
		System::DrawDebugArrow(Boatsled.ActorLocation + Boatsled.MeshComponent.UpVector * 200.f, Boatsled.ActorLocation + Boatsled.MeshComponent.UpVector * 200.f + Direction, 100, Color, Duration);
	}
}