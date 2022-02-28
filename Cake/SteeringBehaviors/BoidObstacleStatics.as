import Cake.SteeringBehaviors.BoidObstacleComponent;
import Cake.SteeringBehaviors.BoidArea;

class UBoidObstacleContainerComponent : UActorComponent
{
	TArray<UBoidObstacleComponent> ListOfObstacles;
}

void RegisterBoidObstacle(UBoidObstacleComponent Obstacle)
{
	UBoidObstacleContainerComponent ObstacleContainer = BoidObstacleContainer;
	
	if(ObstacleContainer.ListOfObstacles.Num() == 0)
		Reset::RegisterPersistentComponent(ObstacleContainer);
	
	BoidObstacleContainer.ListOfObstacles.Add(Obstacle);
}

void UnregisterBoidObstacle(UBoidObstacleComponent Obstacle)
{
	UBoidObstacleContainerComponent ObstacleContainer = BoidObstacleContainer;
	bool bHadObstacles = ObstacleContainer.ListOfObstacles.Num() != 0;
	ObstacleContainer.ListOfObstacles.Remove(Obstacle);

	if (bHadObstacles && ObstacleContainer.ListOfObstacles.Num() == 0)
		Reset::UnregisterPersistentComponent(ObstacleContainer);
}

void GetBoidObstacles(TArray<UBoidObstacleComponent>& OutObstacles)
{
	OutObstacles = BoidObstacleContainer.ListOfObstacles;
}

bool IsPointOverlappingBoidObstacle(FVector Point)
{
	FVector Out;
	return IsPointOverlappingBoidObstacle(Point, Out);
}

bool IsPointOverlappingBoidObstacle(FVector Point, FVector& OutHitOrigin)
{
	OutHitOrigin = FVector::ZeroVector;
	UBoidObstacleContainerComponent ObstacleContainer = BoidObstacleContainer;

	for(UBoidObstacleComponent BoidObstacle : ObstacleContainer.ListOfObstacles)
	{
		if(BoidObstacle.IsPointOverlapping(Point))
		{
			OutHitOrigin = BoidObstacle.WorldLocation;
			return true;
		}
	}

	return false;
}

UBoidObstacleContainerComponent GetBoidObstacleContainer() property
{
	UBoidObstacleContainerComponent ObstacleContainer = UBoidObstacleContainerComponent::GetOrCreate(Game::GetMay());
	return ObstacleContainer;
}

ABoidArea FindClosestBoidArea(FVector Origin)
{
	TArray<AActor> ListOfAreas;
	Gameplay::GetAllActorsOfClass(ABoidArea::StaticClass(), ListOfAreas);

	AActor Closest = nullptr;
	float ClosestSq = Math::MaxFloat;
	for(AActor Area : ListOfAreas)
	{
		const float DistanceSq = Area.ActorLocation.DistSquared(Origin);
		if(DistanceSq < ClosestSq)
		{
			ClosestSq = DistanceSq;
			Closest = Area;
		}
	}

	ABoidArea BoidArea = Cast<ABoidArea>(Closest);

	if(BoidArea != nullptr)
	{
		Print("Found boid area: " + BoidArea.Name + ".");
	}
	else
	{
		Print("Unable to locate any BoidArea in this level.");
	}

	return BoidArea;
}
