import Vino.Checkpoints.Checkpoint;
import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.PlayRoom.Castle.CastleCamera.CastleCameraActor;
import Peanuts.Fades.FadeStatics;

class ACastleLevelPortalEntrance : ACheckpoint
{
	UPROPERTY()
	ACastleCamera Camera;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnRespawnAtCheckpoint.AddUFunction(this, n"PortalRespawnComplete");		
	}

	UFUNCTION()
	void PortalRespawnComplete()
	{
		//Print("AOSDJAOSIDA", 50);
		//float FadeInDuration = 0.5f;
		/*FadeOutFullscreen(2, 0, FadeInDuration);
		ActivateCamera();*/
	}

	UFUNCTION()
	void ActivateCamera()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Camera != nullptr)
			{
				FHazeFocusTarget FocusTarget;
				FocusTarget.Actor = Player;
				Camera.KeepInViewComponent.AddTarget(FocusTarget);

				FHazeCameraBlendSettings BlendSettings;
				BlendSettings.BlendTime = 0.f;
				Camera.ActivateCamera(Player, BlendSettings, this);
			}
		}
	}
}

event void FPlayerCastlePortalEvent();

class ACastleLevelPortalExit : APlayerTrigger
{
    UPROPERTY(Category = "Portal Trigger")
    FPlayerCastlePortalEvent OnPortalFadeOutComplete;

	void EnterTrigger(AActor Actor) override
    {
		APlayerTrigger::EnterTrigger(Actor);

		StartFadeOut();
    }

	void StartFadeOut()
	{
		float FadeOutDuration = 0.5f;
		FadeOutFullscreen(2, FadeOutDuration, 0);

		System::SetTimer(this, n"FadeComplete", FadeOutDuration, false);
	}

	UFUNCTION()
	void FadeComplete()
	{
		OnPortalFadeOutComplete.Broadcast();
	}
}