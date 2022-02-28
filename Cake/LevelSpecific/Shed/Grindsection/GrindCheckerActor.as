import Vino.Movement.Grinding.UserGrindComponent;

event void FPlayerGrindStateChangedSignature();
class AGrindChecker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "Grinding")
	FPlayerGrindStateChangedSignature BothPlayersGrinding;

	UPROPERTY(Category = "Grinding")
	FPlayerGrindStateChangedSignature OnePlayerGrinding;

	UPROPERTY(Category = "Grinding")
	FPlayerGrindStateChangedSignature NoPlayersGrindedForTime;

	UPROPERTY(Category = "Grinding")
	FPlayerGrindStateChangedSignature NoPlayersGrinding;

	UPROPERTY(Category = "Grinding")
	float TimeUntilSendNoPlayersGrinded = 10;

	

	int PlayersGrinding = 0;
	FTimerHandle Timer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto player : Game::Players)
		{
			UUserGrindComponent::Get(player).OnGrindSplineAttached.AddUFunction(this, n"PlayerStartedGrinding");
			UUserGrindComponent::Get(player).OnGrindSplineDetached.AddUFunction(this, n"PlayerStoppedGrinding");
		}
	}

	UFUNCTION()
	void PlayerStartedGrinding(AGrindspline GrindSpline, EGrindAttachReason Reason)
	{
		PlayersGrinding++;
		System::InvalidateTimerHandle(Timer);

		if (PlayersGrinding == 2)
		{
			BothPlayersGrinding.Broadcast();
		}

		if (PlayersGrinding == 1)
		{
			OnePlayerGrinding.Broadcast();
		}
	}

	UFUNCTION()
	void PlayerStoppedGrinding(AGrindspline GrindSpline, EGrindDetachReason Reason)
	{
		PlayersGrinding--;

		if (PlayersGrinding == 1)
		{
			OnePlayerGrinding.Broadcast();
		}

		if (PlayersGrinding == 0)
		{
			NoPlayersGrinding.Broadcast();

			if (!System::TimerExistsHandle(Timer))
			{
				Timer = System::SetTimer(this, n"NoPlayersGrindedForXTime", TimeUntilSendNoPlayersGrinded, false);
			}
		}
	}

	UFUNCTION()
	void NoPlayersGrindedForXTime()
	{
		NoPlayersGrindedForTime.Broadcast();
	}
}
