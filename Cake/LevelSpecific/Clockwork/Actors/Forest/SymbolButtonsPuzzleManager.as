import Cake.LevelSpecific.Clockwork.Actors.Forest.SymbolButtonsClockTarget;
import Peanuts.Triggers.PlayerTrigger;

class ASymbolButtonsPuzzleManager : AHazeActor
{
	UPROPERTY()
	TArray<int> CorrectOrder;

	UPROPERTY()
	TArray<AActor> Clocks;

	UPROPERTY()
	TArray<ASymbolButtonsClockTarget> LookAtTargets;

	UPROPERTY()
	UNiagaraSystem Particle;

	UPROPERTY()
	UNiagaraSystem FailParticle;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SuccessEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FailEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PuzzleDoneEvent;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SuccessForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FailForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SuccessCameraShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> FailCameraShake;

	UPROPERTY()
	APlayerTrigger LookAtTrigger;

	int CheckNumber = 0;
	
	bool bPuzzleDone = false;

	UFUNCTION()
	void CheckCorrectButton(int ButtonNumber, AActor FailParticleLocation)
	{
		if(bPuzzleDone)
			return;

		if (ButtonNumber != CorrectOrder[0])
		{
			if(CorrectOrder[CheckNumber] == ButtonNumber)
			{
				Niagara::SpawnSystemAtLocation(Particle, Clocks[CheckNumber].ActorLocation, Clocks[CheckNumber].ActorRotation);
				UHazeAkComponent::HazePostEventFireForget(SuccessEvent, Clocks[CheckNumber].GetActorTransform());
				if (LookAtTargets[CheckNumber].bLookedAt)
				{
					Game::GetMay().PlayForceFeedback(SuccessForceFeedback, false, true, n"SymbolSuccess");
					Game::GetMay().PlayCameraShake(SuccessCameraShake, 1.5f);
				}

				CheckNumber++;
				if(CheckNumber == CorrectOrder.Num())
				{
					bPuzzleDone = true;
					PuzzleDone();
					UHazeAkComponent::HazePostEventFireForget(PuzzleDoneEvent, Clocks[CheckNumber-1].GetActorTransform());
					return;
				}
			} 
			else
			{
				Niagara::SpawnSystemAtLocation(FailParticle, FailParticleLocation.ActorLocation, FailParticleLocation.ActorRotation);
				UHazeAkComponent::HazePostEventFireForget(FailEvent, Clocks[CheckNumber].GetActorTransform());
				if (LookAtTargets[ButtonNumber - 1].bLookedAt)
				{
					Game::GetMay().PlayForceFeedback(FailForceFeedback, false, true, n"SymbolFailure");
					Game::GetMay().PlayCameraShake(FailCameraShake, 1.5f);
				}
				CheckNumber = 0;
			}
			return;
		}

		if(ButtonNumber == CorrectOrder[0])
		{
			Niagara::SpawnSystemAtLocation(Particle, Clocks[0].ActorLocation, Clocks[0].ActorRotation);
			UHazeAkComponent::HazePostEventFireForget(SuccessEvent, Clocks[0].GetActorTransform());
			CheckNumber = 1;
			if (LookAtTargets[0].bLookedAt)
			{
				Game::GetMay().PlayForceFeedback(SuccessForceFeedback, false, true, n"SymbolFailure");
				Game::GetMay().PlayCameraShake(SuccessCameraShake, 1.5f);
			}
		}

		if(CheckNumber == 0)
			return;

		if(ButtonNumber != CorrectOrder[CheckNumber] && ButtonNumber != CorrectOrder[CheckNumber - 1]) 
		{
			Niagara::SpawnSystemAtLocation(FailParticle, FailParticleLocation.ActorLocation, FailParticleLocation.ActorRotation);
			UHazeAkComponent::HazePostEventFireForget(SuccessEvent, LookAtTargets[ButtonNumber - 1].GetActorTransform());
			CheckNumber = 0;
			if (LookAtTargets[ButtonNumber - 1].bLookedAt)
			{
				Game::GetMay().PlayForceFeedback(FailForceFeedback, false, true, n"SymbolFailure");
				Game::GetMay().PlayCameraShake(SuccessCameraShake, 1.5f);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void PuzzleDone()
	{
		bPuzzleDone = true;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (LookAtTrigger != nullptr)
		{
			for (ASymbolButtonsClockTarget Target : LookAtTargets)
			{
				Target.LookAtComp.TriggerVolume = LookAtTrigger;
			}
		}
	}
}