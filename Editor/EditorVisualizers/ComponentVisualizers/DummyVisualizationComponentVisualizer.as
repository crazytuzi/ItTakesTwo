import Peanuts.Visualization.DummyVisualizationComponent;

class UDummyVisualizationComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDummyVisualizationComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UDummyVisualizationComponent Comp = Cast<UDummyVisualizationComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		FVector Origin; 
		if (Comp.ConnectionBase != nullptr) 
			Origin = Comp.ConnectionBase.WorldTransform.TransformPosition(Comp.ConnectionBaseOffset); 
		else
			Origin = Comp.Owner.ActorTransform.TransformPosition(Comp.ConnectionBaseOffset);

		for (AActor ConnectedActor : Comp.ConnectedActors)
		{
			if (ConnectedActor != nullptr)
				DrawDashedLine(Origin, ConnectedActor.ActorLocation, Comp.Color, Comp.DashSize);
		}
		FTransform OwnerTransform = Comp.Owner.ActorTransform;
		for (const FVector& Loc : Comp.ConnectedLocalLocations)
		{
			DrawDashedLine(Origin, OwnerTransform.TransformPosition(Loc), Comp.Color, Comp.DashSize);
		}
    }   
} 

