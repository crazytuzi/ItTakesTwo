import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UShelfVOBank : UFoghornVOBankDataAssetBase
{
		//Story & Design barks - dialogue
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomElephantBookShelfIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBBossFightClawMachine;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBBossFightClawMachineStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBBossFightClawMachineMiss;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomBookshelfTowerhangFinish;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBBossFightClawMachineHangPull;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBBossFightDragged;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomBookshelfLegPullGetStuck;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomBookshelfToEdgeHangApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomBookshelfEdgeHangStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomBookshelfEdgeHangEndCutie;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomBookshelfDraggedStart;

		//Design barks - barks




	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		//Story & Design barks - dialogues
		if (EventName == n"FoghornDBPlayRoomElephantBookShelfIntro")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomElephantBookShelfIntro, Actor);
		}
		else if (EventName == n"FoghornDBBossFightClawMachine")
		{
			PlayFoghornDialogue(FoghornDBBossFightClawMachine, nullptr);
		}
		else if (EventName == n"FoghornDBBossFightClawMachineStart")
		{
			PlayFoghornDialogue(FoghornDBBossFightClawMachineStart, nullptr);
		}
		else if (EventName == n"FoghornDBBossFightClawMachineMiss")
		{
			PlayFoghornDialogue(FoghornDBBossFightClawMachineMiss, Actor);
		}
		else if (EventName == n"FoghornDBPlayRoomBookshelfTowerhangFinish")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomBookshelfTowerhangFinish, nullptr);
		}
		else if (EventName == n"FoghornDBBossFightClawMachineHangPull")
		{
			PlayFoghornDialogue(FoghornDBBossFightClawMachineHangPull, Actor);
		}
		else if (EventName == n"FoghornDBBossFightDragged")
		{
			PlayFoghornDialogue(FoghornDBBossFightDragged, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomBookshelfLegPullGetStuck")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomBookshelfLegPullGetStuck, Actor);
		}
		else if (EventName == n"FoghornDBPlayRoomBookshelfToEdgeHangApproach")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomBookshelfToEdgeHangApproach, Actor);
		}
		else if (EventName == n"FoghornDBPlayRoomBookshelfEdgeHangStart")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomBookshelfEdgeHangStart, Actor);
		}
		else if (EventName == n"FoghornDBPlayRoomBookshelfEdgeHangEndCutie")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomBookshelfEdgeHangEndCutie, Actor);
		}
		else if (EventName == n"FoghornDBPlayRoomBookshelfDraggedStart")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomBookshelfDraggedStart, Actor);
		}

		//Design barks - barks



		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
