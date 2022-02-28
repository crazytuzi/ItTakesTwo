import Vino.Movement.Capabilities.Sliding.SlopeSlidingSplineComponent;
import Vino.Movement.Capabilities.Sliding.DummySlopeSlidingSplineVisualizerComponent;
import Rice.Props.PropBaseActor;


class SplineSlopeSlidingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = Root)
	USlopeSlidingSplineComponent MovementGuideSpline;

	// Create dummy component so we get a visualiser.
	UPROPERTY(DefaultComponent)
	UDummySlopeSlidingSplineVisualiserComponent DummyVisualiser;
	default DummyVisualiser.SplineToVisualise = MovementGuideSpline;

	UFUNCTION(CallInEditor)
	void UpdateMovementSpline()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		UHazeSplineComponent SplineOnChild = nullptr;
		for (AActor Child : AttachedActors)
		{
			APropBaseActor PropChild = Cast<APropBaseActor>(Child);
			
			SplineOnChild = UHazeSplineComponent::Get(PropChild);
			if (SplineOnChild != nullptr)
				break;
		}

		if (SplineOnChild != nullptr)
			MovementGuideSpline.CopyOtherSpline(SplineOnChild);
	}
}