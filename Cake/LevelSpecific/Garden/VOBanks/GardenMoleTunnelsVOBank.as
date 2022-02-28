import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UGardenMoleTunnelsVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsStealthLevelStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsStealthLevelStartEnd;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsFinalChaseOutro;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsShellsReact;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsExploration;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsStealthDialogueFirst;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsStealthDialogueSecond;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenMoleTunnelsAfterStealth;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsSneakyBushTransform;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenMoleTunnelsSneakyBushMoleSneeze;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsSneakyBushDialogueFirst;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsSneakyBushDialogueSecond;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsSneakyBushDialogueThird;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsSneakyBushDialogueFourth;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsStealthEnd;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenMoleTunnelsStartChase;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenMoleTunnelsMoleChaseBelow;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsGroundPoundMoleStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsGroundPoundMoleEnd;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsShellWalkFirstCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsShellWalkFirstMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenMoleTunnelsShellWalkEffortCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenMoleTunnelsShellWalkEffortMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsStealthWarningCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsStealthWarningMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsSneakyBushWarningCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsSneakyBushWarningMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenMoleTunnelsSneakyBushFirstWaterPlant;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsGenericChaseMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsGenericChaseCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsGroundPoundMoleHalfway;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsSlomoSequenceMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornSBGardenMoleTunnelsSlomoSequenceCody;



	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBGardenMoleTunnelsStealthLevelStart")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsStealthLevelStart, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsStealthLevelStartEnd")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsStealthLevelStartEnd, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsFinalChaseOutro")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsFinalChaseOutro, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornSBGardenMoleTunnelsShellsReact")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsShellsReact, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsExploration")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsExploration, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsStealthDialogueFirst")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsStealthDialogueFirst, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsStealthDialogueSecond")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsStealthDialogueSecond, nullptr);
		}
		else if (EventName == n"FoghornDBGardenMoleTunnelsAfterStealth")
		{
			PlayFoghornDialogue(FoghornDBGardenMoleTunnelsAfterStealth, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSneakyBushTransform")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsSneakyBushTransform, nullptr);
		}
		else if (EventName == n"FoghornDBGardenMoleTunnelsSneakyBushMoleSneeze")
		{
			PlayFoghornDialogue(FoghornDBGardenMoleTunnelsSneakyBushMoleSneeze, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSneakyBushDialogueFirst")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsSneakyBushDialogueFirst, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSneakyBushDialogueSecond")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsSneakyBushDialogueSecond, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSneakyBushDialogueThird")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsSneakyBushDialogueThird, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSneakyBushDialogueFourth")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsSneakyBushDialogueFourth, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsStealthEnd")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsStealthEnd, nullptr);
		}
		else if (EventName == n"FoghornDBGardenMoleTunnelsStartChase")
		{
			PlayFoghornDialogue(FoghornDBGardenMoleTunnelsStartChase, nullptr);
		}
		else if (EventName == n"FoghornDBGardenMoleTunnelsMoleChaseBelow")
		{
			PlayFoghornDialogue(FoghornDBGardenMoleTunnelsMoleChaseBelow, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsGroundPoundMoleStart")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsGroundPoundMoleStart, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsGroundPoundMoleEnd")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsGroundPoundMoleEnd, nullptr);
		}

		//Design Barks - Barks 
		else if (EventName == n"FoghornSBGardenMoleTunnelsShellWalkFirstCody")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsShellWalkFirstCody, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsShellWalkFirstMay")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsShellWalkFirstMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenMoleTunnelsShellWalkEffortCody")
		{
			PlayFoghornBark(FoghornDBGardenMoleTunnelsShellWalkEffortCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenMoleTunnelsShellWalkEffortMay")
		{
			PlayFoghornBark(FoghornDBGardenMoleTunnelsShellWalkEffortMay, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsStealthWarningCody")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsStealthWarningCody, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsStealthWarningMay")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsStealthWarningMay, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSneakyBushWarningCody")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsSneakyBushWarningCody, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSneakyBushWarningMay")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsSneakyBushWarningMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenMoleTunnelsSneakyBushFirstWaterPlant")
		{
			PlayFoghornBark(FoghornDBGardenMoleTunnelsSneakyBushFirstWaterPlant, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsGenericChaseMay")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsGenericChaseMay, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsGenericChaseCody")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsGenericChaseCody, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsGroundPoundMoleHalfway")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsGroundPoundMoleHalfway, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSlomoSequenceMay")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsSlomoSequenceMay, nullptr);
		}
		else if (EventName == n"FoghornSBGardenMoleTunnelsSlomoSequenceCody")
		{
			PlayFoghornBark(FoghornSBGardenMoleTunnelsSlomoSequenceCody, nullptr);
		}
		
		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
