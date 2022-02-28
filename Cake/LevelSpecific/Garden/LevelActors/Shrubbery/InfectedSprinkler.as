import Vino.PlayerHealth.PlayerHealthStatics;

event void FOnSprinklerTurnedOff();

class AInfectedSprinkler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UBoxComponent BoxCollider;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent WaterRoot;

	UPROPERTY(DefaultComponent, Attach = WaterRoot)
	UNiagaraComponent SprinklerEffect;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.f;
	default DisableComp.bRenderWhileDisabled = true;
	
	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	bool bActivated = true;

	UPROPERTY()
	float MaxPitch = 25.0f;
	
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SprinklerMovementTimeLike;

	UPROPERTY()
	FOnSprinklerTurnedOff OnSprinklerTurnedOff;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"InfectedSprinklerCapability");
	}

	UFUNCTION()
	void DeactivateSprinkler()
	{
		bActivated = false;
		OnSprinklerTurnedOff.Broadcast();
	}
}
