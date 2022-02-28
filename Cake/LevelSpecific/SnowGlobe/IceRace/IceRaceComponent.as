import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceWidget;

class UIceRaceComponent : UActorComponent
{
	UPROPERTY(Category = "Effects")
	UNiagaraSystem PlayerPowerUpEffect;

	UNiagaraComponent PlayerPowerUpEffectComponent;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem PlayerBoostEffect;

	UNiagaraComponent PlayerBoostEffectComponent;

	UPROPERTY()
	TSubclassOf<UIceRaceWidget> IceRaceWidget;

	UPROPERTY()
	bool bHasBoost;

	UPROPERTY()
	bool bInStartPosition;

	UPROPERTY()
	bool bRaceActive;

	UPROPERTY()
	int Laps = 0;

	UPROPERTY()
	int Checkpoints = 0;

	UPROPERTY()
	UForceFeedbackEffect BoostForceFeedback;

	UPROPERTY()
	FText BoostPickupPromptText;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(GetOwner());
		PlayerPowerUpEffectComponent = Niagara::SpawnSystemAttached(PlayerPowerUpEffect, Player.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false, false);	
		PlayerBoostEffectComponent = Niagara::SpawnSystemAttached(PlayerBoostEffect, Player.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false, false);	
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	//	Print(Player.Name + " Laps: " + Laps);
	}

}