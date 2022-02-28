import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseComponent;

class ADerbyHorseSplineTrack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000.f;

	UPROPERTY(Category = "Settings")
	float RaceLength = 4000.f;

	UPROPERTY(Category = "Settings")
	float ObstacleSpawnDistance = 1000.f;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget), Category = "Setup")
	FTransform DefaultPosition;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget), Category = "Setup")
	FTransform PlayPosition;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget), Category = "Setup")
	FTransform GoalPosition;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget), Category = "Setup")
	FTransform ObstacleSpawnPosition;

	UPROPERTY(NotEditable, meta = (MakeEditWidget))
	FVector MiddlePosition;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		GoalPosition.Location = FVector(PlayPosition.Location.X + RaceLength, PlayPosition.Location.Y, PlayPosition.Location.Z);
		FVector MidLocation = PlayPosition.Location - GoalPosition.Location;
		MiddlePosition = FVector(PlayPosition.Location.X -(MidLocation.X / 2), PlayPosition.Location.Y, PlayPosition.Location.Z);

		FVector SpawnLocation = FVector(GoalPosition.Location.X + ObstacleSpawnDistance, GoalPosition.Location.Y, GoalPosition.Location.Z);
		FVector SpawnWorldLoc = Root.RelativeTransform.TransformPosition(SpawnLocation);
		float SpawnDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(SpawnWorldLoc);
		if(SpawnDistance >= SplineComp.SplineLength)
		{
			SpawnLocation = SplineComp.GetLocationAtDistanceAlongSpline(SplineComp.SplineLength, ESplineCoordinateSpace::Local);
		}
		ObstacleSpawnPosition.Location = SpawnLocation;
	}

	FVector GetWorldLocationAtStatePosition(EDerbyHorseState State)
	{
		float Distance = GetSplineDistanceAtGamePosition(State);
		FVector Location;
		Location = SplineComp.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		return Location;
	}

	FVector GetWorldLocationAtDistance(float Distance)
	{
		FVector Location;
		Location = SplineComp.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		return Location;
	}

	//Get Spline distance att Minigame Enum Position
	float GetSplineDistanceAtGamePosition(EDerbyHorseState State)
	{
		FVector TargetPosition;

		switch(State)
		{
			case(EDerbyHorseState::AwaitingStart):
				TargetPosition = Root.RelativeTransform.TransformPosition(PlayPosition.Location);
				break;
			case(EDerbyHorseState::Inactive):
				TargetPosition = Root.RelativeTransform.TransformPosition(DefaultPosition.Location);
				break;
			case(EDerbyHorseState::GameActive):
				TargetPosition = Root.RelativeTransform.TransformPosition(GoalPosition.Location);
				break;
			default:
				TargetPosition = Root.WorldLocation;
				break;
		}
		return CalculateDistanceAtLocation(TargetPosition);
	}

	FVector GetWorldLocationAtObstacleSpawn()
	{
		FVector SpawnPosition = Root.RelativeTransform.TransformPosition(ObstacleSpawnPosition.Location);
		return SpawnPosition;
	}

	float CalculateDistanceAtLocation(FVector TargetPosition)
	{
		float SplineDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(TargetPosition);
		return SplineDistance;
	}
}