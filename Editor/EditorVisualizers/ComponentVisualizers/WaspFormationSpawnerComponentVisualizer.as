import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspFormationSpawner;
import Cake.LevelSpecific.Tree.Wasps.Scenepoints.WaspFormationScenepoint;

class UWaspFormationSpawnerComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UWaspSpawnerDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UWaspSpawnerDummyComponent Comp = Cast<UWaspSpawnerDummyComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		AWaspEnemySpawner Spawner = Cast<AWaspEnemySpawner>(Comp.Owner);
		if (Spawner != nullptr)
		{
			for(AScenepointActorBase EntrySp : Spawner.EntryScenepoints)
			{
				if (EntrySp != nullptr)
					DrawDashedLine(Spawner.ActorLocation, EntrySp.ActorLocation, FLinearColor::LucBlue, 50);
			}

			for (ASplineActor EntrySpline : Spawner.EntrySplinePaths)
			{
				if (EntrySpline != nullptr)
					DrawDashedLine(Spawner.ActorLocation, EntrySpline.ActorLocation, FLinearColor::LucBlue, 50);
			}
		}		

		AWaspFormationSpawner FormationSpawner = Cast<AWaspFormationSpawner>(Comp.Owner);
		if (FormationSpawner != nullptr)
		{
			for(AWaspFormationScenepoint Scenepoint : FormationSpawner.FormationPoints)
			{
				if (Scenepoint != nullptr)
					DrawDashedLine(Comp.Owner.ActorLocation, Scenepoint.ActorLocation, FLinearColor::LucBlue, 50);
			}
		}		
	}
}