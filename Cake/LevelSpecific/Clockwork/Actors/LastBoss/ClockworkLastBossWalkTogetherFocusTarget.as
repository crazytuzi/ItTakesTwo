import Vino.Movement.Components.MovementComponent;
class AClockworkLastBossWalkTogetherFocusTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	bool bFollowCody = false;

	AHazePlayerCharacter PlayerToFollow;

	UHazeMovementComponent MoveComp;
	
	FVector Loc;

	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bFollowCody)
			PlayerToFollow = Game::GetCody();
		else	
			PlayerToFollow = Game::GetMay();

		MoveComp = UHazeMovementComponent::Get(PlayerToFollow);
		Loc = PlayerToFollow.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bIsActive)
			return;

		if (!MoveComp.IsAirborne())
			Loc = PlayerToFollow.ActorLocation;
		else
		{
			Loc.X = PlayerToFollow.ActorLocation.X;
			Loc.Y = PlayerToFollow.ActorLocation.Y;
		}

		SetActorLocation(Loc);
	}

	UFUNCTION()
	void SetWalkTogetherFocusTargetActive(bool bNewActive)
	{
		bIsActive = bNewActive;
		Loc = PlayerToFollow.ActorLocation;
	}
}