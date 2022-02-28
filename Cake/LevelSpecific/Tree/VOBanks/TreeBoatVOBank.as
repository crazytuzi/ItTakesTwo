import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UTreeBoatVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBTreeWaspNestBoatRiver;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeBoatWallImpactSecond;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeBoatWallImpactThird;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeBoatLarvaeSpotted;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeBoatDamApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeBoatUpstream;
		
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeBoatTornadoSpotted;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeBoatWallImpactFirst;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeBoatAcceleration;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeBoatAccelerationEffortMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeBoatAccelerationEffortCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeBoatLarvaeImpactCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeBoatLarvaeImpactMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeBoatWobbleHardCody;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		//Story Barks
		if (EventName == n"FoghornSBTreeWaspNestBoatRiver")
		{
			PlayFoghornDialogue(FoghornSBTreeWaspNestBoatRiver, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBTreeBoatWallImpactSecond")
		{
			PlayFoghornDialogue(FoghornDBTreeBoatWallImpactSecond, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatWallImpactThird")
		{
			PlayFoghornDialogue(FoghornDBTreeBoatWallImpactThird, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatLarvaeSpotted")
		{
			PlayFoghornDialogue(FoghornDBTreeBoatLarvaeSpotted, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatDamApproach")
		{
			PlayFoghornDialogue(FoghornDBTreeBoatDamApproach, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatUpstream")
		{
			PlayFoghornDialogue(FoghornDBTreeBoatUpstream, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatTornadoSpotted")
		{
			PlayFoghornDialogue(FoghornDBTreeBoatTornadoSpotted, nullptr);
		}

		//Design Barks - Barks 
		else if (EventName == n"FoghornDBTreeBoatWallImpactFirst")
		{
			PlayFoghornBark(FoghornDBTreeBoatWallImpactFirst, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatAcceleration")
		{
			PlayFoghornBark(FoghornDBTreeBoatAcceleration, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatAccelerationEffortMay")
		{
			PlayFoghornBark(FoghornDBTreeBoatAccelerationEffortMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatAccelerationEffortCody")
		{
			PlayFoghornBark(FoghornDBTreeBoatAccelerationEffortCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatLarvaeImpact")
		{
			PlayFoghornBark(FoghornDBTreeBoatLarvaeImpactCody, nullptr);
			PlayFoghornBark(FoghornDBTreeBoatLarvaeImpactMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeBoatWobbleHard")
		{
			PlayFoghornBark(FoghornDBTreeBoatWobbleHardCody, nullptr);
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
