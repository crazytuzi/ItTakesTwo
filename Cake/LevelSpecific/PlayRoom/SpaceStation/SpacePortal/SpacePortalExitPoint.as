class ASpacePortalExitPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent Direction;
	default Direction.ArrowSize = 3.f;

	float OffsetFromFloor = 672.965637;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Direction.SetRelativeLocation(FVector(0.f, 0.f, OffsetFromFloor));
	}
}