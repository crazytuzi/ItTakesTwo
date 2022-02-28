
/*
*	Spline Region system:
*	Region components need to be directly under SplineRegionContainer
*	RegionContainers need to be directly under a HazeSplineComponent.
*	On the RegionContainer you can specifiy types, those types will be added to the drop down menu.
*	You can manualy just add RegionComponents aswell as long as they are directly under a RegionContainer in the hierarchy it is fine.
*/

class UPlayerVisibilitySplineRegion : UHazeSplineRegionComponent
{

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(EnteringActor);
		if(Player == nullptr)
			return;

		Player.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionExit(AHazeActor ExitingActor, ERegionExitReason ExitReason)
	{
		auto Player = Cast<AHazePlayerCharacter>(ExitingActor);
		if(Player == nullptr)
			return;

		Player.SetActorHiddenInGame(false);
	}
}

// class AExampleSplineRegionActor : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	USceneComponent Root;

// 	UPROPERTY(DefaultComponent)
// 	UHazeSplineComponentBase Spline;
// 	default Spline.AddSplinePoint(FVector::ForwardVector * 300.f, ESplineCoordinateSpace::Local, true);

// 	// Note: the container needs to be attached to a spline.
// 	UPROPERTY(DefaultComponent, Attach = Spline)
// 	UHazeSplineRegionContainerComponent RegionContainer;
// 	// In the editor you can context click on the regionspline to add regions. The regions that show up is defined in RegisteredRegionTypes list.
// 	default RegionContainer.RegisteredRegionTypes.Add(UExampleSplineRegionComponent::StaticClass());

// 	// You can also just add a RegionCompnent manually regardless of registered types (make sure the Component is attached to the/a container).
// 	// Currently its not that useful doing it in AS since you can't edit the region location/size here.
// 	UPROPERTY(DefaultComponent, Attach = RegionContainer)
// 	UExampleSplineRegionComponent Region;
// }
