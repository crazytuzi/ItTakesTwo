import Vino.Movement.Grinding.GrindingCapabilityTags;
class UGrindingDisableJumpRegionComponent : UHazeSplineRegionComponent
{

	// Override the color that is used to visualize the region in the editor.
	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Red;
	}

	/*
	*	The regions enter and exit functions are automaticly called when the SplineFollow component moves across it.
	*	Both should be called even if the move was fully across it during a single frame.
	*	If you have a system that you want to trigger it without using a followcomponent then please come talk to me (Simon Skogsrydh) and we'll look into it.
	*/
	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(EnteringActor);

		if (Player != nullptr)
		{
			Player.BlockCapabilities(GrindingCapabilityTags::Jump, this);
		}
	}
	UFUNCTION(BlueprintOverride)
	void OnRegionExit(AHazeActor ExitingActor, ERegionExitReason ExitReason)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(ExitingActor);

		if (Player != nullptr)
		{
			Player.BlockCapabilities(GrindingCapabilityTags::Jump, this);
		}
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
