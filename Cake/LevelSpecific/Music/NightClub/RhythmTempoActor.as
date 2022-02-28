import Rice.GUI.InputButtonWidget;

UCLASS(Abstract)
class ARhythmTempoActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WidgetNode;

	UPROPERTY()
	TSubclassOf<UInputButtonWidget> InputButtonClass;
	default InputButtonClass = Asset("/Game/GUI/InputIcon/WBP_InputButton.WBP_InputButton_C");
	private UInputButtonWidget InputButtonInstance = nullptr;

	UPROPERTY()
	FName ActionName;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	AHazeActor RhythmActor;
	UActorComponent RhythmComp;
	AHazePlayerCharacter Player;

	FVector StartLocation;
	FVector EndLocation;
	FVector TargetLocation;
	FVector TargetDirection;

	UPROPERTY(EditDefaultsOnly, meta = (ClampMin = 0.05, ClampMax = 0.5))
	float HitMarginal = 0.2f;

	float Tempo = 1.0f;
	float Elapsed = 0.0f;
	float DistanceTotal = 0.0f;
	float TargetTime = 0.0f;

	bool bReadyToDie = false;
	bool bControlSaysOkayToDie = false;
	bool bStopped = true;
	int HandshakeCounter = 0;

	void SetupTempo(FVector NewTargetLocation, FVector InStartLocation, FRotator InStartRotation, float NewTempo)
	{
		SetActorLocationAndRotation(InStartLocation, InStartRotation);
		SetActorHiddenInGame(false);
		StartLocation = ActorLocation;
		Tempo = NewTempo;
		TargetLocation = NewTargetLocation;
		DistanceTotal = TargetLocation.Distance(ActorLocation);
		TargetDirection = (TargetLocation - StartLocation).GetSafeNormal();
		EndLocation = TargetLocation + (TargetLocation * DistanceTotal);
		Elapsed = 0.0f;
		TargetTime = Tempo * 2.0f;
		DistanceTotal *= 2.0f;
		SetActorTickEnabled(true);
		bReadyToDie = false;
		bStopped = false;
		HandshakeCounter = 2;
	}
	
	void StopTempo()
	{
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
		SetLifeSpan(3.0f);
		RemoveWidget(Player);
		bStopped = true;
	}

	void Handshake()
	{
		bControlSaysOkayToDie = true;
		HandshakeCounter--;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float DistanceRemaining = TargetLocation.Distance(ActorLocation);
		const float PercentRemaining = Elapsed / TargetTime;
		//Print("PercentRemaining " + PercentRemaining);
		FVector NewLocation = StartLocation + (TargetDirection * (DistanceTotal * PercentRemaining));
		SetActorLocation(NewLocation);
		Elapsed += MovementSpeed * DeltaTime;

		if(Elapsed > (Tempo + HitMarginal))
		{
			bReadyToDie = true;
			SetActorTickEnabled(false);
			BP_OnReadyToDie();
		}
	}

	UFUNCTION(BlueprintEvent, meta =  (DisplayName = "On Ready To Die"))
	void BP_OnReadyToDie() {}

	void OnNewDancer(AHazePlayerCharacter InPlayer)
	{
		BP_OnNewDancer(InPlayer);
		RefreshWidget(InPlayer);
	}

	// Called whenever a new player has started using the rhythm actor so we can trigger controller icon change etc.
	UFUNCTION(BlueprintEvent, meta =  (DisplayName = "On New Dancer"))
	void BP_OnNewDancer(AHazePlayerCharacter NewDancer) {}

	bool TestTempo() const
	{
		if(bStopped)
			return false;

		if(bControlSaysOkayToDie)
			return false;

		const float Min = Tempo - HitMarginal;
		const float Max = Tempo + HitMarginal;
		return Elapsed > Min && Elapsed < Max;
	}

	float GetMovementSpeed() const property
	{
		if(RhythmActor.HasControl())
		{
			return 1.0f;
		}

		const float PercentRemaining = Elapsed / (TargetTime * 0.5f);

		if(PercentRemaining > 0.96f)
		{
			return 0.4f;
		}

		return 1.0f;
	}

	void RefreshWidget(AHazePlayerCharacter InPlayer)
	{
		if(InPlayer != Player)
		{
			RemoveWidget(Player);
			CreateWidget(InPlayer);
			Player = InPlayer;
		}
		else if(InputButtonInstance == nullptr && InPlayer != nullptr)
		{
			CreateWidget(InPlayer);
			Player = InPlayer;
		}
	}

	void ClearWidget()
	{
		RemoveWidget(Player);
	}

	protected void CreateWidget(AHazePlayerCharacter InPlayer)
	{
		if(InputButtonInstance == nullptr && InputButtonClass.IsValid())
		{
			InputButtonInstance = Cast<UInputButtonWidget>(InPlayer.AddWidget(InputButtonClass));
			InputButtonInstance.ActionName = ActionName;
			InputButtonInstance.AttachWidgetToComponent(WidgetNode);
			InputButtonInstance.SetWidgetShowInFullscreen(true);
		}
	}

	protected void RemoveWidget(AHazePlayerCharacter InPlayer)
	{
		if(InputButtonInstance != nullptr && InPlayer != nullptr)
		{
			InPlayer.RemoveWidget(InputButtonInstance);
			InputButtonInstance.RemoveFromParent();
			InputButtonInstance = nullptr;
		}
	}

	bool IsFree() const
	{
		if(!Network::IsNetworked())
		{
			return bStopped;
		}

		return HandshakeCounter <= 0;
	}
}
