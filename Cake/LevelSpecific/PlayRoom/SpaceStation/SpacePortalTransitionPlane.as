UCLASS(Abstract)
class ASpacePortalTransitionPlane : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent TransitionPlane;

	UPROPERTY()
	float CurrentBrightness;
}