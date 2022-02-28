import Cake.SteeringBehaviors.BoidShapeComponent;

#if EDITOR

class UBoidObstacleComponentVisualizer : UBoidObstacleShapeVisualizer
{
    default VisualizedClass = UBoidShapeComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UBoidShapeComponent Comp = Cast<UBoidShapeComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			return;

		DrawBoidShape(Comp);

		if(!Comp.bUseVirtualFloor)
			return;

		const FLinearColor VirtualFloorColor = Comp.VirtualFloorColor;
		const float BoxSize = Comp.Radius * 1.4f;
		const float BoxHeight = 10.0f;
		const FVector BoxExtents(BoxSize, BoxSize, BoxHeight);
		const FVector VirtualFloorLoc = Comp.VirtualFloorLocation;
		DrawWireBox(VirtualFloorLoc, BoxExtents, FQuat::Identity, VirtualFloorColor, 10.0f);

		const int NumLines = Comp.VirtualFloorNumLines;
		const float SpaceBetweenLines = BoxSize / float(NumLines);
		const float BoxSizeHalf = BoxSize * 0.5f;

		for(int i = 1; i < (NumLines * 2); ++i)
		{
			const float X = (-BoxSize) + (i * SpaceBetweenLines);
			const FVector Start = VirtualFloorLoc + FVector(X, BoxSize, 0);
			const FVector End = VirtualFloorLoc + FVector(X, -BoxSize, 0);
			DrawLine(Start, End, VirtualFloorColor, 10);
		}

		DrawWireSphere(Comp.ShapeCenterLocation, 200.0f, FLinearColor::LucBlue, 10);
	}
}

// Can be used by other visualizers to draw the same information
UCLASS(Abstract)
class UBoidObstacleShapeVisualizer : UHazeScriptComponentVisualizer
{
	protected void DrawBoidShape(UBoidShapeComponent BoidShape)
	{
		if(BoidShape.Shape == EBoidObstacleShape::Sphere)
			DrawWireSphere(BoidShape.WorldLocation, BoidShape.Radius, BoidShape.VisualizerColor, BoidShape.VisualizerThickness);
		else if(BoidShape.Shape == EBoidObstacleShape::Capsule)
			DrawWireCapsule(BoidShape.WorldLocation, FRotator::ZeroRotator, BoidShape.VisualizerColor, BoidShape.Radius, BoidShape.HalfHeight, 16, BoidShape.VisualizerThickness);
	}
}

#endif // EDITOR
