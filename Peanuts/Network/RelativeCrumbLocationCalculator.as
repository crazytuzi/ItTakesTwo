
class URelativeCrumbLocationCalculator : UHazeReplicationLocationCalculator
{
	AHazeActor Owner = nullptr;
	USceneComponent RelativeComponent = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor InOwner, USceneComponent InRelativeComponent)
	{
		Owner = InOwner;
		RelativeComponent = InRelativeComponent;
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FHazeActorReplicationFinalized CurrentParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		if(RelativeComponent != nullptr)
		{
			OutTargetParams.Location = Owner.GetActorLocation();
			OutTargetParams.CustomLocation = OutTargetParams.Location - RelativeComponent.GetWorldLocation();
		}
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		if(RelativeComponent != nullptr)
		{
			const FVector RelativeLocation = RelativeComponent.GetWorldLocation();
			TargetParams.Location = RelativeLocation + TargetParams.CustomLocation;
		}

	}
}