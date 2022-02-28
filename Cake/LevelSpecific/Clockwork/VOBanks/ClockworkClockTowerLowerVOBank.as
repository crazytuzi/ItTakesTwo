import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UClockworkClockTowerLowerVOBank : UFoghornVOBankDataAssetBase
{
		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBClockworkLowerTowerTimeIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBClockworkLowerTowerBridgeLongRun;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBClockworkLowerTowerStatueRoomIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBClockworkLowerTowerElevatorRoomIntro;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerCrusherRoom;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerBullBossStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerElevatorRoomHalfway;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerElevatorRoomEnd;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerPocketWatchRoomEnd;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerEvilBirdGlassPlatform;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerCrusherRoomComplete;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerBullBossFirstHit;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerBullBossSecondHit;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBClockworkLowerTowerBullBossEnd;


		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerBullBossPostFight;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerBullBossPostFightCodyLands;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerEvilBirdGenericMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerEvilBirdGenericCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerDoubleInteractHintCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerDoubleInteractHintMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerElevatorRoomDeathMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerElevatorRoomDeathCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerPocketWatchRoomHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerBullBossChargeTutorial;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerBullBossChargeWarning;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerStatueRoom;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerKeysSpottedMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerKeysSpottedCody;
		
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBClockworkLowerTowerCrusherRoomMayTeleport;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBClockworkLowerTowerTimeIntro")
		{
			PlayFoghornDialogue(FoghornSBClockworkLowerTowerTimeIntro, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkLowerTowerBridgeLongRun")
		{
			PlayFoghornDialogue(FoghornSBClockworkLowerTowerBridgeLongRun, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkLowerTowerStatueRoomIntro")
		{
			PlayFoghornDialogue(FoghornSBClockworkLowerTowerStatueRoomIntro, nullptr);
		}
		else if (EventName == n"FoghornSBClockworkLowerTowerElevatorRoomIntro")
		{
			PlayFoghornDialogue(FoghornSBClockworkLowerTowerElevatorRoomIntro, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBClockworkLowerTowerCrusherRoom")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerCrusherRoom, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossStart")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerBullBossStart, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerElevatorRoomHalfway")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerElevatorRoomHalfway, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerElevatorRoomEnd")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerElevatorRoomEnd, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerPocketWatchRoomEnd")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerPocketWatchRoomEnd, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerEvilBirdGlassPlatform")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerEvilBirdGlassPlatform, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerCrusherRoomComplete")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerCrusherRoomComplete, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossFirstHit")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerBullBossFirstHit, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossSecondHit")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerBullBossSecondHit, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossEnd")
		{
			PlayFoghornDialogue(FoghornDBClockworkLowerTowerBullBossEnd, nullptr);
		}

		//Design Barks - Barks 
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossPostFight")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerBullBossPostFight, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossPostFightCodyLands")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerBullBossPostFightCodyLands, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerEvilBirdGenericMay")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerEvilBirdGenericMay, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerEvilBirdGenericCody")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerEvilBirdGenericCody, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerDoubleInteractHintCody")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerDoubleInteractHintCody, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerDoubleInteractHintMay")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerDoubleInteractHintMay, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerElevatorRoomDeathMay")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerElevatorRoomDeathMay, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerElevatorRoomDeathCody")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerElevatorRoomDeathCody, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerPocketWatchRoomHint")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerPocketWatchRoomHint, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossChargeTutorial")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerBullBossChargeTutorial, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerBullBossChargeWarning")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerBullBossChargeWarning, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerStatueRoom")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerStatueRoom, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerKeysSpottedMay")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerKeysSpottedMay, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerKeysSpottedCody")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerKeysSpottedCody, nullptr);
		}
		else if (EventName == n"FoghornDBClockworkLowerTowerCrusherRoomMayTeleport")
		{
			PlayFoghornBark(FoghornDBClockworkLowerTowerCrusherRoomMayTeleport, nullptr);
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
