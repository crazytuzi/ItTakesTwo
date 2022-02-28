import Cake.FlyingMachine.Glider.FlyingMachineGlider;
import Cake.FlyingMachine.FlyingMachineOrientation;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineGliderWindCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Glider);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default CapabilityDebugCategory = FlyingMachineCategory::Glider;

	AFlyingMachineGlider Glider;
	UFlyingMachineGliderComponent GliderComp;

	FHazeAcceleratedVector WindTargetLocation;
	FHazeAcceleratedFloat WindForce;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Glider = Cast<AFlyingMachineGlider>(Owner);
		GliderComp = UFlyingMachineGliderComponent::GetOrCreate(Glider);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GliderComp.FollowSplines.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GliderComp.FollowSplines.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Glider.GetActorLocation();

		float ClosestLen = BIG_NUMBER;
		FTransform ClosestTransform;

		FVector Forward = Owner.GetActorForwardVector();
		Forward.ConstrainToPlane(FVector::UpVector);
		Forward.Normalize();

		/* Collect wind forces from flying too far or turning too far away from a spline */
		float TargetWindForce = 0.f;

		// Get the closest spline to where we _predict_ we will be soon in the future
		FHazeSplineSystemPosition ClosestPosition;
		FVector PredictLocation = Loc + Forward * GliderComp.Speed;
		FVector PredictLocation_Constrained = PredictLocation.ConstrainToPlane(FVector::UpVector);

		for(int i=0; i<GliderComp.FollowSplines.Num(); ++i)
		{
			UHazeSplineComponent Spline = GliderComp.FollowSplines[i];
			FHazeSplineSystemPosition SplinePosition = Spline.GetPositionClosestToWorldLocation(PredictLocation);

			float LenSqrd = (PredictLocation - SplinePosition.WorldLocation).ConstrainToPlane(FVector::UpVector).SizeSquared();
			if (LenSqrd < ClosestLen)
			{
				ClosestPosition = SplinePosition;
				ClosestLen = LenSqrd;
			}
		}

		// Then if we're going away from it too far, apply wind
		float Len = FMath::Sqrt(ClosestLen);
		if (Len > 5000.f)
		{
			TargetWindForce += (Len - 5000.f) / 5000.f;
		}

		// Also if we're turning very far away from the spline angularily (its a word), then also apply heavy wind to force
		// the glider back into looking forwards
		{
			float Angle = Math::DotToDegrees(Forward.DotProduct(ClosestPosition.WorldForwardVector));
			if (Angle > 70.f)
			{
				TargetWindForce += (Angle - 70.f) / 20.f;
			}
		}

		// We dont want the forces to snap violently, especially when hopping from one spline to another, so accelerate all the values
		WindForce.AccelerateTo(TargetWindForce, 2.f, DeltaTime);

		// The target location is offset forwards on the spline
		ClosestPosition.Move(2000.f);
		FVector TargetLocation = ClosestPosition.WorldLocation;
		WindTargetLocation.AccelerateTo(TargetLocation, 2.f, DeltaTime);

		// --- Apply forces!
		if (WindForce.Value > 0.f)
		{
			FVector TargetDirection = (WindTargetLocation.Value - Loc).GetSafeNormal();
			FQuat ToTargetQuat = FQuat::FindBetweenNormals(Forward, TargetDirection);
			float Angle = 0.f;
			FVector Axis;
			ToTargetQuat.ToAxisAndAngle(Axis, Angle);

			FQuat DeltaRotation(Axis, Angle * 2.f * WindForce.Value * DeltaTime);

			FQuat Rotation = GliderComp.Rotation.Quaternion();
			Rotation = DeltaRotation * Rotation;
			GliderComp.Rotation = Rotation.Rotator();

			Glider.CallOnWindBlowEvent(TargetDirection, WindForce.Value);
			GliderComp.OnWindBlow.Broadcast(TargetDirection, WindForce.Value);
		}
	}
}