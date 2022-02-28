import Vino.Movement.Swinging.SwingComponent;
import Rice.Debug.DebugStatics;

class USwingPointComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USwingPointComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        USwingPointComponent SwingPoint = Cast<USwingPointComponent>(Component);
        if (SwingPoint == nullptr)
            return;       

		DrawSwingPointArc(SwingPoint);

		TArray<AActor> Actors;
		Gameplay::GetAllActorsOfClass(AActor::StaticClass(), Actors);

		TArray<USwingPointComponent> SwingPointComponents;

		for (AActor Actor : Actors)
		{
			USwingPointComponent OtherSwingPointComponent = Cast<USwingPointComponent>(Actor.GetComponentByClass(USwingPointComponent::StaticClass()));

			if (OtherSwingPointComponent != nullptr)
				SwingPointComponents.Add(OtherSwingPointComponent);
		}

		for (USwingPointComponent OtherSwingPoint : SwingPointComponents)
		{
			if (SwingPoint == OtherSwingPoint)
				continue;

			const float SelectableDistance = SwingPoint.GetDistance(EHazeActivationPointDistanceType::Selectable) * 2;
			if ((SwingPoint.WorldLocation - OtherSwingPoint.WorldLocation).Size() > SelectableDistance)
				continue;

			DrawSwingPointArc(OtherSwingPoint);

			DrawLine(SwingPoint.WorldLocation, OtherSwingPoint.WorldLocation, FLinearColor::Green, 10.f);			
		}

    }
	void DrawSwingPointArc(USwingPointComponent SwingPoint, int NumberOfArcs = 4)
	{
		if(!ShouldDrawDebugLines(SwingPoint.Owner, 10000))
			return;
		float Segments = GetNumberOfSegmentsBasedOnDistance(SwingPoint.Owner, 10000, 3, 20);
		for (int Index = 0, Count = NumberOfArcs; Index < Count; ++Index)
		{
			FVector Normal = FVector::ForwardVector;
			float Angle = (180 / NumberOfArcs) * Index;
			Normal = Normal.RotateAngleAxis(Angle, FVector::UpVector);
			DrawArc(SwingPoint.WorldLocation, SwingPoint.SwingAngle * 2, SwingPoint.RopeLength, -SwingPoint.UpVector, FLinearColor::Red, 4.f, Normal, Segments, 0.f, true);	
		}
	}
}

