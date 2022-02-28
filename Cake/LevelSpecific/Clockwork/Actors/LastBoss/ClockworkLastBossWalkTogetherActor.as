import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossWalkTogetherManager;
class AClockworkLastBossWalkTogetherActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BackCollision;
	default BackCollision.BoxExtent = FVector(32.f, 2000.f, 1500.f);
	default BackCollision.CollisionProfileName = n"BlockAll";
	default BackCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent FrontCollision;
	default FrontCollision.BoxExtent = FVector(32.f, 2000.f, 1500.f);
	default FrontCollision.CollisionProfileName = n"BlockAll";
	default FrontCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	AHazeActor DirectionActor;

	UPROPERTY()
	AClockworkLastBossWalkTogetherManager Manager;

	AHazePlayerCharacter CurrentPlayerPastCollisionWalls;

	bool bShouldMove = false;

	FVector LocationToSet = FVector::ZeroVector;
	float LocationOffset = 0.f;

	FVector FrontStartingLoc;
	FVector BackStartingLoc;

	float BackXLastTick = BackStartingLoc.X;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LocationToSet = DirectionActor.GetActorLocation();

		FrontStartingLoc = FrontCollision.RelativeLocation;
		BackStartingLoc = BackCollision.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldMove)
			return;

		AHazePlayerCharacter LastPlayer = Manager.GetActorInFirstPlace().OtherPlayer;
		FVector Dir = LastPlayer.GetActorLocation() - DirectionActor.GetActorLocation();
		float Length = Dir.DotProduct(DirectionActor.GetActorForwardVector());
		if (Length > LocationOffset)
			LocationOffset = Length;
		
		SetBackCollisionLocation(LastPlayer);
		SetActorLocation(LocationToSet + (DirectionActor.ActorForwardVector * LocationOffset));
	}

	void SetBackCollisionLocation(AHazePlayerCharacter Player)
	{
		// If a player somehow gets behind the back collision (with May's teleport ability for example)
		// if that happens, we need to move the back collision behind that player. Then start going back to the back collisions original relative location
		float BackX = 0.f;
		FVector LastPlayerRelativeLoc = GetActorTransform().InverseTransformPosition(Player.ActorLocation);
		if (LastPlayerRelativeLoc.X > BackCollision.RelativeLocation.X)
			BackCollision.SetRelativeLocation(FVector(LastPlayerRelativeLoc.X + 100.f, BackCollision.RelativeLocation.Y, BackCollision.RelativeLocation.Z));
		else
		{
			BackX = LastPlayerRelativeLoc.X + 100.f;
			BackX = FMath::Max(BackX, BackStartingLoc.X);
			if (BackX > BackXLastTick)
				BackX = BackXLastTick;
			BackCollision.SetRelativeLocation(FVector(BackX, BackCollision.RelativeLocation.Y, BackCollision.RelativeLocation.Z));
		}

		BackXLastTick = BackCollision.RelativeLocation.X;
	}

	UFUNCTION()
	void SetWalkTogetherActorEnabled(bool bEnabled)
	{
		ECollisionEnabled Collision = bEnabled ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		bShouldMove = bEnabled; 
		BackCollision.SetCollisionEnabled(Collision);
		FrontCollision.SetCollisionEnabled(Collision);
	}
}