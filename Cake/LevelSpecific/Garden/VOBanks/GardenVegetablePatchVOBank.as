import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UGardenVegetablePatchVOBank : UFoghornVOBankDataAssetBase
{
		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenVegetablePatchEntranceIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenVegetablePatchEntranceOutro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenVegetablePatchGreenhouseIntro;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchDandelionTransform;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchFirstCactusSpotted;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchFirstCactus;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchFirstEnemySpawn;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchFirstEnemyComplete;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchBeanstalk;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchBeanstalkVinesCluster;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenVegetablePatchBurrowerEnd;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSickleReact;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSickleReactBulb;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchVineWhipReact;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchVineWhipReactBulb;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchDandelionInfection;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchPotSpotted;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchPotBloom;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchDandelionHintFirst;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchDandelionHintSecond;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchDandelionPitTraversal;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchDandelionAcrossSuccess;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchWaterPlantHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchBeanstalkMax;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchBurrowerWhipHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchBurrowerSickleHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchBurrowerEnemySpawn;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchEnterSpaCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchEnterSpaMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaMeditatingCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaMeditatingMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaShowerCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaShowerMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaFootMassageMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaFootMassageCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaAcupunctureMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaAcupunctureCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaLarvaMassageMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenVegetablePatchSpaLarvaMassageCody;




	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBGardenVegetablePatchEntranceIntro")
		{
			PlayFoghornDialogue(FoghornSBGardenVegetablePatchEntranceIntro, nullptr);
		}
		else if (EventName == n"FoghornSBGardenVegetablePatchEntranceOutro")
		{
			PlayFoghornDialogue(FoghornSBGardenVegetablePatchEntranceOutro, nullptr);
		}
		else if (EventName == n"FoghornSBGardenVegetablePatchGreenhouseIntro")
		{
			PlayFoghornDialogue(FoghornSBGardenVegetablePatchGreenhouseIntro, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBGardenVegetablePatchDandelionTransform")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchDandelionTransform, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchFirstCactusSpotted")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchFirstCactusSpotted, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchFirstCactus")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchFirstCactus, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchFirstEnemySpawn")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchFirstEnemySpawn, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchFirstEnemyComplete")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchFirstEnemyComplete, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchBeanstalk")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchBeanstalk, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchBeanstalkVinesCluster")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchBeanstalkVinesCluster, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchBurrowerEnd")
		{
			PlayFoghornDialogue(FoghornDBGardenVegetablePatchBurrowerEnd, nullptr);
		}

		//Design Barks - Barks 
			else if (EventName == n"FoghornDBGardenVegetablePatchSickleReact")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSickleReact, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSickleReactBulb")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSickleReactBulb, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchVineWhipReact")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchVineWhipReact, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchVineWhipReactBulb")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchVineWhipReactBulb, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchDandelionInfection")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchDandelionInfection, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchPotSpotted")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchPotSpotted, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchPotBloom")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchPotBloom, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchDandelionHintFirst")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchDandelionHintFirst, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchDandelionHintSecond")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchDandelionHintSecond, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchDandelionPitTraversal")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchDandelionPitTraversal, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchDandelionAcrossSuccess")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchDandelionAcrossSuccess, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchWaterPlantHint")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchWaterPlantHint, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchBeanstalkMax")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchBeanstalkMax, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchBurrowerWhipHint")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchBurrowerWhipHint, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchBurrowerSickleHint")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchBurrowerSickleHint, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchBurrowerEnemySpawn")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchBurrowerEnemySpawn, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchEnterSpaCody")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchEnterSpaCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchEnterSpaMay")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchEnterSpaMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaMeditatingCody")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaMeditatingCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaMeditatingMay")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaMeditatingMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaShowerCody")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaShowerCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaShowerMay")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaShowerMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaFootMassageMay")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaFootMassageMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaFootMassageCody")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaFootMassageCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaAcupunctureMay")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaAcupunctureMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaAcupunctureCody")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaAcupunctureCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaLarvaMassageMay")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaLarvaMassageMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenVegetablePatchSpaLarvaMassageCody")
		{
			PlayFoghornBark(FoghornDBGardenVegetablePatchSpaLarvaMassageCody, nullptr);
		}


		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
