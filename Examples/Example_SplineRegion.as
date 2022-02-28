
/*
*	Spline Region system:
*	Region components need to be directly under SplineRegionContainer
*	RegionContainers need to be directly under a HazeSplineComponent.
*	On the RegionContainer you can specifiy types, those types will be added to the drop down menu.
*	You can manualy just add RegionComponents aswell as long as they are directly under a RegionContainer in the hierarchy it is fine.
*/

class UExampleSplineRegionComponent : UHazeSplineRegionComponent
{


	// Called the first time the region is created.
	// Useful for setting default data dependant on the regions initial state.
	UFUNCTION(BlueprintOverride)
	void OnRegionInitialized()
	{
	}

	// Override the color that is used to visualize the region in the editor.
	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Teal;
	}

	/*
	*	The regions enter and exit functions are automaticly called when the SplineFollow component moves across it.
	*	Both should be called even if the move was fully across it during a single frame.
	*	If you have a system that you want to trigger it without using a followcomponent then please come talk to me (Simon Skogsrydh) and we'll look into it.
	*/
	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
	}
	UFUNCTION(BlueprintOverride)
	void OnRegionExit(AHazeActor ExitingActor, ERegionExitReason ExitReason)
	{
	}

	/*
	*	Regions will only tick when they are flagged to and they are active (an actor is within in the region).
	*/
	default bTicksWhenActive = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	}

	/*
		- Some Helper functions on this component-

		// Returs the start and end worldlocations of the region.
		FVector GetStartPointLocation() const;
		FVector GetEndPointLocation() const;

		// Returs the start and end worldrotation of the region.
		FQuat StartPointRotation() const;
		FQuat EndPointRotation() const;

		// Check if the distance is within the region.
		bool IsDistanceWithinRegion(float Distance) const;

		// Check if the region and range touch. Range start should always be the value to go from. If range end is lower than start it is assumed this is because it looped on the spline.
		bool DoesRangeOverapRegion(float RangeStart, float RangeEnd) const;
		
		// Find the closest distance on the spline from the worldlocation and checks if that is inside the region.
		bool IsWorldLocationWithinRegion(FVector WorldLocation) const;

		// Only checks if the actor has had its location updated to be inside the region.
		bool IsActorWithinRegion(AHazeActor* Actor) const;
	*/
}

class AExampleSplineRegionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponentBase Spline;
	default Spline.AddSplinePoint(FVector::ForwardVector * 300.f, ESplineCoordinateSpace::Local, true);

	// Note: the container needs to be attached to a spline.
	UPROPERTY(DefaultComponent, Attach = Spline)
	UHazeSplineRegionContainerComponent RegionContainer;
	// In the editor you can context click on the regionspline to add regions. The regions that show up is defined in RegisteredRegionTypes list.
	default RegionContainer.RegisteredRegionTypes.Add(UExampleSplineRegionComponent::StaticClass());

	// You can also just add a RegionCompnent manually regardless of registered types (make sure the Component is attached to the/a container).
	// Currently its not that useful doing it in AS since you can't edit the region location/size here.
	UPROPERTY(DefaultComponent, Attach = RegionContainer)
	UExampleSplineRegionComponent Region;
}
