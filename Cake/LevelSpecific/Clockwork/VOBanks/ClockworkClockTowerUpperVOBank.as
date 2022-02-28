import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UClockworkClockTowerUpperVOBank : UFoghornVOBankDataAssetBase
{
	//Story Barks
	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornSBClockworkUpperTowerClockBossApproach;

	//Design Barks - Dialogues 
	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornDBClockworkUpperTowerClockBossPendulumHalfway;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornSBClockworkUpperTowerClockBossFreeFall;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornDBClockworkUpperTowerClockBossFreeFallHalfway;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornSBClockworkUpperTowerClockBossBombsStart;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornDBClockworkUpperTowerClockBossFinalExplosionStart;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornDBClockworkUpperTowerClockBossFinalExplosionHalfway;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornSBClockworkUpperTowerClockBossSprintPhase;

	//Design Barks - Barks 
	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornSBClockworkUpperTowerClockBossBombsHintMay;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornSBClockworkUpperTowerClockBossBombsHintCody;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornSBClockworkUpperTowerClockBossStart;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornSBClockworkUpperTowerClockBossPendulumGenericMay;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornSBClockworkUpperTowerClockBossPendulumGenericCody;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBClockworkUpperTowerClockBossFinalExplosionEnd;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		//Story Barks
		if (EventName == n"FoghornSBClockworkUpperTowerClockBossApproach")
		{
			PlayFoghornDialogue(FoghornSBClockworkUpperTowerClockBossApproach, nullptr);
		}
		
		//Design Barks - Dialogues 
		else if(EventName == n"FoghornDBClockworkUpperTowerClockBossPendulumHalfway")
		{
			PlayFoghornDialogue(FoghornDBClockworkUpperTowerClockBossPendulumHalfway, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossFreeFall")
		{
			PlayFoghornDialogue(FoghornSBClockworkUpperTowerClockBossFreeFall, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkUpperTowerClockBossFreeFallHalfway")
		{
			PlayFoghornDialogue(FoghornDBClockworkUpperTowerClockBossFreeFallHalfway, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossBombsStart")
		{
			PlayFoghornDialogue(FoghornSBClockworkUpperTowerClockBossBombsStart, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkUpperTowerClockBossFinalExplosionStart")
		{
			PlayFoghornDialogue(FoghornDBClockworkUpperTowerClockBossFinalExplosionStart, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkUpperTowerClockBossFinalExplosionHalfway")
		{
			PlayFoghornDialogue(FoghornDBClockworkUpperTowerClockBossFinalExplosionHalfway, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossSprintPhase")
		{
			PlayFoghornDialogue(FoghornSBClockworkUpperTowerClockBossSprintPhase, nullptr);
		}


		//Design Barks - Barks 
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossBombsHintMay")
		{
			PlayFoghornBark(FoghornSBClockworkUpperTowerClockBossBombsHintMay, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossBombsHintCody")
		{
			PlayFoghornBark(FoghornSBClockworkUpperTowerClockBossBombsHintCody, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossStart")
		{
			PlayFoghornBark(FoghornSBClockworkUpperTowerClockBossStart, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossPendulumGenericMay")
		{
			PlayFoghornBark(FoghornSBClockworkUpperTowerClockBossPendulumGenericMay, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkUpperTowerClockBossPendulumGenericCody")
		{
			PlayFoghornBark(FoghornSBClockworkUpperTowerClockBossPendulumGenericCody, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkUpperTowerClockBossFinalExplosionEnd")
		{
			PlayFoghornBark(FoghornDBClockworkUpperTowerClockBossFinalExplosionEnd, nullptr);
		}



		else
		{
			DebugLogNoEvent(EventName);
		}

		// if (EventName == n"ExampleBarkAsset")
		// {
		// 	PlayFoghornBark(ExampleBarkAsset, nullptr);
		// }
		// else if (EventName == n"ExampleDialogueAsset")
		// {
		// 	PlayFoghornDialogue(ExampleDialogueAsset, nullptr);
		// }
	}
}
