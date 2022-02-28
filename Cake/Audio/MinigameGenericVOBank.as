import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UMinigameGenericVOBank : UFoghornVOBankDataAssetBase
{
		// Story & Design barks - dialogue
		// UPROPERTY(Category = "Zzzhax")
		// UFoghornDialogueDataAsset Zzzhax;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigamePendingStartCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigamePendingStartMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericStartCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericStartMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericTauntCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericTauntMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericFailCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericFailMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericWinCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericWinMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericLoseCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericLoseMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericDrawCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGameplayGlobalMinigameGenericDrawMay;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		//Minigame Design barks - dialogues

		//Design Barks - Barks 
		if (EventName == n"FoghornDBGameplayGlobalMinigamePendingStartCody")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigamePendingStartCody, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigamePendingStartMay")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigamePendingStartMay, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericStartCody")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericStartCody, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericStartMay")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericStartMay, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericTauntCody")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericTauntCody, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericTauntMay")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericTauntMay, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericFailCody")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericFailCody, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericFailMay")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericFailMay, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericWinCody")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericWinCody, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericWinMay")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericWinMay, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericLoseCody")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericLoseCody, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericLoseMay")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericLoseMay, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericDrawCody")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericDrawCody, nullptr);
		}
		else if (EventName == n"FoghornDBGameplayGlobalMinigameGenericDrawMay")
		{
			PlayFoghornBark(FoghornDBGameplayGlobalMinigameGenericDrawMay, nullptr);
		}

		else if (EventName == n"Zzzhax")
		{
			//PlayFoghornDialogue(Zzzhax, Actor);
		}
		
		//Minigame Design barks - barks

		else
		{
			DebugLogNoEvent(EventName);
		}
	}

}