import Cake.LevelSpecific.SnowGlobe.Curling.CurlingObstacle;
enum EObstacleState
{
	Default,
	Raised,
	Lowering
};

class ACurlingObstacleHolder : AHazeActor
{
	EObstacleState ObstacleState;

	UPROPERTY(Category = "Capabilities")
	TSubclassOf<UHazeCapability> Capability;

	UPROPERTY(Category = "Setup")
	TArray<ACurlingObstacle> CurlingObstacleArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(Capability);
	}

	UFUNCTION()
	void ObstaclesRaise()
	{
		ObstacleState = EObstacleState::Raised;
	}

	UFUNCTION(NetFunction)
	void ObstaclesLower()
	{
		ObstacleState = EObstacleState::Lowering;
	}
}