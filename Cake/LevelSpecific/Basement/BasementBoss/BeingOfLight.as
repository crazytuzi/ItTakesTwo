import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;

class ABeingOfLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent ForwardDirection;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent EffectComp;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent CameraComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> PlayerCapabilityClass;

	float MayInput = 0.f;
	float CodyInput = 0.f;

	bool bActive = false;
	float CurrentScale = 0.f;

	bool bTutorialActivated = false;
	bool bTutorialCompleted = false;
	float TutorialTime = 0.f;

	UFUNCTION()
	void ActivateBeingOfLight()
	{
		TeleportActor(GetActiveParentBlobActor().ActorLocation, ActorRotation);
		SetActorHiddenInGame(false);
		bActive = true;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ActivateCamera(CameraComp, FHazeCameraBlendSettings(0.f), this);
			Player.SetCapabilityAttributeObject(n"BeingOfLight", this);
			Player.AddCapability(PlayerCapabilityClass);
			Player.SetCapabilityActionState(n"BeingOfLight", EHazeActionState::Active);
			System::SetTimer(this, n"ShowTutorial", 3.5f, false);
		}
	}

	UFUNCTION()
	void ShowTutorial()
	{
		bTutorialActivated = true;
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Up;
		ShowTutorialPrompt(Game::GetMay(), TutorialPrompt, this);
	}

	void UpdatePlayerInput(AHazePlayerCharacter Player, float Input)
	{
		if (Player == Game::GetMay())
			MayInput = FMath::Clamp(Input, 0.f, 1.f);
		else
			CodyInput = FMath::Clamp(Input, 0.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		if (CurrentScale <= 4.f)
		{
			CurrentScale += 2.f * DeltaTime;
			CurrentScale = FMath::Clamp(CurrentScale, 0.f, 2.f);
			EffectComp.SetWorldScale3D(CurrentScale);
		}

		float TotalInput = MayInput + CodyInput;
		if (TotalInput > 1.f)
		{
			AddActorWorldOffset(ForwardDirection.ForwardVector * 1000.f * DeltaTime);

			if (!bTutorialActivated)
				return;

			if (bTutorialCompleted)
				return;

			TutorialTime += DeltaTime;
			if (TutorialTime >= 2.f)
			{
				bTutorialCompleted = true;
				RemoveTutorialPromptByInstigator(Game::GetMay(), this);
			}
		}
	}
}