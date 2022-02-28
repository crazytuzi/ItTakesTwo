import Vino.AI.Scenepoints.ScenepointComponent;
import Vino.AI.Scenepoints.ScenepointActor;

class UFishRoamScenepointsTeam : UHAzeAITeam
{
	TArray<UFishRoamScenepointComponent> RoamScenepoints;
}

class AFishRoamScenepoint : AScenepointActorBase
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UFishRoamScenepointComponent RoamComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UFishRoamScenepointsTeam Team = Cast<UFishRoamScenepointsTeam>(JoinTeam(n"FishRoamScenepointsTeam", UFishRoamScenepointsTeam::StaticClass()));
		Team.RoamScenepoints.AddUnique(RoamComp);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		UFishRoamScenepointsTeam Team = Cast<UFishRoamScenepointsTeam>(GetJoinedTeam(n"FishRoamScenepointsTeam"));
		if (Team != nullptr)
			Team.RoamScenepoints.Remove(RoamComp);
	}

	UFUNCTION()
	UScenepointComponent GetScenepoint()
	{
		return RoamComp;
	};
}

class UFishRoamScenepointComponent : UScenepointComponent
{
	default Radius = 1000.f;
}

