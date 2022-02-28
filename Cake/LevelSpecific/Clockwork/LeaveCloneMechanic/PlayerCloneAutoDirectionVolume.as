
class APlayerCloneAutoDirectionVolume : AVolume
{
	default BrushComponent.CollisionProfileName = n"Trigger";

	UPROPERTY(DefaultComponent)
	UArrowComponent AutoDirection;

	// If the player is moving within this angle (degrees), force the direction
	UPROPERTY(Category = "Auto Direction")
	float MaximumAngle = 90.f;

	// Whether to normalize the impulse when teleporting here
	UPROPERTY(Category = "Normalize Impulse")
	bool bNormalizeImpulse = false;

	// Only normalize impulse if the player would launch from the clone at at least this speed
	UPROPERTY(Category = "Normalize Impulse", Meta = (EditCondition = "bNormalizeImpulse", EditConditionHides))
	float MinSpeedToNormalize = 0.f;

	// Normalized impulse to apply
	UPROPERTY(Category = "Normalize Impulse", Meta = (EditCondition = "bNormalizeImpulse", EditConditionHides))
	FVector NormalizedImpulse;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector Origin;
		FVector BoxExtent;
		float SphereRadius;
		System::GetComponentBounds(BrushComponent, Origin, BoxExtent, SphereRadius);

		AutoDirection.SetWorldLocation(Origin);
		AutoDirection.SetWorldScale3D(FVector(BoxExtent.AbsMin) * 0.01f);
	}
};