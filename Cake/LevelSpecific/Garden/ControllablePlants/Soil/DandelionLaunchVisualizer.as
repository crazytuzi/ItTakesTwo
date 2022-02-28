import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionLaunchComponent;

#if EDITOR

class UDandelionVisualizerComponent : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDandelionLaunchComponent::StaticClass();
	
	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UDandelionLaunchComponent Comp = Cast<UDandelionLaunchComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		const FVector StartLoc = Comp.Owner.ActorLocation;

		DrawArrow(StartLoc, StartLoc + FVector::UpVector * Comp.LaunchHeight, FLinearColor::Red, 10.0f, 20.0f);
    }
}

#endif // EDITOR
