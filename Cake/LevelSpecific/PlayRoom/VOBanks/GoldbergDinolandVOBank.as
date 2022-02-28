import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UGoldbergDinolandVOBank : UFoghornVOBankDataAssetBase
{

	//Design Barks
	// UPROPERTY(Category = "Voiceover")
	// UFoghornBarkDataAsset ExampleBarkAsset;

	// UPROPERTY(Category = "Voiceover")
	// UFoghornDialogueDataAsset ExampleDialogueAsset;

	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Design Barks
		if (EventName == n"DummyName")
		{
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
