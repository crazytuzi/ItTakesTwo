import Peanuts.Foghorn.FoghornStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.HopscotchVOBank;
event void FHomeworkChallengeSignature(AHomeworkChallenge Challenge);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkChallenge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;	
	
	UPROPERTY()
	FHomeworkChallengeSignature ChallengeCompleted;

	UPROPERTY()
	FHomeworkChallengeSignature ChallengeFailed;

	UPROPERTY()
	UHopscotchVOBank VOBank;

	float FailVoTimer = 2.f;
	bool bShouldTickFailVoTimer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickFailVoTimer)
		{
			FailVoTimer += DeltaTime;
			if (FailVoTimer >= 2.f)
			{
				bShouldTickFailVoTimer = false;
				FailVoTimer = 0.f;
				PlayFailVO();
			}
		}
	}

	UFUNCTION()
	void CompleteChallenge()
	{
		ChallengeCompleted.Broadcast(this);
	}

	UFUNCTION()
	void DebugCompleteChallenge()
	{
		ChallengeCompleted.Broadcast(this);
	}

	UFUNCTION()
	void FailedChallenge()
	{
		ChallengeFailed.Broadcast(this);
		bShouldTickFailVoTimer = true;

		// Timer doesn't trigger for scripts inherited by this one??
		//System::SetTimer(this, n"PlayFailVO", 2.f, false);
	}

	void PlayFailVO()
	{
		int Rand = FMath::RandRange(0, 1);
		if (Rand == 1)
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayRoomHopscotchChallengeFailMay");
		else
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayRoomHopscotchChallengeFailCody");
	}

	void StartChallenge()
	{
		
	}
}