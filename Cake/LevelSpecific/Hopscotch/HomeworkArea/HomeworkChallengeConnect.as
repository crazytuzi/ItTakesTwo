import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkChallenge;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkConnectBook;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkConnectPaper;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkPen;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkTimer;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkChallengeConnect : AHomeworkChallenge
{
	UPROPERTY()
	AHomeworkConnectPaper HomeConnectPaper;

	UPROPERTY()
	AHomeworkPen HomeworkPen;

	UPROPERTY()
	float TimerDuration;
	default TimerDuration = 100.f;

	UPROPERTY()
	float Timer;

	bool bTimerIsActive;

	bool bTimerIsSet = false;

	float AudioTimer = 1.f;

	UPROPERTY(Category = "References")
	AHomeworkTimer HomeworkTimer;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHomeworkChallenge::BeginPlay_Implementation();
		
		HomeConnectPaper.PaperIsFilledEvent.AddUFunction(this, n"PaperIsFilled");
		HomeConnectPaper.ChallengeFailedEvent.AddUFunction(this, n"ChallengeFailed");
		HomeworkPen.PenInteractedWithEvent.AddUFunction(this, n"PenInteractedWith");
	}

	UFUNCTION()
	void PenInteractedWith()
	{
		if(!bTimerIsSet)
			StartChallenge();
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
		HomeworkTimer.SetTime(TimerDuration);
		HomeworkPen.ClearTrail();
		bTimerIsSet = true;
		System::SetTimer(this, n"StartTickingTime", 1.5f, false);
	}

	UFUNCTION()
	void StartTickingTime()
	{
		StartConnectTimer();
	}

	UFUNCTION()
	void ChallengeFailed()
	{
		if (HasControl())
			NetChallengeFailed();
	}

	UFUNCTION(NetFunction)
	void NetChallengeFailed()
	{
		HomeConnectPaper.OnChallengeReset();
		FailedChallenge();
		StopConnectTimer();
	}

	UFUNCTION()
	void PaperIsFilled()
	{
		if (HasControl())
			NetPaperIsFilled();
	}

	UFUNCTION(NetFunction)
	void NetPaperIsFilled()
	{
		StopConnectTimer();
		HomeConnectPaper.OnChallengeCompleted();
		System::SetTimer(this, n"ChallengeIsCompleted", 3.f, false);
	}

	UFUNCTION()
	void ChallengeIsCompleted()
	{
		ChallengeCompleted.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (bTimerIsActive)
		{
			Timer -= DeltaTime;
			AudioTimer -= DeltaTime;
			if (AudioTimer <= 0.f)
			{
				AudioTimer = 1.f;
			}
		
			if (Timer <= 0.f)
			{
				ConnectTimerRanOut();
			} else 
			{
				SetConnectTimeText();
			}
		} else 
		{

		}
	}

	UFUNCTION()
	void StartConnectTimer()
	{
		Timer = TimerDuration;
		bTimerIsActive = true;
		HomeworkTimer.StartTimer();
	}

	UFUNCTION()
	void StopConnectTimer()
	{
		bTimerIsActive = false;
		HomeworkTimer.StopTimer();
		bTimerIsSet = false;
	}

	UFUNCTION(BlueprintEvent)
	void SetConnectTimeText()
	{
		// doing this in BP!
	}

	UFUNCTION()
	void ConnectTimerRanOut()
	{
		if (HasControl())
			NetConnectTimerRanOut();
	}

	UFUNCTION(NetFunction)
	void NetConnectTimerRanOut()
	{
		HomeConnectPaper.OnChallengeReset();
		FailedChallenge();
		StopConnectTimer();
	}
}