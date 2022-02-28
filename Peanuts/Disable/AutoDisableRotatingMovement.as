
/**
 * Helper to automatically disable tick on a rotating movement
 * component lazily without needing to convert to a hazeactor.
 */
class UAutoDisableRotatingMovementComponent : UActorComponent
{
	UPROPERTY(Category = "Disable")
	float DisableDistance = 8000.f;

	URotatingMovementComponent RotatingComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotatingComp = URotatingMovementComponent::Get(Owner);
		SetComponentTickEnabled(RotatingComp != nullptr);
		SetComponentTickInterval(FMath::RandRange(0.f, 1.f));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float MinDistSQ = FMath::Min(
			Game::Cody.GetSquaredDistanceTo(Owner),
			Game::May.GetSquaredDistanceTo(Owner)
		);

		if (MinDistSQ > FMath::Square(DisableDistance))
			RotatingComp.SetComponentTickEnabled(false);
		else
			RotatingComp.SetComponentTickEnabled(true);

		SetComponentTickInterval(1.f);
	}
};