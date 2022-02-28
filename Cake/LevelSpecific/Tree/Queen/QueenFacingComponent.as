class UQueenFacingComponent : USceneComponent
{
	float WorldZ;
	UPROPERTY()
	bool bDebugDraw;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WorldZ = GetWorldLocation().Z;
	}

	void UpdateRotation(FVector TailForwardVector, FVector TailPosition)
	{
		FVector Forward = TailForwardVector;
		Forward.Z = 0;

		SetWorldRotation(Forward.ToOrientationRotator());


		FVector Location = WorldLocation;
		Location.Z = WorldZ;
		Location.X = TailPosition.X;
		Location.Y = TailPosition.Y;
		SetWorldLocation(Location);

		// if (bDebugDraw)
		// 	System::DrawDebugArrow(WorldLocation, WorldLocation + ForwardVector * 1500, 500, FLinearColor::DPink);
	}
}