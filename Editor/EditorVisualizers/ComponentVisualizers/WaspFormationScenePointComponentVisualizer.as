import Cake.LevelSpecific.Tree.Wasps.Scenepoints.WaspFormationScenepoint;

class UWaspFormationScenepointComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UWaspFormationScenepointComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UWaspFormationScenepointComponent Comp = Cast<UWaspFormationScenepointComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		DrawLine(Comp.GetFormationSpawnLocation(), Comp.GetWorldLocation(), FLinearColor::Green, 3.f);
		DrawLine(Comp.GetWorldLocation(), Comp.GetFormationDestination(), FLinearColor::Red, 3.f);
		DrawLine(Comp.GetFormationDestination(), Comp.GetFormationFleeLocation(), FLinearColor::Yellow, 3.f);
	}
}