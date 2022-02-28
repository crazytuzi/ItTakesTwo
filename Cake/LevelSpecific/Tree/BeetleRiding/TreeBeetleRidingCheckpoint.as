import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineActor;
import Peanuts.Triggers.ActorTrigger;

class UTreeBeetleRidingCheckpointVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTreeBeetleRidingCheckpointVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		ATreeBeetleRidingCheckpoint Checkpoint = Cast<ATreeBeetleRidingCheckpoint>(Component.GetOwner());

		FVector LocationOnSpline = Checkpoint.Spline.GetLocationAtDistanceAlongSpline(Checkpoint.CheckpointDistance, ESplineCoordinateSpace::World);

		DrawDashedLine(Checkpoint.GetActorLocation(), LocationOnSpline, FLinearColor::Red, 20.f);
		DrawPoint(LocationOnSpline, FLinearColor::Red, 20.f);
	}
}

class UTreeBeetleRidingCheckpointVisualizerComponent : UActorComponent
{

}

class ATreeBeetleRidingCheckpoint : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UTreeBeetleRidingCheckpointVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.SetWorldScale3D(20.f);

	UPROPERTY()
	AConnectedHeightSplineActor ConnectedHeightSplineActor;

	UPROPERTY()
	AActorTrigger ActorTrigger;

	UConnectedHeightSplineComponent Spline;

	float CheckpointDistance = 0.f;

	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (ConnectedHeightSplineActor == nullptr)
			return;

		Spline = ConnectedHeightSplineActor.ConnectedHeightSplineComponent;

		CheckpointDistance = Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ActorTrigger != nullptr)
			ActorTrigger.OnActorEnter.AddUFunction(this, n"OnActorTriggered");

		Spline = ConnectedHeightSplineActor.ConnectedHeightSplineComponent;
		CheckpointDistance = Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
	}

	UFUNCTION()
	void OnActorTriggered(AHazeActor Actor)
	{
		/*
		ATreeBeetleRidingBeetle TreeBeetleRidingBeetle = Cast<ATreeBeetleRidingBeetle>(Actor);
		if (TreeBeetleRidingBeetle != nullptr)
		{

		}
		*/
	}

}