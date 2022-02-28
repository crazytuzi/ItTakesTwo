import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkChallenge;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkMathBook;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkTimer;

enum EHomeworkMathChallenge
{  
    Challenge01,
	Challenge02,
	Challenge03
};

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkChallengeMath : AHomeworkChallenge
{
	EHomeworkMathChallenge CurrentMathChallenge = EHomeworkMathChallenge::Challenge01;

	UPROPERTY(Category = "Timers")
	float ChallengeTimerDuration;
	default ChallengeTimerDuration = 10.f;

	UPROPERTY()
	float ChallengeTimer;

	UPROPERTY()
	float CooldownTime;
	default CooldownTime = 3.f;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	bool bTimerIsActive = false;

	TArray<int> NewAnswerArray;

	int Answer;
	int LastAnswer;
	float AnswerTimer;

	bool bLastStop = false;

	UPROPERTY(Category = "References")
	AHomeworkMathBook MathBook;

	UPROPERTY(Category = "References")
	AHomeworkTimer Timer;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHomeworkChallenge::BeginPlay_Implementation();

		NewAnswerArray.Add(0);
		NewAnswerArray.Add(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);
		DecreaseTimer(DeltaTime);
		CheckIfTimeRanOut();
		SetAnswerTextInBook();
		CheckIfCorrectAnswer(DeltaTime);
	}

	UFUNCTION()
	void CurrentAnswers(TArray<int> AnswersArray)
	{
		NewAnswerArray[0] = AnswersArray[0] + 1;
		NewAnswerArray[1] = AnswersArray[1] + 1;
		AnswerTimer = 0.f;
	}

	void StartChallenge()
	{
		AHomeworkChallenge::StartChallenge();
		
		if (HasControl())
			NetStartChallenge();
	}

	UFUNCTION(NetFunction)
	void NetStartChallenge()
	{
		PickRandomAnswer();
		StartTimer();
	}

	void StartTimer()
	{
		ChallengeTimer = ChallengeTimerDuration;
		bTimerIsActive = true;
		MathBook.AudioCountDownStart(true);
		Timer.StartTimer();
	}

	void DecreaseTimer(float DeltaTime)
	{
		if (bTimerIsActive)
		{
			ChallengeTimer -= DeltaTime;
			SetTimerTextOnBook();
			SetTimerTextColor();
		}
	}

	void CheckIfCorrectAnswer(float DeltaTime)
	{
		if (NewAnswerArray[0] + NewAnswerArray[1] == Answer && bTimerIsActive)
		{
			if(NewAnswerArray[0] != 0 && NewAnswerArray[1] != 0)
			{
				AnswerTimer += DeltaTime;
				
				if (AnswerTimer > 0.75f)
					WasCorrectAnswer();
			}
		} 
	}

	void WasCorrectAnswer()
	{
		if (HasControl())
		{
			NetWasCorrectAnswer(NewAnswerArray[0], NewAnswerArray[1], Answer);
			System::SetTimer(this, n"EraseAllNumbers", CooldownTime / 2, false);
			System::SetTimer(this, n"ChallengeStepCompleted", CooldownTime, false);
		}	
	}

	UFUNCTION(NetFunction)
	void NetWasCorrectAnswer(int LeftAnswer, int RightAnswer, int NewAnwer)
	{
		StopTimer();
		MathBook.ShowCheckMark(true);
		MathBook.ShowRingCheckMark(CurrentMathChallenge, true, false);
		MathBook.AudioRightAnswer();
		ForceAnswerTextInBook(LeftAnswer, RightAnswer, NewAnwer);
		AnswerTimer = 0;
	}

	void ResetTimer()
	{
		if (HasControl())
			NetResetTimer();
	}

	UFUNCTION(NetFunction)
	void NetResetTimer()
	{
		ChallengeTimer = ChallengeTimerDuration;
	}

	void StopTimer()
	{
		bTimerIsActive = false;
		MathBook.AudioCountDownStart(false);	
		Timer.StopTimer();
		
		if (!bLastStop)
			Timer.SetTime(ChallengeTimerDuration);
	}

	void CheckIfTimeRanOut()
	{
		if (ChallengeTimer <= 0 && bTimerIsActive == true)
		{
			FailedChallenge();
			bTimerIsActive = false;
			MathBook.ShowCross(true);
			MathBook.AudioCountDownStart(false);
			System::SetTimer(this, n"RestartAfterFailure", 3.f, false);
			Timer.StopTimer();
			Timer.SetTime(ChallengeTimerDuration);
		}
	}

	UFUNCTION()
	void RestartAfterFailure()
	{
		CurrentMathChallenge = EHomeworkMathChallenge::Challenge01;
		MathBook.ShowRingCheckMark(0, false, true);
		MathBook.ShowCross(false);
		PickRandomAnswer();
		StartTimer();
	}

	void EraseAllNumbers()
	{
		MathBook.SetNumbersErased(true);
	}

	void ShowAllNumbers()
	{
		MathBook.SetNumbersErased(false);
	}

	UFUNCTION(BlueprintEvent)
	void SetTimerTextOnBook()
	{
		// Converting Float to Seconds and MS in BP!
		// Also setting the FText in BP!
	}

	UFUNCTION(BlueprintEvent)
	void SetTimerTextColor()
	{
		// DOING THIS IN BP!
	}

	void SetAnswerTextInBook()
	{
		if (bTimerIsActive)
			MathBook.SetMathText(NewAnswerArray[0], NewAnswerArray[1], Answer);
	}

	void ForceAnswerTextInBook(int LeftAnswer, int RightAnswer, int NewAnswer)
	{
		MathBook.SetMathText(LeftAnswer, RightAnswer, NewAnswer);
	}

	void PickRandomAnswer()
	{
		if (HasControl())
		{
			int RandomAnsw = FMath::RandRange(5, 17);

			if (RandomAnsw == LastAnswer)
			{
				PickRandomAnswer();
			} else {
				NetPickRandomAnswer(RandomAnsw);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetPickRandomAnswer(int NewAnswer)
	{
		Answer = NewAnswer;
		LastAnswer = NewAnswer;
	}

	UFUNCTION()
	void ChallengeStepCompleted()
	{
		NetChallengeStepCompleted();
	}

	UFUNCTION(NetFunction)
	void NetChallengeStepCompleted()
	{
		switch (CurrentMathChallenge)
        {
        case EHomeworkMathChallenge::Challenge01:
           // Change To Challenge 02
		   CurrentMathChallenge = EHomeworkMathChallenge::Challenge02;
		   MathBook.ShowCheckMark(false);
		   PickRandomAnswer();
		   StartTimer();
		   Timer.StartTimer();
		   ShowAllNumbers();
        break;
        case EHomeworkMathChallenge::Challenge02:
           // Change To Challenge 03
		   CurrentMathChallenge = EHomeworkMathChallenge::Challenge03;
		   MathBook.ShowCheckMark(false);
		   PickRandomAnswer();
		   StartTimer();
		   Timer.StartTimer();
		   ShowAllNumbers();
        break;
        case EHomeworkMathChallenge::Challenge03:
           // Complete Math Challenge 
		   ChallengeCompleted.Broadcast(this);
		   MathBook.AudioFinalSuccess();
		   bLastStop = true;
		   StopTimer();
        break;
        }
	}
}