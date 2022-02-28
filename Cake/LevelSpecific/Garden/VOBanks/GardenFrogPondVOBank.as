import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UGardenFrogPondVOBank : UFoghornVOBankDataAssetBase
{

		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBGardenMoleTunnelsMainFountainPoisonBulbDestroyed;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondSinkingPuzzleCompleteFrogNY;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondScalePuzzleJumpFrogNY;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondPurpleInfectionLilyPadsFrogNY;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondRespawnGenericFrogNY;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondPurpleInfectionLilyPadsFrogFrench;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondFroggerCompleteFrogFrench;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondPurpleInfectionMainFountainPuzzleFrogFrench;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondSinkingPuzzleCompleteFrenchFrog;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondMainFountainPuzzleCompleteFrogFrench;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondFishFountainPuzzleCompleteFrogFrench;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondMainFountainPuzzleTaxiStandFrogNY;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondMainFountainPuzzleTopFrogFrench;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondMainFountainPuzzleHatch;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondGreenhouseMushroom;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondGreenhouseMushroomHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondGreenhouseWindowHalfway;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogPondGreenhouseWindowComplete;

		//Design Barks - Barks 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondGreenhouseWindow;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondGrindSectionBloomingCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondGrindSectionBloomingMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondJumpReactionMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondJumpReactionCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondSinkingPuzzleCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondSinkingPuzzleMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondFishFountainPuzzleHintCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondFishFountainPuzzleHintMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondMainFountainPuzzleHintCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondMainFountainPuzzleHintMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondGenericBarksFrogNY;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogPondGenericBarksFrogFrench;

		//Design Barks - Dialogues (minigames)
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogpondSnailRaceStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogpondSnailRaceCodyWins;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBGardenFrogpondSnailRaceMayWins;

		//Design Barks  Barks (minigames)
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogpondSnailRaceTauntCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogpondSnailRaceTauntMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogpondSnailRaceApproachCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBGardenFrogpondSnailRaceApproachMay;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Story Barks
		if (EventName == n"FoghornSBGardenMoleTunnelsMainFountainPoisonBulbDestroyed")
		{
			PlayFoghornDialogue(FoghornSBGardenMoleTunnelsMainFountainPoisonBulbDestroyed, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBGardenFrogPondSinkingPuzzleCompleteFrogNY")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondSinkingPuzzleCompleteFrogNY, nullptr, Actor2);
		}
		else if (EventName == n"FoghornDBGardenFrogPondScalePuzzleJumpFrogNY")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondScalePuzzleJumpFrogNY, nullptr, Actor2);
		}
		else if (EventName == n"FoghornDBGardenFrogPondPurpleInfectionLilyPadsFrogNY")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondPurpleInfectionLilyPadsFrogNY, nullptr, Actor2);
		}
		else if (EventName == n"FoghornDBGardenFrogPondRespawnGenericFrogNY")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondRespawnGenericFrogNY, nullptr, Actor2);
		}
		else if (EventName == n"FoghornDBGardenFrogPondPurpleInfectionLilyPadsFrogFrench")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondPurpleInfectionLilyPadsFrogFrench, Actor);
		}
		else if (EventName == n"FoghornDBGardenFrogPondFroggerCompleteFrogFrench")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondFroggerCompleteFrogFrench, Actor);
		}
		else if (EventName == n"FoghornDBGardenFrogPondPurpleInfectionMainFountainPuzzleFrogFrench")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondPurpleInfectionMainFountainPuzzleFrogFrench, Actor);
		}
		else if (EventName == n"FoghornDBGardenFrogPondSinkingPuzzleCompleteFrenchFrog")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondSinkingPuzzleCompleteFrenchFrog, Actor);
		}
		else if (EventName == n"FoghornDBGardenFrogPondMainFountainPuzzleCompleteFrogFrench")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondMainFountainPuzzleCompleteFrogFrench, Actor);
		}
		else if (EventName == n"FoghornDBGardenFrogPondFishFountainPuzzleCompleteFrogFrench")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondFishFountainPuzzleCompleteFrogFrench, Actor);
		}
		else if (EventName == n"FoghornDBGardenFrogPondMainFountainPuzzleTaxiStandFrogNY")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondMainFountainPuzzleTaxiStandFrogNY, nullptr, Actor2);
		}
		else if (EventName == n"FoghornDBGardenFrogPondMainFountainPuzzleTopFrogFrench")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondMainFountainPuzzleTopFrogFrench, Actor);
		}
		else if (EventName == n"FoghornDBGardenFrogPondMainFountainPuzzleHatch")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondMainFountainPuzzleHatch, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGreenhouseMushroom")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondGreenhouseMushroom, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGreenhouseMushroomHint")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondGreenhouseMushroomHint, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGreenhouseWindowHalfway")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondGreenhouseWindowHalfway, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGreenhouseWindowComplete")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogPondGreenhouseWindowComplete, nullptr);
		}

		//Design Barks - Barks 
		else if (EventName == n"FoghornDBGardenFrogPondGreenhouseWindow")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondGreenhouseWindow, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGrindSectionBloomingCody")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondGrindSectionBloomingCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGrindSectionBloomingMay")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondGrindSectionBloomingMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondJumpReactionMay")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondJumpReactionMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondJumpReactionCody")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondJumpReactionCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondSinkingPuzzleCody")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondSinkingPuzzleCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondSinkingPuzzleMay")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondSinkingPuzzleMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondFishFountainPuzzleHintCody")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondFishFountainPuzzleHintCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondFishFountainPuzzleHintMay")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondFishFountainPuzzleHintMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondMainFountainPuzzleHintCody")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondMainFountainPuzzleHintCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondMainFountainPuzzleHintMay")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondMainFountainPuzzleHintMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGenericBarksFrogNY")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondGenericBarksFrogNY, Actor2);
		}
		else if (EventName == n"FoghornDBGardenFrogPondGenericBarksFrogFrench")
		{
			PlayFoghornBark(FoghornDBGardenFrogPondGenericBarksFrogFrench, Actor);
		}

		//Design Barks - Dialogues (minigames)
		else if (EventName == n"FoghornDBGardenFrogpondSnailRaceStart")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogpondSnailRaceStart, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogpondSnailRaceCodyWins")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogpondSnailRaceCodyWins, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogpondSnailRaceMayWins")
		{
			PlayFoghornDialogue(FoghornDBGardenFrogpondSnailRaceMayWins, nullptr);
		}

		//Design Barks - Barks (minigames)
		else if (EventName == n"FoghornDBGardenFrogpondSnailRaceTauntCody")
		{
			PlayFoghornBark(FoghornDBGardenFrogpondSnailRaceTauntCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogpondSnailRaceTauntMay")
		{
			PlayFoghornBark(FoghornDBGardenFrogpondSnailRaceTauntMay, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogpondSnailRaceApproachCody")
		{
			PlayFoghornBark(FoghornDBGardenFrogpondSnailRaceApproachCody, nullptr);
		}
		else if (EventName == n"FoghornDBGardenFrogpondSnailRaceApproachMay")
		{
			PlayFoghornBark(FoghornDBGardenFrogpondSnailRaceApproachMay, nullptr);
		}


		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
