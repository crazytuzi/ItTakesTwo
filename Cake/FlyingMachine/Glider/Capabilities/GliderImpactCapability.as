import Cake.FlyingMachine.Glider.FlyingMachineGlider;
import Cake.FlyingMachine.FlyingMachineOrientation;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineGliderImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Glider);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default CapabilityDebugCategory = FlyingMachineCategory::Glider;

	AFlyingMachineGlider Glider;
	UFlyingMachineGliderComponent GliderComp;

	// Minimum time between hits
	float HitCooldown = 0.f;

	FVector TranslateDirection;
	float TranslateDistance;

	FVector RotateAxis;
	float RotateAngles;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Glider = Cast<AFlyingMachineGlider>(Owner);
		GliderComp = UFlyingMachineGliderComponent::GetOrCreate(Glider);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GliderComp.Hits.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (TranslateDistance <= 0.f && RotateAngles <= 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	void ProcessHits()
	{
		FVector Forward = GliderComp.Rotation.Vector();

		// See if any of the hits are fatal enough
		for(FHitResult Result : GliderComp.Hits)
		{
			FVector HitLocation = Result.Location - Glider.ActorLocation;
			HitLocation.ConstrainToPlane(Forward);

			float HitDot = Result.Normal.DotProduct(-Forward);

			if (HasControl())
			{
				// Far away from center, we allow this if forward is clear..
				if (HitLocation.Size() > 500.f)
				{
					if (!IsForwardClear())
					{
						NetTriggerFatalImpact(Result);
						return;
					}
				}

				// Center-ish hit, was it head-on enough?
				else if (HitLocation.Size() > 200.f)
				{
					if (HitDot < -0.7f)
					{
						NetTriggerFatalImpact(Result);
						return;
					}
				}

				// Center on, just die
				else
				{
					NetTriggerFatalImpact(Result);
					return;
				}
			}

			GliderComp.OnImpact.Broadcast(Result, HitDot);

			// Calculate translation
			TranslateDirection = -HitLocation;
			TranslateDirection.Z = 0.f;
			TranslateDirection.Normalize();
			TranslateDistance = 1600.f;

			// Calculate rotation to look towards spline forward
			FVector SplineForward = GetClosestSplineForward();
			FQuat Rotation = FQuat::FindBetweenNormals(Forward, SplineForward);

			Rotation.ToAxisAndAngle(RotateAxis, RotateAngles);
			RotateAngles *= HitDot;

			Glider.CallOnImpactEvent(Result);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HitCooldown -= DeltaTime;
		if (HitCooldown < 0.f)
		{
			ProcessHits();
		}

		GliderComp.Hits.Empty();

		if (TranslateDistance < 0.f)
			return;

		/* Update translation */
		float DeltaDistance = TranslateDistance * 2.f * DeltaTime;
		Glider.AddActorWorldOffset(TranslateDirection * DeltaDistance);

		TranslateDistance -= DeltaDistance;

		/* Update rotation */
		float DeltaAngles = RotateAngles * 2.f * DeltaTime;
		FQuat DeltaRotation = FQuat(RotateAxis, DeltaAngles);

		FQuat Rotation = GliderComp.Rotation.Quaternion();
		Rotation = Rotation * DeltaRotation;
		GliderComp.Rotation = Rotation.Rotator();

		RotateAngles -= DeltaAngles;
	}

	FVector GetClosestSplineForward()
	{
		TArray<UHazeSplineComponent> Splines = GliderComp.FollowSplines;
		if (Splines.Num() == 0)
		{
			// No followed splines
			return FVector();
		}

		FVector Loc = Glider.ActorLocation;

		FVector ClosestForward;
		float ClosestDistance = BIG_NUMBER;

		for(int i=0; i<Splines.Num(); ++i)
		{
			FVector SplineLoc = Splines[i].FindLocationClosestToWorldLocation(Loc, ESplineCoordinateSpace::World);

			float Distance = (SplineLoc - Loc).SizeSquared();
			if (Distance < ClosestDistance)
			{
				ClosestForward = Splines[i].FindDirectionClosestToWorldLocation(Loc, ESplineCoordinateSpace::World);
				ClosestDistance = Distance;
			}
		}

		return ClosestForward;
	}

	UFUNCTION(NetFunction)
	void NetTriggerFatalImpact(FHitResult Hit)
	{
		Glider.CallOnFatalImpactEvent(Hit);
		GliderComp.OnFatalImpact.Broadcast();
	}

	bool IsForwardClear()
	{
		FHazeTraceParams Trace;
		Trace.InitWithPrimitiveComponent(Glider.Mesh);
		Trace.From = Glider.ActorLocation;
		Trace.To = Glider.ActorLocation + Glider.ActorForwardVector * 2000.f;
		Trace.SetToSphere(400.f);

		FHazeHitResult Hit;
		Trace.Trace(Hit);

		return Hit.bBlockingHit;
	}
}