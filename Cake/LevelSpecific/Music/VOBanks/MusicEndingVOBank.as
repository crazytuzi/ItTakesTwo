import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UMusicEndingVOBank : UFoghornVOBankDataAssetBase
{
	// UPROPERTY(Category = "Voiceover")
	// UFoghornBarkDataAsset ExampleBarkAsset;

	// UPROPERTY(Category = "Voiceover")
	// UFoghornDialogueDataAsset ExampleDialogueAsset;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBMusicEndingFirstWalkOutsideDressingRoom;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBMusicEndingSecondWalkBeforeFlipSwitch;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBMusicEndingThirdWalkBeforeCurtains;




	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Design Barks - Barks 
		if (EventName == n"FoghornDBMusicEndingFirstWalkOutsideDressingRoom")
		{
			PlayFoghornBark(FoghornDBMusicEndingFirstWalkOutsideDressingRoom, nullptr);
		}
		else if (EventName == n"FoghornDBMusicEndingSecondWalkBeforeFlipSwitch")
		{
			PlayFoghornBark(FoghornDBMusicEndingSecondWalkBeforeFlipSwitch, nullptr);
		}
		else if (EventName == n"FoghornDBMusicEndingThirdWalkBeforeCurtains")
		{
			PlayFoghornBark(FoghornDBMusicEndingThirdWalkBeforeCurtains, nullptr);
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
