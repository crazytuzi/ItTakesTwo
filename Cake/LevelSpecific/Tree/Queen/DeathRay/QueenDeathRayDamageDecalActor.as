import Vino.PlayerHealth.PlayerHealthStatics;

class AQueenDeathrayDamageDecalActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FRuntimeFloatCurve FadeCurve;

	UPROPERTY(DefaultComponent)
	UDecalComponent Decal;

	UPROPERTY(DefaultComponent)
	UBoxComponent DamageBox;

	bool bDealDamage = true;
	float TimeSinceDamage = 0;
	
	UPROPERTY()
	float TimeActive;

	UPROPERTY()
	const float MaxTime = 10;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableActor(nullptr);
		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player != nullptr)
		{
			DamagePlayerHealth(Player, 0.5f);
			OverlappingPlayers.Add(Player);
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Decal.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player != nullptr && bDealDamage)
		{
			DamagePlayerHealth(Player, 0.5f);
			OverlappingPlayers.Remove(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (OverlappingPlayers.Num() > 0)
		{
			TimeSinceDamage += DeltaTime;
		}

		if (TimeSinceDamage > 3)
		{
			for (auto Player : OverlappingPlayers)
			{
				if(bDealDamage)
				{
					DamagePlayerHealth(Player, 0.5f);
				}
			}
		}

		TimeActive += DeltaTime;

		if (TimeActive > MaxTime * 0.33f)
		{
			bDealDamage = false;
		}

		if (TimeActive > MaxTime)
		{
			DisableActor(nullptr);
		}
	}
}