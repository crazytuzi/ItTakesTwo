import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UTreeDarkroomVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeWaspNestDarkRoomIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeWaspNestDarkRoomFlyingAnimal;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeDarkroomPaintingsApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeDarkroomAnimalRideEnd;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeDarkroomAnimalRideEndFall;



		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomLanternGenericCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomLanternGenericMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomPaintingsHouseCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomPaintingsHouseMay;
		
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomFirefliesJumpMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomFirefliesJumpCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomAnimalApproachCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeDarkroomAnimalApproachMay;




	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBTreeWaspNestDarkRoomIntro")
		{
			PlayFoghornDialogue(FoghornSBTreeWaspNestDarkRoomIntro, nullptr);
		}
		else if (EventName == n"FoghornSBTreeWaspNestDarkRoomFlyingAnimal")
		{
			PlayFoghornDialogue(FoghornSBTreeWaspNestDarkRoomFlyingAnimal, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBTreeDarkroomPaintingsApproach")
		{
			PlayFoghornDialogue(FoghornDBTreeDarkroomPaintingsApproach, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomAnimalRideEnd")
		{
			PlayFoghornDialogue(FoghornDBTreeDarkroomAnimalRideEnd, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomAnimalRideEndFall")
		{
			PlayFoghornDialogue(FoghornDBTreeDarkroomAnimalRideEndFall, nullptr);
		}


		//Design Barks - Barks 
		else if (EventName == n"FoghornDBTreeDarkroomLanternGeneric")
		{
			PlayFoghornBark(FoghornDBTreeDarkroomLanternGenericCody, nullptr);
			PlayFoghornBark(FoghornDBTreeDarkroomLanternGenericMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomPaintingsHouseCody")
		{
			PlayFoghornBark(FoghornDBTreeDarkroomPaintingsHouseCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomPaintingsHouseMay")
		{
			PlayFoghornBark(FoghornDBTreeDarkroomPaintingsHouseMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomFirefliesJumpMay")
		{
			PlayFoghornBark(FoghornDBTreeDarkroomFirefliesJumpMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomFirefliesJumpCody")
		{
			PlayFoghornBark(FoghornDBTreeDarkroomFirefliesJumpCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomAnimalApproachCody")
		{
			PlayFoghornBark(FoghornDBTreeDarkroomAnimalApproachCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeDarkroomAnimalApproachMay")
		{
			PlayFoghornBark(FoghornDBTreeDarkroomAnimalApproachMay, nullptr);
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