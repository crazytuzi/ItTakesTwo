import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledTunnelMovementCapabilityBase : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	ABoatsled Boatsled;
	UHazeSplineComponent TrackSpline;

	TArray<AActor> TunnelBaseTraceIgnores;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		Boatsled = BoatsledComponent.Boatsled;
		TrackSpline = BoatsledComponent.TrackSpline;

		// Initialize trace ignore list
		TunnelBaseTraceIgnores.Add(PlayerOwner);
		TunnelBaseTraceIgnores.Add(PlayerOwner.OtherPlayer);
		TunnelBaseTraceIgnores.Add(Boatsled);
		TunnelBaseTraceIgnores.Add(Boatsled.OtherBoatsled);
	}

	void OffsetBoatsledMeshRotation(const FVector& Velocity, const FVector& GroundNormal, const FVector& SplineUpVector, float DistanceAlongSpline)
	{
		// Track spline can be null for a frame before transitioning to a new movement type
		if(BoatsledComponent.TrackSpline == nullptr)
			return;

		FVector BoatsledUpVector;

		float OffsetRotationTime = 0.02f;

		// If boatsled is mid-air, just use spline's up vector
		if(GroundNormal.IsNearlyZero())
		{
			OffsetRotationTime = 0.5f;
			BoatsledUpVector = SplineUpVector;
		}
		// Boatsled is grounded, get rotation from current location in tunnel
		else
		{
			// Get vector from boatsled to tunnel radius and normalize
			FVector TunnelCentre = GetTunnelCentre(SplineUpVector, DistanceAlongSpline);
			BoatsledUpVector = (TunnelCentre - Boatsled.ActorLocation).GetSafeNormal();
		}

		// Offset mesh rotation
		FQuat Rotation = Math::MakeQuatFromXZ(Velocity, BoatsledUpVector);
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(Rotation.Rotator(), OffsetRotationTime);
	}

	FVector GetTunnelCentre(const FVector& SplineUpVector, float DistanceAlongSpline)
	{
		// Get tunnel radius
		FVector LocationOnSpline = BoatsledComponent.TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector TunnelMeshBase = GetTunnelSplineMeshBase(LocationOnSpline, SplineUpVector);
		float TunnelRadius = BoatsledComponent.GetTunnelRadius(TunnelMeshBase, SplineUpVector);

		// Get vector from boatsled to tunnel radius and normalize
		return TunnelMeshBase + SplineUpVector * TunnelRadius;
	}

	FVector GetTunnelSplineMeshBase(const FVector& LocationOnSpline, const FVector& SplineUpVector)
	{
		TArray<FHitResult> HitResults;

		FVector BoatsledToLocationOnSpline = LocationOnSpline - Boatsled.ActorLocation;
		FVector TraceStart = Boatsled.ActorLocation + Boatsled.MeshComponent.UpVector * 300.f;
		FVector TraceEnd = Boatsled.ActorLocation + BoatsledToLocationOnSpline * 1.5f;

		System::LineTraceMulti(TraceStart, TraceEnd, ETraceTypeQuery::TraceTypeQuery1, false, TunnelBaseTraceIgnores, EDrawDebugTrace::None, HitResults, true);
		for(FHitResult HitResult : HitResults)
		{
			if(!HitResult.bBlockingHit)
				continue;

			if(HitResult.Actor != TrackSpline.Owner)
				continue;

			return HitResult.ImpactPoint;
		}

		return LocationOnSpline;
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
}