import Peanuts.Pendulum.PendulumWidget;

event void FOnPendulumEnter(AHazePlayerCharacter Player);
event void FOnPendulumExit(AHazePlayerCharacter Player);
event void FOnPendulumSuccess(AHazePlayerCharacter Player);
event void FOnPendulumFail(AHazePlayerCharacter Player);

class UPendulumUserComponent : UActorComponent
{
	UPendulumComponent CurrentPendulum = nullptr;
}

class UPendulumComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Widget")
	TSubclassOf<UPendulumWidget> WidgetClass;

	UPROPERTY(Category = "Pendulum")
	float Period = 1.f;

	UPROPERTY(Category = "Pendulum")
	float SuccessFraction = 0.3f;

	UPROPERTY(Category = "Pendulum")
	FOnPendulumEnter OnEnter;

	UPROPERTY(Category = "Pendulum")
	FOnPendulumExit OnExit;

	UPROPERTY(Category = "Pendulum")
	FOnPendulumSuccess OnSuccess;

	UPROPERTY(Category = "Pendulum")
	FOnPendulumFail OnFail;

	UPROPERTY(Category = "Audio Event")
	UAkAudioEvent OnTriggerDrumMachine;

	// Gameplay variables
	TArray<UPendulumWidget> Widgets;
	TArray<AHazePlayerCharacter> InteractingPlayers;
	float Time = 0.f;
	float PendulumPosition = 0.f;

	bool bIsPendulumActive = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Time += DeltaTime * PI * Period;
		PendulumPosition = FMath::Cos(Time);

		for(auto Widget : Widgets)
		{
			Widget.PendulumPosition = FMath::Cos(Time);
			Widget.SuccessFraction = SuccessFraction;
			Widget.bHasInteractingPlayers = InteractingPlayers.Num() > 0;
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void AddPlayer(AHazePlayerCharacter Player)
	{
		InteractingPlayers.AddUnique(Player);
		UPendulumUserComponent UserComp = UPendulumUserComponent::GetOrCreate(Player);
		UserComp.CurrentPendulum = this;
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void RemovePlayer(AHazePlayerCharacter Player)
	{
		InteractingPlayers.Remove(Player);
		UPendulumUserComponent UserComp = UPendulumUserComponent::GetOrCreate(Player);
		UserComp.CurrentPendulum = nullptr;
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void StartPendulum()
	{
		for(auto Player : Game::Players)
		{
			auto Widget = Cast<UPendulumWidget>(Player.AddWidget(WidgetClass));
			Widget.SuccessFraction = SuccessFraction;
			Widget.AttachWidgetToComponent(this);

			Widgets.Add(Widget);
		}
		
		bIsPendulumActive = true;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void StopPendulum()
	{
		for(auto Widget : Widgets)
		{
			Widget.Player.RemoveWidget(Widget);
		}
		Widgets.Empty();

		bIsPendulumActive = false;
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void DoPlayerPress(AHazePlayerCharacter Player)
	{
		if (!bIsPendulumActive)
			return;

		if (FMath::Abs(PendulumPosition) <= SuccessFraction)
		{
			OnSuccess.Broadcast(Player);
			UHazeAkComponent::HazePostEventFireForget(OnTriggerDrumMachine, FTransform());
			
		}
		else
		{
			OnFail.Broadcast(Player);
		}
	}
}