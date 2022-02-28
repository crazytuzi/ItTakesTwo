import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Cake.LevelSpecific.Shed.Vacuum.VacuumWallSlideFan;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;
import Vino.Tutorial.TutorialStatics;

class AVacuumWallSlideFanValve : AValveTurnInteractionActor
{
	UPROPERTY()
	AVacuumWallSlideFan TargetFan;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 9000.f;

	UPROPERTY(Category = "Valve Audio Events")
	UAkAudioEvent StartValveAudioEvent;

	UPROPERTY(Category = "Valve Audio Events")
	UAkAudioEvent StopValveAudioEvent;

	UPROPERTY(Category = "Valve Audio Events")
	UAkAudioEvent DestroyValveAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> DestroyCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DestroyForceFeedback;

	float PreviousSyncValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetFan != nullptr)
		{
			// Is the current replicated input type the same as increase or decrease value
			if(InputStatus == EValveTurnInteractionAnimationDirection::Valid)
			{
				TargetFan.ValveTurnDirection = 1.f;
			}
			else if(InputStatus == EValveTurnInteractionAnimationDirection::Invalid)
			{
				TargetFan.ValveTurnDirection = -1.f;
			}
			else
			{
				TargetFan.ValveTurnDirection = 0.f;
			}

			TargetFan.UpdateRotation(SyncComponent.Value);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Platform_Shed_Vacuum_WallSlideFan_Valve_TurnDirection", TargetFan.ValveTurnDirection);
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		Super::OnInteractionActivated(Component, Player);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::Slow);
		TargetFan.SetControlSide(Player);
		Player.PlayerHazeAkComp.HazePostEvent(StartValveAudioEvent);

		ShowCancelPrompt(Player, this);
    }

	void EndInteraction(AHazePlayerCharacter Player) override
	{
		Super::EndInteraction(Player);
		TargetFan.ValveTurnDirection = 0.f;
		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Slow);
		Player.PlayerHazeAkComp.HazePostEvent(StopValveAudioEvent);

		RemoveCancelPromptByInstigator(Player, this);
	}

	UFUNCTION()
	void DestroyValve()
	{
		EnterInteraction.Disable(n"FanAutomated");
		if (CurrentActivePlayer != nullptr)
			KnockdownActor(CurrentActivePlayer, ActorForwardVector * 1000.f);

		ForceEnd();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(DestroyCamShake, 0.5f);
			Player.PlayForceFeedback(DestroyForceFeedback, false, true, n"ValveDestroy");
		}

		UHazeAkComponent::HazePostEventFireForget(DestroyValveAudioEvent, this.GetActorTransform());
	}
}