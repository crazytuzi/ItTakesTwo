import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UPillowFortVOBank : UFoghornVOBankDataAssetBase
{
		//Story Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBPlayRoomPillowFortLandingIntro;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornSBPlayRoomPillowFortFinalRoom;

		//Design Barks - Dialogues 
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomPillowFortHackingGameFirstScreenHint;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomPillowFortHackingGameGeneric;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomPillowFortHackingGameCounterHack;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomPillowFortFigurines;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayRoomPillowFortDollsDialogue;

		//Design Barks - Bark 
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortHackingGameDoubleInteractCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortHackingGameDoubleInteractMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortHackingGameCounterHackMidway;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortLavaLampCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortLavaLampMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortFigurinesApproachCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortFigurinesApproachMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortOrbLampInteractMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortOrbLampInteractCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortFlashlightInteractMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortFlashlightInteractCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortDollsBarksVincent;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayRoomPillowFortDollsBarksLeo;

		//Design Barks - Dialogues (minigame)
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayroomPillowfortHazeBoyTankBrothersStart;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayroomPillowfortHazeBoyTankBrothersCodyWins;

		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBPlayroomPillowfortHazeBoyTankBrothersMayWins;

		//Design Barks - Barks (minigames)
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomPillowfortTankBrothersApproachCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomPillowfortTankBrothersApproachMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntMay;





	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		//Story Barks
		if (EventName == n"FoghornSBPlayRoomPillowFortLandingIntro")
		{
			PlayFoghornDialogue(FoghornSBPlayRoomPillowFortLandingIntro, nullptr);
		}
		else if (EventName == n"FoghornSBPlayRoomPillowFortFinalRoom")
		{
			PlayFoghornDialogue(FoghornSBPlayRoomPillowFortFinalRoom, nullptr);
		}

		//Design Barks - Dialogues 
		else if (EventName == n"FoghornDBPlayRoomPillowFortHackingGameFirstScreenHint")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomPillowFortHackingGameFirstScreenHint, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortHackingGameGeneric")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomPillowFortHackingGameGeneric, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortHackingGameCounterHack")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomPillowFortHackingGameCounterHack, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortFigurines")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomPillowFortFigurines, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortDollsDialogue")
		{
			PlayFoghornDialogue(FoghornDBPlayRoomPillowFortDollsDialogue, Actor, Actor2);
		}

		//Design Barks - Bark 
		else if (EventName == n"FoghornDBPlayRoomPillowFortHackingGameDoubleInteractCody")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortHackingGameDoubleInteractCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortHackingGameDoubleInteractMay")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortHackingGameDoubleInteractMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortHackingGameCounterHackMidway")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortHackingGameCounterHackMidway, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortLavaLampCody")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortLavaLampCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortLavaLampMay")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortLavaLampMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortFigurinesApproachCody")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortFigurinesApproachCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortFigurinesApproachMay")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortFigurinesApproachMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortOrbLampInteractMay")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortOrbLampInteractMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortOrbLampInteractCody")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortOrbLampInteractCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortFlashlightInteractMay")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortFlashlightInteractMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortFlashlightInteractCody")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortFlashlightInteractCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortDollsBarksVincent")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortDollsBarksVincent, Actor2);
		}
		else if (EventName == n"FoghornDBPlayRoomPillowFortDollsBarksLeo")
		{
			PlayFoghornBark(FoghornDBPlayRoomPillowFortDollsBarksLeo, Actor);
		}

		//Design Barks - Dialogues (minigames)
		else if (EventName == n"FoghornDBPlayroomPillowfortHazeBoyTankBrothersStart")
		{
			PlayFoghornDialogue(FoghornDBPlayroomPillowfortHazeBoyTankBrothersStart, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomPillowfortHazeBoyTankBrothersCodyWins")
		{
			PlayFoghornDialogue(FoghornDBPlayroomPillowfortHazeBoyTankBrothersCodyWins, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomPillowfortHazeBoyTankBrothersMayWins")
		{
			PlayFoghornDialogue(FoghornDBPlayroomPillowfortHazeBoyTankBrothersMayWins, nullptr);
		}

		//Design Barks - Barks (minigames)
		else if (EventName == n"FoghornDBPlayroomPillowfortTankBrothersApproachCody")
		{
			PlayFoghornBark(FoghornDBPlayroomPillowfortTankBrothersApproachCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomPillowfortTankBrothersApproachMay")
		{
			PlayFoghornBark(FoghornDBPlayroomPillowfortTankBrothersApproachMay, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntCody")
		{
			PlayFoghornBark(FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntCody, nullptr);
		}
		else if (EventName == n"FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntMay")
		{
			PlayFoghornBark(FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntMay, nullptr);
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
