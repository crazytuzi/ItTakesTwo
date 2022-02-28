import Peanuts.Spline.SplineComponent;
class ASplinePlayerFollower : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Icon;

	UPROPERTY()
	AHazeSplineActor Spline;

	UHazeSplineComponent SplineComp;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(Spline);
	}

	UFUNCTION()
	void TrackPlayer(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}

	UFUNCTION()
	void StopTrackingPlayer()
	{
		Player = nullptr;
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick (float DeltaTime)
	{
		if (Player != nullptr)
		{
			FHazeSplineSystemPosition SplinePos = SplineComp.GetPositionClosestToWorldLocation(Player.ActorLocation, true);
			FVector DesiredPosition = SplinePos.WorldLocation + FVector::UpVector * 200;

			FVector Position = FMath::Lerp(GetActorLocation(), DesiredPosition, DeltaTime * 10);
			SetActorLocation(Position);
		}
	}
}