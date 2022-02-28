import Peanuts.Triggers.PlayerTrigger;

class UTriggeredEnableComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	APlayerTrigger PlayerTrigger;

	AHazeActor HazeOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PlayerTrigger == nullptr)
			return;

		HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.DisableActor(this);
		
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (PlayerTrigger == nullptr)
			return;

		PlayerTrigger.OnPlayerEnter.Unbind(this, n"OnPlayerTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerTrigger(AHazePlayerCharacter Player)
	{
		HazeOwner.EnableActor(this);

		PlayerTrigger.OnPlayerEnter.Unbind(this, n"OnPlayerTrigger");
	}

}