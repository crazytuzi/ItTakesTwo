import Vino.Interactions.DoubleInteractionActor;
class AMarbleMazeButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonMeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = ButtonMeshRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteractionActor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonCancelledAudioEvent;

	UPROPERTY()
	FHazeTimeLike MoveButtonTimeline;
	default MoveButtonTimeline.Duration = 1.f;

	UPROPERTY()
	bool bIsLeftInteraction = false;

	// --- Timers --- //
	bool bShouldTickForwardTimer = false;
	float ForwardTimer = 0.f;
	float ForwardTimerDuration = 0.4f;
	bool bShouldTickBackwardTimer = false;
	float BackwardTimer = 0.f;
	float BackwardTimerDuration = 0.2f;
	// ------------- //

	AHazePlayerCharacter PlayerUsingButton;
	FVector ButtonRootStartLoc = FVector::ZeroVector;
	FVector ButtonRootEndLoc = FVector(-20.f, 0.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveButtonTimeline.BindUpdate(this, n"MoveButtonTimelineUpdate");
		if (bIsLeftInteraction)
			DoubleInteractionActor.OnLeftInteractionReady.AddUFunction(this, n"OnInteractionReady");
		else
			DoubleInteractionActor.OnRightInteractionReady.AddUFunction(this, n"OnInteractionReady");

		DoubleInteractionActor.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"CanceledInteraction");

		MoveButtonTimeline.SetPlayRate(1.f/0.15f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickForwardTimer)
		{
			if (ForwardTimer >= ForwardTimerDuration)
			{
				bShouldTickForwardTimer = false;
				MoveButtonTimeline.PlayFromStart();
			}

			ForwardTimer += DeltaTime;
		}

		if (bShouldTickBackwardTimer)
		{
			if (BackwardTimer >= BackwardTimerDuration)
			{
				bShouldTickBackwardTimer = false;
				MoveButtonTimeline.ReverseFromEnd();
			}

			BackwardTimer += DeltaTime;
		}
	}

	UFUNCTION()
	void MoveButtonTimelineUpdate(float CurrentValue)
	{
		ButtonMeshRoot.SetRelativeLocation(FMath::Lerp(ButtonRootStartLoc, ButtonRootEndLoc, CurrentValue));
	}

	UFUNCTION()
	void OnInteractionReady(AHazePlayerCharacter Player)
	{
		PlayerUsingButton = Player;
		Player.PlayerHazeAkComp.HazePostEvent(ButtonActivatedAudioEvent);
		ForwardTimer = 0.f;
		bShouldTickForwardTimer = true;
	}

	UFUNCTION()
	void CanceledInteraction(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bLeftInteraction)
	{
		if (bLeftInteraction && !bIsLeftInteraction)
		return;
		Player.PlayerHazeAkComp.HazePostEvent(ButtonCancelledAudioEvent);
		BackwardTimer = 0.f;
		bShouldTickBackwardTimer = true;
	}
}