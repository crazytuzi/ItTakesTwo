import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Garden.VOBanks.GardenShrubberyVOBank;

class ASpiderTutorialArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent Box;
	default Box.BoxExtent = FVector(500.f, 500.f, 500.f);

	UPROPERTY(Category = "Settings")
	UGardenShrubberyVOBank VOBank;

	UPROPERTY(Category = "Settings")
	bool bShouldTriggerVO = false;

	UPROPERTY(Category = "Settings")
	FName EventName;

	default SetActorTickEnabled(false);

	float VOTimer = 0.f;

	AHazePlayerCharacter OverlappingPlayer;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Box.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        Box.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
    }
    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			Player.SetCapabilityActionState(n"SpiderTutorial", EHazeActionState::Active);
			OverlappingPlayer = Player;
		}
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(VOTimer >= 1.f)
		{
			if(OverlappingPlayer != nullptr && OverlappingPlayer.IsCody())
			{
				PlayFoghornVOBankEvent(VOBank, EventName);
				VOTimer = 0.f;
			}
		}
		else
		{
			VOTimer += DeltaSeconds;
		}
	}

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			Player.SetCapabilityActionState(n"SpiderTutorial", EHazeActionState::Inactive);
			OverlappingPlayer = nullptr;
		}
    }
}