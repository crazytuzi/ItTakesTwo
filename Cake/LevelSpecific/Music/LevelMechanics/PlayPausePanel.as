import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.MovementComponent;

event void FPlayPausePanelPressedEvent();

UCLASS(Abstract)
class APlayPausePanel : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlayButton;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PauseButton;

	UPROPERTY()
	bool bPaused = false;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface PressedMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface NotPressedMaterial;

	float PressedOffset = 40.f;

	UPROPERTY()
	FHazeTimeLike PressedTimeLike;

	UPROPERTY()
	FPlayPausePanelPressedEvent OnPlayButtonPressed;

	UPROPERTY()
	FPlayPausePanelPressedEvent OnPauseButtonPressed;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPaused)
		{
			PauseButton.SetMaterial(1, PressedMaterial);
			PlayButton.SetMaterial(1, NotPressedMaterial);

			PauseButton.SetRelativeLocation(FVector(125.f, 0.f, -PressedOffset));
			PlayButton.SetRelativeLocation(FVector(-125.f, 0.f, 0.f));
		}
		else
		{
			PauseButton.SetMaterial(1, NotPressedMaterial);
			PlayButton.SetMaterial(1, PressedMaterial);

			PauseButton.SetRelativeLocation(FVector(125.f, 0.f, 0.f));
			PlayButton.SetRelativeLocation(FVector(-125.f, 0.f, -PressedOffset));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorGroundPoundedDelegate GroundPoundDelegate;
		GroundPoundDelegate.BindUFunction(this, n"GroundPounded");
		BindOnActorGroundPounded(this, GroundPoundDelegate);

		PressedTimeLike.BindUpdate(this, n"UpdatePressed");
		PressedTimeLike.BindFinished(this, n"FinishPressed");

		if (bPaused)
		{
			PressedTimeLike.SetNewTime(0.1f);
			OnPauseButtonPressed.Broadcast();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void GroundPounded(AHazePlayerCharacter Player)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);

		if (MoveComp != nullptr)
		{
			if (MoveComp.DownHit.Component == PlayButton && bPaused)
			{
				bPaused = false;
				PauseButton.SetMaterial(1, NotPressedMaterial);
				PlayButton.SetMaterial(1, PressedMaterial);
				
			}
			else if (MoveComp.DownHit.Component == PauseButton && !bPaused)
			{
				bPaused = true;			
				PauseButton.SetMaterial(1, PressedMaterial);
				PlayButton.SetMaterial(1, NotPressedMaterial);
			}

			PressedTimeLike.PlayFromStart();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdatePressed(float CurValue)
	{
		float CurPressedValue = FMath::Lerp(0.f, -40.f, CurValue);
		float CurUnpressedValue = FMath::Lerp(-40.f, 0.f, CurValue);

		if (bPaused)
		{
			PauseButton.SetRelativeLocation(FVector(125.f, 0.f, CurPressedValue));
			PlayButton.SetRelativeLocation(FVector(-125.f, 0.f, CurUnpressedValue));
		}
		else
		{
			PauseButton.SetRelativeLocation(FVector(125.f, 0.f, CurUnpressedValue));
			PlayButton.SetRelativeLocation(FVector(-125.f, 0.f, CurPressedValue));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishPressed()
	{
		if (bPaused)
		{
			OnPauseButtonPressed.Broadcast();
		}
		else
		{
			OnPlayButtonPressed.Broadcast();
		}
	}
}