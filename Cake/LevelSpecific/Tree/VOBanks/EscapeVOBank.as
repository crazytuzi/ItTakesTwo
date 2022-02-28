import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UEscapeVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeSquirrelTurfReturnFlight;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeEscapeFlightChase;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeEscapePlaneCombat;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeEscapeNoseDiveCrash;

		//Design Barks - dialogues

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeEscapeCannonShoot;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeEscapeFirstGatesClose;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeEscapePlaneBoost;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeEscapeTunnel;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeEscapeUpRavine;

		// Design Barks - Barks

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapePlaneBoostEffortCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapePlaneBoostEffortMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeGenericKill;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeLowHealth;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeCatapultApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeBigCannonApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeStrawBarrier;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeStrawBarrierEffortCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeStrawBarrierEffortMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeBossFightLowHealth;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeSquirrelFighterSpawnCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeSquirrelFighterSpawnMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeTunnelExitDropEffortCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeEscapeTunnelExitDropEffortMay;




	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBTreeSquirrelTurfReturnFlight")
		{
			PlayFoghornDialogue(FoghornSBTreeSquirrelTurfReturnFlight, nullptr);
		}
		else if (EventName == n"FoghornSBTreeEscapeFlightChase")
		{
			PlayFoghornDialogue(FoghornSBTreeEscapeFlightChase, nullptr);
		}
		else if (EventName == n"FoghornSBTreeEscapePlaneCombat")
		{
			PlayFoghornDialogue(FoghornSBTreeEscapePlaneCombat, nullptr);
		}
		else if (EventName == n"FoghornSBTreeEscapeNoseDiveCrash")
		{
			PlayFoghornDialogue(FoghornSBTreeEscapeNoseDiveCrash, nullptr);
		}

		//Design Barks - Dialogues

		else if (EventName == n"FoghornDBTreeEscapeCannonShoot")
		{
			PlayFoghornDialogue(FoghornDBTreeEscapeCannonShoot, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeFirstGatesClose")
		{
			PlayFoghornDialogue(FoghornDBTreeEscapeFirstGatesClose, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapePlaneBoost")
		{
			PlayFoghornDialogue(FoghornDBTreeEscapePlaneBoost, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeTunnel")
		{
			PlayFoghornDialogue(FoghornDBTreeEscapeTunnel, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeUpRavine")
		{
			PlayFoghornDialogue(FoghornDBTreeEscapeUpRavine, nullptr);
		}

		//Design Barks - Barks

		else if (EventName == n"FoghornDBTreeEscapePlaneBoostEffortCody")
		{
			PlayFoghornBark(FoghornDBTreeEscapePlaneBoostEffortCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapePlaneBoostEffortMay")
		{
			PlayFoghornBark(FoghornDBTreeEscapePlaneBoostEffortMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeGenericKill")
		{
			PlayFoghornBark(FoghornDBTreeEscapeGenericKill, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeLowHealth")
		{
			PlayFoghornBark(FoghornDBTreeEscapeLowHealth, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeCatapultApproach")
		{
			PlayFoghornBark(FoghornDBTreeEscapeCatapultApproach, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeBigCannonApproach")
		{
			PlayFoghornBark(FoghornDBTreeEscapeBigCannonApproach, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeStrawBarrier")
		{
			PlayFoghornBark(FoghornDBTreeEscapeStrawBarrier, nullptr);
			PlayFoghornBark(FoghornDBTreeEscapeStrawBarrierEffortCody, nullptr);
			PlayFoghornBark(FoghornDBTreeEscapeStrawBarrierEffortMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeBossFightLowHealth")
		{
			PlayFoghornBark(FoghornDBTreeEscapeBossFightLowHealth, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeSquirrelFighterSpawnCody")
		{
			PlayFoghornBark(FoghornDBTreeEscapeSquirrelFighterSpawnCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeSquirrelFighterSpawnMay")
		{
			PlayFoghornBark(FoghornDBTreeEscapeSquirrelFighterSpawnMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeEscapeTunnelExitDropEffort")
		{
			PlayFoghornBark(FoghornDBTreeEscapeTunnelExitDropEffortCody, nullptr);
			PlayFoghornBark(FoghornDBTreeEscapeTunnelExitDropEffortMay, nullptr);
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
