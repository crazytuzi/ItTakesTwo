
import Vino.LevelSpecific.Snowglobe.SnowGlobeMagnetRotatingComponent;
import Vino.LevelSpecific.Snowglobe.MagneticRotationSnapPointComponent;

class USnowGlobeMagnetSnappedRotatingComponent : USnowGlobeMagnetRotatingComponent
{
	TArray<UMagneticRotationSnapPointComponent> SnapPoints;

	USceneComponent SelfSnappingReferencePoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();

		// Get all snappint points from actor
		Owner.GetComponentsByClass(UMagneticRotationSnapPointComponent::StaticClass(), SnapPoints);

		// Find actual snapping point in actor; shitty but mäh
		TArray<USceneComponent> Children;
		GetChildrenComponents(true, Children);
		for(auto Child : Children)
		{
			if(Child.Name.ToString().Contains("RotationSnappingPoint"))
			{
				SelfSnappingReferencePoint = Child;
				break;
			}
		}
	}

	float CalculateMagnetAngularForce(UMagnetGenericComponent Magnet, FVector Force) override
	{
		float AngularForce = 0.f;
		float InfluenceScale = 1.f;

		// Go through snapping points in actor
		for(UMagneticRotationSnapPointComponent SnapPoint : SnapPoints)
		{
			FVector WorldRotationAxis = WorldTransform.TransformVector(LocalRotationAxis).GetSafeNormal();

			if(SnapPoint.ShouldInfluence(SelfSnappingReferencePoint, Force, WorldRotationAxis, InfluenceScale))
			{
				FVector MagnetOffset = (SnapPoint.WorldLocation - WorldLocation).ConstrainToPlane(WorldRotationAxis).GetSafeNormal();
				FVector ConstrainedMagnetToSnapPoint = (SnapPoint.WorldLocation - SelfSnappingReferencePoint.WorldLocation).ConstrainToPlane(WorldRotationAxis);
				if(ForceType == ESnowGlobeMagnetForceType::TwoDimensional)
					ConstrainedMagnetToSnapPoint.Normalize();

				// Calculate force from angle between magnet snap and force directions
				FVector RotationCross = MagnetOffset.CrossProduct(ConstrainedMagnetToSnapPoint);
				float Torque = RotationCross.DotProduct(WorldRotationAxis);

				// For one-dimensional, just take the sign of the force :) since we only care about backwards or forwards
				if (ForceType == ESnowGlobeMagnetForceType::OneDimensional)
					AngularForce = FMath::Sign(AngularForce);

				// Get snapping force; lower force the closer this is from the snapping point
				float TorqueMagnitude = SnapPoint.MagnetSnapForce * Time::GlobalWorldDeltaSeconds;
				TorqueMagnitude = TorqueMagnitude / FMath::Sqrt(TorqueMagnitude);

				// Lower force when player (or whatever) is not influencing magnet
				if(Force.IsZero())
					TorqueMagnitude *= 0.05f;

				// Add force and scale variables
				AngularForce += Torque * TorqueMagnitude * InfluenceScale;
				InfluenceScale *= (1.f - InfluenceScale);
			}
		}

		// Mix snapping point forces with regular calculation
		return Super::CalculateMagnetAngularForce(Magnet, Force) * InfluenceScale + AngularForce;
	}
}