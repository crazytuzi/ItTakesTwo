import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UAwakeningVOBank : UFoghornVOBankDataAssetBase
{
		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBShedAwakeningDivorceIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBShedAwakeningFusesocketJumpOut;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBShedAwakeningSawSuccessPart1;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBShedAwakeningSawSuccessPart2;

		
		//Design Barks - dialogues
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBShedAwakeningPeriscope;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBShedAwakeningToolBoxWalk;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBShedAwakeningWireTunnel;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBShedAwakeningGearsGroundPoundCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBShedAwakeningGearsGroundPoundMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBShedAwakeningSawMachineApproach;


		//Design Barks - barks

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningFuseSocketDoubleInteractCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningFuseSocketDoubleInteractMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningThirdFuseStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningThirdFuseGlassApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningThirdFuseGlassBreak;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningThirdFuseSaw;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningOutletMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningOutletCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningContainer;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningSawMachineDoubleInteractCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningSawMachineDoubleInteractMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningToolBoxAsleep;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBShedAwakeningToolBoxGroan;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		if (EventName == n"DummyName")
		{
		}

		//Story Barks

		else if (EventName == n"FoghornSBShedAwakeningDivorceIntro")
		{
			PlayFoghornDialogue(FoghornSBShedAwakeningDivorceIntro, nullptr);
		}
		else if (EventName == n"FoghornSBShedAwakeningFusesocketJumpOut")
		{
			PlayFoghornDialogue(FoghornSBShedAwakeningFusesocketJumpOut, nullptr);
		}
		else if (EventName == n"FoghornSBShedAwakeningSawSuccessPart1")
		{
			PlayFoghornDialogue(FoghornSBShedAwakeningSawSuccessPart1, nullptr);
		}
		else if (EventName == n"FoghornSBShedAwakeningSawSuccessPart2")
		{
			PlayFoghornDialogue(FoghornSBShedAwakeningSawSuccessPart2, nullptr);
		}

		//Design Barks - dialogues

		else if (EventName == n"FoghornDBShedAwakeningPeriscope")
		{
			PlayFoghornDialogue(FoghornDBShedAwakeningPeriscope, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningToolBoxWalk")
		{
			PlayFoghornDialogue(FoghornDBShedAwakeningToolBoxWalk, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningWireTunnel")
		{
			PlayFoghornDialogue(FoghornDBShedAwakeningWireTunnel, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningGearsGroundPoundCody")
		{
			PlayFoghornDialogue(FoghornDBShedAwakeningGearsGroundPoundCody, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningGearsGroundPoundMay")
		{
			PlayFoghornDialogue(FoghornDBShedAwakeningGearsGroundPoundMay, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningSawMachineApproach")
		{
			PlayFoghornDialogue(FoghornDBShedAwakeningSawMachineApproach, nullptr);
		}


		//Designs Barks - barks
		
		else if (EventName == n"FoghornDBShedAwakeningFuseSocketDoubleInteractCody")
		{
			PlayFoghornBark(FoghornDBShedAwakeningFuseSocketDoubleInteractCody, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningFuseSocketDoubleInteractMay")
		{
			PlayFoghornBark(FoghornDBShedAwakeningFuseSocketDoubleInteractMay, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningThirdFuseStart")
		{
			PlayFoghornBark(FoghornDBShedAwakeningThirdFuseStart, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningThirdFuseGlassApproach")
		{
			PlayFoghornBark(FoghornDBShedAwakeningThirdFuseGlassApproach, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningThirdFuseGlassBreak")
		{
			PlayFoghornBark(FoghornDBShedAwakeningThirdFuseGlassBreak, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningThirdFuseSaw")
		{
			PlayFoghornBark(FoghornDBShedAwakeningThirdFuseSaw, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningOutletMay")
		{
			PlayFoghornBark(FoghornDBShedAwakeningOutletMay, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningOutletCody")
		{
			PlayFoghornBark(FoghornDBShedAwakeningOutletCody, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningContainer")
		{
			PlayFoghornBark(FoghornDBShedAwakeningContainer, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningSawMachineDoubleInteractCody")
		{
			PlayFoghornBark(FoghornDBShedAwakeningSawMachineDoubleInteractCody, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningSawMachineDoubleInteractMay")
		{
			PlayFoghornBark(FoghornDBShedAwakeningSawMachineDoubleInteractMay, nullptr);
		}
		else if (EventName == n"FoghornDBShedAwakeningToolBoxAsleep")
		{
			PlayFoghornBark(FoghornDBShedAwakeningToolBoxAsleep, Actor);
		}
		else if (EventName == n"FoghornDBShedAwakeningToolBoxGroan")
		{
			PlayFoghornBark(FoghornDBShedAwakeningToolBoxGroan, Actor);
		}

		else
		{
			DebugLogNoEvent(EventName);
		}

	}
}
