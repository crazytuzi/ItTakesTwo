event void FHopscotchButtonEvent(AHopscotchButton Button);

class AHopscotchButton : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent ButtonMesh;
    default ButtonMesh.RelativeRotation = FRotator(90.f, 180.f, 180.f);
    default ButtonMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    UPROPERTY(DefaultComponent, Attach = Root)
    USphereComponent SphereCollision;
    default SphereCollision.RelativeLocation = FVector(0.f, 0.f, 80.f);
    default SphereCollision.SphereRadius = 84.f;

    UPROPERTY()
    FHopscotchButtonEvent ButtonPressedEvent;

	UPROPERTY()
	FHopscotchButtonEvent ButtonResetEvent;

    UPROPERTY()
    FHazeTimeLike ButtonPressedTimeline;

	UPROPERTY()
	TArray<AHopscotchButton> OtherButtons;

	TArray<AHazePlayerCharacter> PlayersOnButton;

    FVector ButtonIntialLocation;
    bool bHasBeenPressed;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		SphereCollision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
        ButtonPressedTimeline.BindUpdate(this, n"ButtonPressedTimelineUpdate");
        ButtonIntialLocation = ButtonMesh.RelativeLocation;
    }

    UFUNCTION()
    void ButtonPressedTimelineUpdate(float CurrentValue)
    {
        ButtonMesh.SetRelativeLocation(FMath::VLerp(ButtonIntialLocation, FVector(ButtonIntialLocation - FVector(0.f, 0.f, 70.f)), FVector(0.f, 0.f, CurrentValue)));
    }

    UFUNCTION()
    void ResetButton()
    {
        if (bHasBeenPressed)
		{
            bHasBeenPressed = false;
            ButtonPressedTimeline.Reverse();
			ButtonResetEvent.Broadcast(this);
		}
    }

	UFUNCTION()
	void PressButton(bool bSendEvent)
	{
		if (!bHasBeenPressed)
        {
            bHasBeenPressed = true;
            ButtonPressedTimeline.PlayFromStart();
            
			if (bSendEvent)
				ButtonPressedEvent.Broadcast(this);
        }
	}

    UFUNCTION()
    void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		if (!OtherActor.HasControl())
			return;

        if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
        {
			NetSetIsPlayerOnButton(Cast<AHazePlayerCharacter>(OtherActor), true);
        }
    }

	UFUNCTION()
    void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (!OtherActor.HasControl())
			return;

        if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
        {
			NetSetIsPlayerOnButton(Cast<AHazePlayerCharacter>(OtherActor), false);
        }
    }

	UFUNCTION(NetFunction)
	void NetSetIsPlayerOnButton(AHazePlayerCharacter Player, bool bOnButton)
	{
		if (bOnButton)
			PlayersOnButton.AddUnique(Player);

		else
			PlayersOnButton.Remove(Player);

		for (AHopscotchButton Button : OtherButtons)
		{
			Button.UpdateButtons();
		}

		UpdateButtons();
	}

	UFUNCTION()
	void UpdateButtons()
	{
		if (!bHasBeenPressed && PlayersOnButton.Num() > 0)
		{
			PressButton(true);
		}
		else if (bHasBeenPressed && PlayersOnButton.Num() == 0)
		{
			for (AHopscotchButton Button : OtherButtons)
			{
				if (Button.PlayersOnButton.Num() > 0)
				{
					ResetButton();
					break;
				}
			}
		}
	}
}