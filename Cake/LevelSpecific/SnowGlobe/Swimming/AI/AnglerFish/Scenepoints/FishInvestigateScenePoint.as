import Vino.AI.Scenepoints.ScenepointComponent;
import Vino.AI.Scenepoints.ScenepointActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;

class AFishInvestigateScenepoint : AScenepointActorBase
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UFishInvestigateScenepointComponent ScenepointComp;

	UFUNCTION()
	UScenepointComponent GetScenepoint()
	{
		return ScenepointComp;
	};
}

class UFishInvestigateScenepointComponent : UScenepointComponent
{
	default Radius = 100000.f;

	UFUNCTION()
	void TriggerInvestigation()
	{
		// Make every fish within radius curious about this scenepoint
		UHazeAITeam FishTeam = HazeAIBlueprintHelper::GetTeam(n"FishTeam");
		for (AHazeActor Fish : FishTeam.GetMembers())
		{
			if ((Fish != nullptr) && Fish.ActorLocation.IsNear(WorldLocation, Radius))
			{
				UFishBehaviourComponent BehaviourComp = UFishBehaviourComponent::Get(Fish);
				if (BehaviourComp != nullptr)
					BehaviourComp.Investigate(this);
			}
		}
	}
}

