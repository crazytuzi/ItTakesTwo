import Vino.PlayerHealth.PlayerHealthStatics;

class AQueenDeathRay : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DamageTrigger;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		SetRayActive(false);
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
        if(!bIsActive)
		{
			return;
		}

		AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);

		if(OverlappingPlayer == nullptr)
			return;

		OverlappingPlayer.DamagePlayerHealth(0.2f, DamageEffect);
    }

	UFUNCTION()
	void SetRayActive(bool bSetActive)
	{
		SetActorHiddenInGame(!bSetActive);
		bIsActive = bSetActive;
	}
}