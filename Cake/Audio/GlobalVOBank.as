import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UGlobalVOBank : UFoghornVOBankDataAssetBase
{
		// Story & Design barks - dialogue
		// UPROPERTY(Category = "Zzzhax")
		// UFoghornDialogueDataAsset Zzzhax;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayBacktrackGenericMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayBacktrackGenericCody;

		


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		//Design barks - dialogues

		//Design Barks - Barks 
		if (EventName == n"FoghornDBGameplayBacktrackGenericMay")
		{
			PlayFoghornBark(FoghornDBGameplayBacktrackGenericMay, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayBacktrackGenericCody")
		{
			PlayFoghornBark(FoghornDBGameplayBacktrackGenericCody, nullptr);
		}
		

		else
		{
			DebugLogNoEvent(EventName);
		}
	}

}