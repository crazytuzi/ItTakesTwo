import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

class UMagneticRotationSnapPointComponent : UPrimitiveComponent
{
	UPROPERTY()
	private float MagnetRange = 1000.f;

	UPROPERTY()
	float MagnetSnapForce = 200.f;

	bool ShouldInfluence(USceneComponent SnapPoint, FVector InfluencingForce, FVector WorldRotationAxis, float& OutInfluenceScale)
	{
		float Distance = SnapPoint.WorldLocation.Distance(WorldLocation);
		if(Distance > MagnetRange)
			return false;

		if(InfluencingForce.IsZero())
			return false;

		FVector SnapPointToActor = (Owner.ActorLocation - WorldLocation).ConstrainToPlane(WorldRotationAxis).GetSafeNormal();
		FVector ConstrainedForce = InfluencingForce.ConstrainToPlane(WorldRotationAxis).GetSafeNormal();

		float Dot = ConstrainedForce.DotProduct(SnapPointToActor);
		if(Dot < 0.8f)
			return false;

		OutInfluenceScale = FMath::Square(Math::Saturate(Dot - 0.8f));
		return true;
	}

	float GetMagnetRange() const
	{
		return MagnetRange;
	}
}

class USnowglobeMagnetSnappedRotatingComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMagneticRotationSnapPointComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UMagneticRotationSnapPointComponent SnapPoint = Cast<UMagneticRotationSnapPointComponent>(Component);
		if(SnapPoint == nullptr)
			return;

		DrawWireSphere(SnapPoint.WorldLocation, SnapPoint.GetMagnetRange(), FLinearColor::Purple, 5.f);
	}
}