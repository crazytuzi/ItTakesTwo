event void FBlackHoleEvent(AHazePlayerCharacter Player, int Index);

UCLASS(Abstract)
class ABlackHole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent BlackHoleEffect;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent Trigger;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY()
	FBlackHoleEvent OnEnterBlackHole;

	UPROPERTY()
	FBlackHoleEvent OnExitBlackHole;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> EnterCapability;

	int CurrentIndex = 0;
	int MaxIndex = 6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(EnterCapability);

		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(EnterCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.SetCapabilityActionState(n"BlackHole", EHazeActionState::Active);
	}
}