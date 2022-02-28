import Vino.PlayerHealth.PlayerHealthStatics;

event void FElectrifiedSurfaceEvent(AHazePlayerCharacter Player);

UCLASS(Abstract)
class AElectrifiedSurface : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent DamageTrigger;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000.f;

	UPROPERTY()
	bool bActive = false;
	UPROPERTY()
	float StartDelay = 0.f;

	bool bElectrified = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	bool bControlledByManager = true;

	UPROPERTY()
	FElectrifiedSurfaceEvent OnPlayerKilled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterDamageTrigger");

		if (bControlledByManager)
			return;

		if (bActive)
		{
			if (StartDelay != 0)
				System::SetTimer(this, n"StartPulsing", StartDelay, false);
			else
				StartPulsing();
		}
	}

	UFUNCTION()
	void StartPulsing()
	{
		BP_StartPulsing();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartPulsing()
	{
		
	}

	UFUNCTION()
	void SetElectrified()
	{
		bElectrified = true;

		TArray<AActor> OverlappingActors;
		DamageTrigger.GetOverlappingActors(OverlappingActors, AHazePlayerCharacter::StaticClass());

		for (AActor CurActor : OverlappingActors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CurActor);

			if (Player != nullptr && Player.HasControl() && !Player.IsPlayerDead())
			{
				NetKillPlayer(Player);
			}
		}
	}

	UFUNCTION()
	void NoLongerElectrified()
	{
		bElectrified = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterDamageTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && Player.HasControl() && !Player.IsPlayerDead())
		{
			if (bElectrified)
			{
				NetKillPlayer(Player);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetKillPlayer(AHazePlayerCharacter Player)
	{
		KillPlayer(Player, DeathEffect);
		OnPlayerKilled.Broadcast(Player);
	}
}