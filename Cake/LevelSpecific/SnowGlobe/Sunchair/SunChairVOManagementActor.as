import Cake.LevelSpecific.SnowGlobe.Sunchair.SunChairInteraction;
import Peanuts.Foghorn.FoghornStatics;
import Cake.LevelSpecific.SnowGlobe.VOBanks.SnowGlobeTownVOBank;

class ASunChairVOManagementActor : AHazeActor
{
	UPROPERTY(Category = "Setup")
	ASunChairInteraction Chair1;

	UPROPERTY(Category = "Setup")
	ASunChairInteraction Chair2;
	
	UPROPERTY()
	USnowGlobeTownVOBank VOBank;

	bool bMayInChair;
	bool bCodyInChair;

	bool bPlayedMaySolo;
	bool bPlayedCodySolo;
	bool bPlayedTogether;
	bool bPlayedAll = false;

	bool bHavePlayed;

	float Timer;
	float MaxTimer = 10.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Chair1.InteractionComp.OnActivated.AddUFunction(this, n"PlayerEntered");
		Chair2.InteractionComp.OnActivated.AddUFunction(this, n"PlayerEntered");
		Chair1.OnPlayerLeft.AddUFunction(this, n"PlayerLeft");
		Chair2.OnPlayerLeft.AddUFunction(this, n"PlayerLeft");
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (bMayInChair || bCodyInChair)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f)
				NetPlayVOCheck();
		}
	}

	UFUNCTION()
	void PlayerEntered(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
			bMayInChair = true;
		else
			bCodyInChair = true;

		if (!IsActorTickEnabled())
			SetActorTickEnabled(true);

		if (!bPlayedTogether && bMayInChair && bCodyInChair)
			Timer = 0.f;
		else
			Timer = 3.f;
	}

	UFUNCTION()
	void PlayerLeft(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
			bMayInChair = false;
		else
			bCodyInChair = false;		

		if (!bMayInChair && !bCodyInChair)
			SetActorTickEnabled(false);
	}

	UFUNCTION(NetFunction)
	void NetPlayVOCheck()
	{
		Timer = MaxTimer;

		if (bCodyInChair && bMayInChair && !bPlayedTogether)
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBSnowGlobeTownSunchairs");
			bPlayedTogether = true;
		}
		else if (bCodyInChair && bMayInChair)
		{
			if (bMayInChair && !bPlayedMaySolo)
			{
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBSnowGlobeTownSunchairsGenericMay");
				bPlayedMaySolo = true;
			}
			else if (bCodyInChair && bPlayedMaySolo)
			{
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBSnowGlobeTownSunchairsGenericCody");
				bPlayedMaySolo = false;
			}		
		} 
		else
		{
			if (bCodyInChair)
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBSnowGlobeTownSunchairsGenericCody");
			else if (bMayInChair)
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBSnowGlobeTownSunchairsGenericMay");
		}
	}
}