import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Checkpoints.Checkpoint;
import Peanuts.Spline.SplineActor;
class AClockworkLastBossWalkTogetherManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	AHazeActor DirectionActor;

	UPROPERTY()
	ASplineActor CheckpointSpline;

	UPROPERTY()
	ACheckpoint ConnectedCheckpoint;

	float CheckpointDistLastTick = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CheckpointSpline == nullptr)
			return;

		if (ConnectedCheckpoint == nullptr)
			return;

		float Dist = CheckpointSpline.Spline.GetDistanceAlongSplineAtWorldLocation(GetActorInFirstPlace().ActorLocation);
		if (Dist < CheckpointDistLastTick)
			Dist = CheckpointDistLastTick;

		FVector CheckpointLoc = CheckpointSpline.Spline.GetLocationAtDistanceAlongSpline(Dist, ESplineCoordinateSpace::World);
		ConnectedCheckpoint.SetActorLocation(CheckpointLoc);

		CheckpointDistLastTick = Dist;
	}

	AHazePlayerCharacter GetActorInFirstPlace()
	{
		float Length = SMALL_NUMBER;
		int CurrentIndex = 0;
		TArray<AHazePlayerCharacter> PlayerArray;
		PlayerArray.Add(Game::GetMay());
		PlayerArray.Add(Game::GetCody());

		for (int i = 0; i < PlayerArray.Num(); i++)
		{
			if (PlayerArray[i].IsPlayerDead())
					return PlayerArray[i].OtherPlayer;
		}

		for (int i = 0; i < PlayerArray.Num(); i++)
		{
			FVector Dir = PlayerArray[i].GetActorLocation() - DirectionActor.GetActorLocation();
			float CurrentLength = Dir.DotProduct(DirectionActor.ActorForwardVector);
			if (CurrentLength > Length)
			{
				Length = CurrentLength;
				CurrentIndex = i;
			}
		}
		return PlayerArray[CurrentIndex];
	}

	float DistanceBetweenPlayers()
	{
		AHazePlayerCharacter FirstPlayer = GetActorInFirstPlace();
		FVector Dir = FirstPlayer.GetActorLocation() - FirstPlayer.OtherPlayer.GetActorLocation();
		return Dir.Size();
	}

	UFUNCTION()
	void UpdateCheckpointSpline(ASplineActor NewSpline)
	{
		CheckpointSpline = NewSpline;
		CheckpointDistLastTick = 0.f;
	}
}