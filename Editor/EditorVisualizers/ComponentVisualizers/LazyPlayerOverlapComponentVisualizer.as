class ULazePlayerOVerlapComponentVisualizer : UHazeScriptComponentVisualizer
{

    default VisualizedClass = UHazeLazyPlayerOverlapComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UHazeLazyPlayerOverlapComponent ShapeComp = Cast<UHazeLazyPlayerOverlapComponent>(Component);
		switch (ShapeComp.Shape.Type)
		{
			case EHazeShapeType::Capsule:
				DrawWireCapsule(ShapeComp.WorldLocation, ShapeComp.WorldRotation,
					FLinearColor::Green, ShapeComp.WorldScale.Y * ShapeComp.Shape.CapsuleRadius,
					ShapeComp.WorldScale.Z * ShapeComp.Shape.CapsuleHalfHeight, 12, 5.f);
			break;
			case EHazeShapeType::Box:
				DrawWireBox(
					ShapeComp.WorldLocation, (ShapeComp.WorldScale * ShapeComp.Shape.BoxExtends),
					ShapeComp.ComponentQuat, FLinearColor::Green, 5.f);
			break;
			case EHazeShapeType::Sphere:
				DrawWireSphere(
					ShapeComp.WorldLocation, ShapeComp.WorldScale.Max * ShapeComp.Shape.SphereRadius,
					FLinearColor::Green, 5.f);
			break;
		}
	}
};