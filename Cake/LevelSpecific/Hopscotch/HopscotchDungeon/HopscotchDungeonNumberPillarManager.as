import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonNumberPillar;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonPenBars;
import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonNumberPillarPlatform;
event void FNumberPillarChallengeCompleted();
class AHopscotchDungeonNumberPillarManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TArray<AHopscotchDungeonNumberPillar> NumberPillarArray;

	UPROPERTY()
	FNumberPillarChallengeCompleted NumberPillarChallengeCompleted;

	UPROPERTY()
	AHopscotchNumberPillarPlatform Platform;

	bool bChallangeActive = false;
	bool bGameOver = false;

	int NumberOfPillarsJumpedOn = 0;

	float GameOverTimer = 5.f;
	bool bShouldTickGameOverTimer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Pillar : NumberPillarArray)
			Pillar.PlayerLandedOnPillarEvent.AddUFunction(this, n"PlayerLandedOnPillar");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			if (bChallangeActive && !bGameOver)
			{
				for(auto Player : Game::GetPlayers())
				{
					if (Player.IsPlayerDead())
					{
						bChallangeActive = false;
						NetChallengeFailed();
					}
				}
			}
		}

		if (bShouldTickGameOverTimer)
		{
			GameOverTimer -= DeltaTime;
			if (GameOverTimer <= 0.f)
			{
				bShouldTickGameOverTimer = false;
				bGameOver = false;
				GameOverTimer = 5.f;
			}
		}
	}

	UFUNCTION(CallInEditor)
	void SetPillarArray()
	{
		GetAllActorsOfClass(NumberPillarArray);
	}

	UFUNCTION(NetFunction)
	void NetChallengeFailed()
	{
		NumberOfPillarsJumpedOn = 0;
		bChallangeActive = false;
		bGameOver = true;
		bShouldTickGameOverTimer = true;

		for(auto Pillar : NumberPillarArray)
		{
			if (Pillar.bPillarIsUp)
				Pillar.MovePillar(false, 1.f, 0.f);
			
			if (Pillar.Number == 1)
				Pillar.MovePillar(true, 1.f, 0.f);
		}
		
		Platform.MovePlatform(false);
	}

	UFUNCTION()
	void ChallengeCompleted()
	{
		if (bGameOver)
			return;

		bGameOver = true;
		NumberPillarChallengeCompleted.Broadcast();
	}

	UFUNCTION()
	void PlayerLandedOnPillar(AHazePlayerCharacter Player, int Number, AHopscotchDungeonNumberPillar PillarActor)
	{

		if (bGameOver && Number != 1)
			return;
		else
		{
			bShouldTickGameOverTimer = false;
			GameOverTimer = 5.f;
			bGameOver = false;
		}

		bChallangeActive = true;

		//Verify that Puzzle hasnt failed / pillar isnt moving down.
		if (Number == 9 && PillarActor.bPillarIsUp)
		{
			ChallengeCompleted();
			return;
		}

		if (Number > NumberOfPillarsJumpedOn)
		{
			NumberOfPillarsJumpedOn = Number;

			for(auto Pillar : NumberPillarArray)
			{
				if (Pillar.Number == (NumberOfPillarsJumpedOn + 1))
					Pillar.MovePillar(true, .25f, 0.f);
				else if (Pillar.Number == NumberOfPillarsJumpedOn)
					Pillar.MovePillar(false, 7.5f, 0.f);
			}

			if (Number == 1)
			{
				Platform.MovePlatform(true);
			}
		}
	}
}