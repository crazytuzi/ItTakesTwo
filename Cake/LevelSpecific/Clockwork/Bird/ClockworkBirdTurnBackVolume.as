class AClockworkBirdTurnBackVolume : AVolume
{
	default BrushComponent.CollisionProfileName = n"Trigger";

	UPROPERTY(DefaultComponent)
	UArrowComponent TurnBackDirection;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector Origin;
		FVector BoxExtent;
		float SphereRadius;
		System::GetComponentBounds(BrushComponent, Origin, BoxExtent, SphereRadius);

		TurnBackDirection.SetWorldLocation(Origin);
		TurnBackDirection.SetWorldScale3D(FVector(BoxExtent.AbsMin) * 0.01f);
	}

};