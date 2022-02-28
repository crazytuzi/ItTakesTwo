import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class AClockworkSpikeWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Wall01;

	UPROPERTY(DefaultComponent, Attach = Wall01)
	UBoxComponent DeathCollision01;
	default DeathCollision01.RelativeLocation = FVector(400.f, -90.f, -800.f);
	default DeathCollision01.BoxExtent = FVector(450.f, 30.f, 840.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Wall02;

	UPROPERTY(DefaultComponent, Attach = Wall02)
	UBoxComponent DeathCollision02;
	default DeathCollision02.RelativeLocation = FVector(400.f, -90.f, -800.f);
	default DeathCollision02.BoxExtent = FVector(450.f, 30.f, 840.f);

	UPROPERTY()
	FHazeTimeLike MoveSpikesTimeline;
	default MoveSpikesTimeline.bLoop = true;
	default MoveSpikesTimeline.Duration = 2.f;

	UPROPERTY()
	float MoveAmount;

	UPROPERTY()
	float StartingLocationY;
	default StartingLocationY = 300.f;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	TArray<FVector> StartingLocation;
	TArray<FVector> TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveSpikesTimeline.BindUpdate(this, n"MoveSpikesTimelineUpdate");

		DeathCollision01.OnComponentBeginOverlap.AddUFunction(this, n"DeathCollisionOnBeginOverlap");
		DeathCollision02.OnComponentBeginOverlap.AddUFunction(this, n"DeathCollisionOnBeginOverlap");

		StartingLocation.Add(Wall01.RelativeLocation);
		StartingLocation.Add(Wall02.RelativeLocation);
		TargetLocation.Add(FVector(Wall01.RelativeLocation + FVector(0.f, 100.f, 0.f)));
		TargetLocation.Add(FVector(Wall02.RelativeLocation + FVector(0.f, -100.f, 0.f)));
		
		MoveSpikesTimeline.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Wall01.SetRelativeLocation(FVector(Wall01.RelativeLocation.X, -StartingLocationY, Wall01.RelativeLocation.Z));
		Wall02.SetRelativeLocation(FVector(Wall02.RelativeLocation.X, StartingLocationY, Wall02.RelativeLocation.Z));
	}

	UFUNCTION()
	void MoveSpikesTimelineUpdate(float CurrentValue)
	{
		Wall01.SetRelativeLocation(FMath::VLerp(StartingLocation[0], TargetLocation[0], FVector(CurrentValue, CurrentValue, CurrentValue)));
		Wall02.SetRelativeLocation(FMath::VLerp(StartingLocation[1], TargetLocation[1], FVector(CurrentValue, CurrentValue, CurrentValue)));
	}

	UFUNCTION()
    void DeathCollisionOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
        {
           Player.KillPlayer(DeathEffect);
        }
    }
}