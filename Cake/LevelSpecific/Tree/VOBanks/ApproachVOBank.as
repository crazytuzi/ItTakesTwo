import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UApproachVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeApproachRoofSwingPart1;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeApproachRoofSwingPart2;


		//Design Barks - dialogues
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeApproachReminder;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeApproachLevelSwing;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeApproachWindows;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeApproachShoes;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeApproachEndApproach;


		//Design Barks - barks
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeApproachPaperPlaneMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeApproachPaperPlaneCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeApproachEndDoubleInteractMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeApproachEndDoubleInteractCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeApproachMushroomsCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeApproachMushroomsMay;



	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		
		//Story Barks
		if (EventName == n"FoghornSBTreeApproachRoofSwingPart1")
		{
			PlayFoghornDialogue(FoghornSBTreeApproachRoofSwingPart1, nullptr);
		}
		else if (EventName == n"FoghornSBTreeApproachRoofSwingPart2")
		{
			PlayFoghornDialogue(FoghornSBTreeApproachRoofSwingPart2, nullptr);
		}


		//Design Barks - dialogues
		else if (EventName == n"FoghornDBTreeApproachReminder")
		{
			PlayFoghornDialogue(FoghornDBTreeApproachReminder, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachLevelSwing")
		{
			PlayFoghornDialogue(FoghornDBTreeApproachLevelSwing, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachWindows")
		{
			PlayFoghornDialogue(FoghornDBTreeApproachWindows, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachShoes")
		{
			PlayFoghornDialogue(FoghornDBTreeApproachShoes, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachEndApproach")
		{
			PlayFoghornDialogue(FoghornDBTreeApproachEndApproach, nullptr);
		}


		//Design Barks - barks
		else if (EventName == n"FoghornDBTreeApproachPaperPlaneMay")
		{
			PlayFoghornBark(FoghornDBTreeApproachPaperPlaneMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachPaperPlaneCody")
		{
			PlayFoghornBark(FoghornDBTreeApproachPaperPlaneCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachEndDoubleInteractMay")
		{
			PlayFoghornBark(FoghornDBTreeApproachEndDoubleInteractMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachEndDoubleInteractCody")
		{
			PlayFoghornBark(FoghornDBTreeApproachEndDoubleInteractCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachMushroomsCody")
		{
			PlayFoghornBark(FoghornDBTreeApproachMushroomsCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeApproachMushroomsMay")
		{
			PlayFoghornBark(FoghornDBTreeApproachMushroomsMay, nullptr);
		}



		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
