import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UCastleDungeonVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBPlayRoomCastleDungeonToyCrusher;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayroomCastleDungeonTeleporterSpotted;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayroomCastleDungeonFirePlatforms;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomCastleDungeonToyCrusherHalfway;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomCastleDungeonToyCrusherDead;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayroomCastleDungeonChargerInitial;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonTeleportPuzzleStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonTeleportPuzzleSwitch;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonTeleportPuzzleDoor;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonDashPuzzle;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonDashPuzzleSuccess;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonFirePlatformPuzzle;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonFirePlatformPuzzleSuccess;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonTeleporterHintMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonTeleporterHintCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonSpikeTrapApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomCastleDungeonToyCrusherGate;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonChargerDamageHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonChargerChainHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonChargerFirePit;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonUltimateMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleDungeonUltimateCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleFireTornadoFirstReactionCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleIceBeamFirstReactionMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardPawnWarningMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardPawnWarningCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardBishopWarningMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardBishopWarningCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardRookWarningMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardRookWarningCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardKnightWarningMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardKnightWarningCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardFireDamageCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomCastleChessboardFireDamageMay;






	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBPlayRoomCastleDungeonToyCrusher")
		{
			PlayFoghornDialogue(FoghornSBPlayRoomCastleDungeonToyCrusher, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBPlayroomCastleDungeonTeleporterSpotted")
		{
			PlayFoghornDialogue(FoghornDBPlayroomCastleDungeonTeleporterSpotted, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonFirePlatforms")
		{
			PlayFoghornDialogue(FoghornDBPlayroomCastleDungeonFirePlatforms, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomCastleDungeonToyCrusherHalfway")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomCastleDungeonToyCrusherHalfway, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomCastleDungeonToyCrusherDead")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomCastleDungeonToyCrusherDead, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonChargerInitial")
		{
			PlayFoghornDialogue(FoghornDBPlayroomCastleDungeonChargerInitial, nullptr);
		}

		//Design Barks - Barks 
		else if (EventName == n"FoghornDBPlayroomCastleDungeonTeleportPuzzleStart")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonTeleportPuzzleStart, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonTeleportPuzzleSwitch")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonTeleportPuzzleSwitch, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonTeleportPuzzleDoor")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonTeleportPuzzleDoor, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonDashPuzzle")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonDashPuzzle, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonDashPuzzleSuccess")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonDashPuzzleSuccess, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonFirePlatformPuzzle")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonFirePlatformPuzzle, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonFirePlatformPuzzleSuccess")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonFirePlatformPuzzleSuccess, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonTeleporterHintMay")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonTeleporterHintMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonTeleporterHintCody")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonTeleporterHintCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonSpikeTrapApproach")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonSpikeTrapApproach, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomCastleDungeonToyCrusherGate")
		{
			PlayFoghornBark(FoghornDBPlayRoomCastleDungeonToyCrusherGate, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonChargerDamageHint")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonChargerDamageHint, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonChargerChainHint")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonChargerChainHint, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonChargerFirePit")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonChargerFirePit, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonUltimateMay")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonUltimateMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleDungeonUltimateCody")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleDungeonUltimateCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleFireTornadoFirstReactionCody")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleFireTornadoFirstReactionCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleIceBeamFirstReactionMay")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleIceBeamFirstReactionMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardPawnWarningMay")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardPawnWarningMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardPawnWarningCody")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardPawnWarningCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardBishopWarningMay")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardBishopWarningMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardBishopWarningCody")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardBishopWarningCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardRookWarningMay")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardRookWarningMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardRookWarningCody")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardRookWarningCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardKnightWarningMay")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardKnightWarningMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardKnightWarningCody")
		{
			PlayFoghornBark(FoghornDBPlayroomCastleChessboardKnightWarningCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardFireDamageCody")
		{
			PlayFoghornEffort(FoghornDBPlayroomCastleChessboardFireDamageCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomCastleChessboardFireDamageMay")
		{
			PlayFoghornEffort(FoghornDBPlayroomCastleChessboardFireDamageMay, nullptr);
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
