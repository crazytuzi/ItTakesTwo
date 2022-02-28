import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class USnowGlobeForestVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBSnowGlobeForestEntranceIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBSnowGlobeCabinFindSkates;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBSnowGlobeForestGateStuck;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBSnowGlobeForestMagnetTutorialReminderFirst;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBSnowGlobeForestTimberSaw;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBSnowGlobeForestCabinApproach;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestColdReactionsMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestColdReactionsCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestWrongMagnetPullMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestWrongMagnetPullCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestWrongMagnetPushMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestWrongMagnetPushCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestMagnetTutorialCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestMagnetTutorialMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestMagnetTutorialReminderSecondCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestMagnetTutorialReminderSecondMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestSlideEffortCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestSlideEffortMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestReminderGenericCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestReminderGenericMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestTimberApproach;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestIceSkatingStartMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestIceSkatingStartCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestMapExamineMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestMapExamineCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestTimberFallCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestTimberFallMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestSuperMagnetSpottedCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestSuperMagnetSpottedMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestSuperMagnetActivatedCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeForestSuperMagnetActivatedMay;




	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBSnowGlobeForestEntranceIntro")
		{
			PlayFoghornDialogue(FoghornSBSnowGlobeForestEntranceIntro, nullptr);
		}
		else if (EventName == n"FoghornSBSnowGlobeCabinFindSkates")
		{
			PlayFoghornDialogue(FoghornSBSnowGlobeCabinFindSkates, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBSnowGlobeForestGateStuck")
		{
			PlayFoghornDialogue(FoghornDBSnowGlobeForestGateStuck, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestMagnetTutorialReminderFirst")
		{
			PlayFoghornDialogue(FoghornDBSnowGlobeForestMagnetTutorialReminderFirst, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestTimberSaw")
		{
			PlayFoghornDialogue(FoghornDBSnowGlobeForestTimberSaw, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestCabinApproach")
		{
			PlayFoghornDialogue(FoghornDBSnowGlobeForestCabinApproach, nullptr);
		}

		//Design Barks - Barsk 
		else if (EventName == n"FoghornDBSnowGlobeForestColdReactionsMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestColdReactionsMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestColdReactionsCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestColdReactionsCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestWrongMagnetPullMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestWrongMagnetPullMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestWrongMagnetPullCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestWrongMagnetPullCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestWrongMagnetPushMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestWrongMagnetPushMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestWrongMagnetPushCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestWrongMagnetPushCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestMagnetTutorialCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestMagnetTutorialCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestMagnetTutorialMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestMagnetTutorialMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestMagnetTutorialReminderSecondCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestMagnetTutorialReminderSecondCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestMagnetTutorialReminderSecondMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestMagnetTutorialReminderSecondMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestSlideEffortCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestSlideEffortCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestSlideEffortMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestSlideEffortMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestReminderGenericCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestReminderGenericCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestReminderGenericMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestReminderGenericMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestTimberApproach")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestTimberApproach, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestIceSkatingStartMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestIceSkatingStartMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestIceSkatingStartCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestIceSkatingStartCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestMapExamineMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestMapExamineMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestMapExamineCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestMapExamineCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestTimberFall")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestTimberFallCody, nullptr);
			PlayFoghornBark(FoghornDBSnowGlobeForestTimberFallMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestSuperMagnetSpottedCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestSuperMagnetSpottedCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestSuperMagnetSpottedMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestSuperMagnetSpottedMay, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestSuperMagnetActivatedCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestSuperMagnetActivatedCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeForestSuperMagnetActivatedMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeForestSuperMagnetActivatedMay, nullptr);
		}


		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
