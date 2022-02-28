
class UScenepointComponent : USceneComponent
{
	UPROPERTY()
	float Radius = 64.f;

	UFUNCTION()
	bool IsAt(AHazeActor Actor, float PredictTime = 0.f)
	{
		if (Actor.ActorLocation.DistSquared(WorldLocation) < FMath::Square(Radius))
			return true;

		if (PredictTime != 0.f) // Allow checking for overshoot with negative prediction time
		{
			FVector DeltaMove = Actor.GetActualVelocity() * PredictTime;
			FVector ToSP = WorldLocation - Actor.ActorLocation;
			if (ToSP.DotProduct(DeltaMove) > 0.f)
			{	
				// We're moving towards sp
				FVector PredictedToSP = (WorldLocation - (Actor.ActorLocation + DeltaMove));
				if (PredictedToSP.DotProduct(DeltaMove) < 0.f)	
				{
					// We will pass sp during predicted time
					return true;
				}
			}
		}

		return false;
	}
}

namespace ScenepointStatics 
{
	UScenepointComponent GetRandom(const TArray<UScenepointComponent>& Scenepoints)
	{
		if (Scenepoints.Num() == 0)
			return nullptr;

		int i = FMath::RandRange(0, Scenepoints.Num() - 1);
		return Scenepoints[i];
	}

	UScenepointComponent GetRandomInView(const TArray<UScenepointComponent>& Scenepoints)
	{
		AHazePlayerCharacter Cody = Game::GetCody();
		AHazePlayerCharacter May = Game::GetMay();
		if ((Cody != nullptr) && (May != nullptr))
		{
			// Get random point in any players view
			TArray<UScenepointComponent> OnScreenPoints;
			for (UScenepointComponent Scenepoint : Scenepoints)
			{
				if (Scenepoint == nullptr)
					continue;

				FVector Loc = Scenepoint.GetWorldLocation();
				if (SceneView::IsInView(Cody, Loc) || SceneView::IsInView(May, Loc))
					OnScreenPoints.Add(Scenepoint);
			}
			if (OnScreenPoints.Num() > 0)
				return GetRandom(OnScreenPoints);
		}
		return nullptr;
	}	

}

struct FScenepointContainer
{
	TArray<UScenepointComponent> Scenepoints;
	private TArray<UScenepointComponent> UnusedScenepoints;
	private UScenepointComponent LastUsedScenepoint = nullptr;

	void Reset()
	{
		UnusedScenepoints.Empty();
		LastUsedScenepoint = nullptr;
	}

	void UpdateUsedScenepoints()
	{
		if (UnusedScenepoints.Num() == 0)
		{
			UnusedScenepoints = Scenepoints; 
			if (UnusedScenepoints.Num() > 1)
				UnusedScenepoints.Remove(LastUsedScenepoint);
		}
	}
	void MarkScenepointUsed(UScenepointComponent Scenepoint)
	{
		UnusedScenepoints.Remove(Scenepoint);
		LastUsedScenepoint = Scenepoint;
	}

	UScenepointComponent UseBestScenepoint()
	{
		UpdateUsedScenepoints();
		UScenepointComponent Scenepoint = ScenepointStatics::GetRandomInView(UnusedScenepoints);
		if (Scenepoint == nullptr)
			Scenepoint = ScenepointStatics::GetRandom(UnusedScenepoints);
		MarkScenepointUsed(Scenepoint);
		return Scenepoint;
	}	

	UScenepointComponent UseRandomScenepoint()
	{
		UpdateUsedScenepoints();
		UScenepointComponent Scenepoint = ScenepointStatics::GetRandom(UnusedScenepoints);
		MarkScenepointUsed(Scenepoint);
		return Scenepoint;
	}
}
