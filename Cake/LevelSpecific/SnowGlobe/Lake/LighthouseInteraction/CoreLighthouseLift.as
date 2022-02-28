import Peanuts.Triggers.BothPlayerTrigger;
import Peanuts.Fades.FadeStatics;
import Vino.Checkpoints.Checkpoint;

event void FLiftRideCompleted();
event void FLiftDoorEvent();

class ACoreLighthouseLift : ABothPlayerTrigger
{
	UPROPERTY(Category = "Lift Doors")
	UStaticMeshComponent CoreLiftDoor;

	UPROPERTY(Category = "Lift Doors")
	UStaticMeshComponent LighthouseLiftDoor;


	UPROPERTY(DefaultComponent)
	UHazeCameraComponent CoreCamera;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent LighthouseCamera;


	UPROPERTY()
	ACheckpoint LighthouseCheckpoint;

	UPROPERTY()
	FLiftDoorEvent OnCloseLiftDoor;

	UPROPERTY()
	FLiftDoorEvent OnOpenLighthouseLiftDoor;


	TArray<AHazePlayerCharacter> PlayerCharacters;
	AHazePlayerCharacter PlayerInControl;

	const float LiftRideDuration = 8.f;
	const float FadeToBlackTime = 2.f;

	bool bCoreCameraIsBlending;

	UPROPERTY()
	FLiftRideCompleted OnLiftRideComplete;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CoreCamera.SetAbsolute(true, true, true);
		LighthouseCamera.SetAbsolute(true, true, true);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerCharacters = Game::GetPlayers();

		for(AHazePlayerCharacter PlayerCharacter : PlayerCharacters)
		{
			if(PlayerCharacter.HasControl())
			{
				PlayerInControl = PlayerCharacter;
				break;
			}
		}

		OnBothPlayersInside.AddUFunction(this, n"OnPlayersInsideTrigger");
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float RemainingCoreCamBlend = PlayerInControl.OtherPlayer.GetRemainingBlendTime(CoreCamera);
		if(FMath::Sign(RemainingCoreCamBlend) > 0.f && FMath::IsNearlyZero(RemainingCoreCamBlend, FadeToBlackTime) && bCoreCameraIsBlending)
		{
			// Fade to black!
			FadeOutFullscreen(LiftRideDuration - FadeToBlackTime * 2.5f, FadeToBlackTime, FadeToBlackTime);

			// Start blending towards lighthouse camera
			PlayerInControl.OtherPlayer.ActivateCamera(LighthouseCamera, LiftRideDuration, this);
			bCoreCameraIsBlending = false;

			// Open light house door after 'liftRideDuration' secs
			System::SetTimer(this, n"OnLiftReachedLighthouse", LiftRideDuration - FadeToBlackTime, false);
		}
	}

	void CloseCoreLiftDoor()
	{
		OnCloseLiftDoor.Broadcast();
	}

	UFUNCTION()
	void OpenLighthouseLiftDoor()
	{
		// Teleport players to lighthouse place
		for(AHazePlayerCharacter PlayerCharacter : PlayerCharacters)
		{
			PlayerCharacter.TriggerMovementTransition(this);
			PlayerCharacter.SetActorLocation(LighthouseCheckpoint.GetPositionForPlayer(PlayerCharacter).Location);
		}

		System::SetTimer(this, n"OnLighthouseLiftDoorOpened", FadeToBlackTime, false);
	}

	UFUNCTION()
	void CloseLighthouseLiftDoor()
	{
		// Eman TODO: Close lighthouse lift door
	}

	// Delegate
	UFUNCTION(NotBlueprintCallable)
	void OnPlayersInsideTrigger()
	{
		for(AHazePlayerCharacter PlayerCharacter : PlayerCharacters)
		{
			// Remove control from players
			PlayerCharacter.BlockCapabilities(CapabilityTags::MovementInput, this);
		}

		// Go fullscreen
		PlayerInControl.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);

		// Set camera outside elevator
		PlayerInControl.ActivateCamera(CoreCamera, LiftRideDuration - FadeToBlackTime, this);
		bCoreCameraIsBlending = true;

		// Close lift Door
		CloseCoreLiftDoor();
	}

	// Delegate
	UFUNCTION(NotBlueprintCallable)
	void OnLiftReachedLighthouse()
	{
		OpenLighthouseLiftDoor();
		OnOpenLighthouseLiftDoor.Broadcast();
	}

	// Delegate
	UFUNCTION(NotBlueprintCallable)
	void OnLighthouseLiftDoorOpened()
	{
		// Restore player control
		for(AHazePlayerCharacter PlayerCharacter : PlayerCharacters)
		{
			PlayerCharacter.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		OnLiftRideComplete.Broadcast();
		bCoreCameraIsBlending = false;
	}
}