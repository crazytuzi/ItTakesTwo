import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UWaspQueenBossVOBank : UFoghornVOBankDataAssetBase
{

		//Design Barks
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightFirstPhaseHammerWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightFirstPhaseArmorDamagedWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightFirstPhaseArmorDestroyedWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightFirstPhaseFlamethrowerWaspQueenHalfway;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseInitialWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseDamaged;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseShieldWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseHandWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseArmorDestroyedWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseWaspPlaneWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseNewHandWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseSwordWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightSecondPhaseScissorsWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightThirdPhaseInitialWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightThirdPhaseSwordWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightThirdPhaseShieldWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightThirdPhaseHandWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightTauntGenericWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightPlayerDeathGenericWaspQueen;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBBossFightPlayerReviveGenericWaspQueen;

		//Design Barks - Dialogues (Cody + May)
		UPROPERTY(Category = "Voiceover")
		UFoghornDialogueDataAsset FoghornDBTreeWaspNestWaspQueenThirdPhase;

		//Design Barks - Barks (Cody + May)
		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeWaspNestWaspQueenDamage;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeWaspNestWaspQueenFlamethrower;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeWaspNestWaspQueenWeakSpotBackCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeWaspNestWaspQueenWeakSpotBackMay;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeWaspNestWaspQueenBombsCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBTreeWaspNestWaspQueenBombsMay;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Design Barks
		if (EventName == n"FoghornDBBossFightFirstPhaseHammerWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightFirstPhaseHammerWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightFirstPhaseArmorDamagedWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightFirstPhaseArmorDamagedWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightFirstPhaseArmorDestroyedWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightFirstPhaseArmorDestroyedWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightFirstPhaseFlamethrowerWaspQueenHalfway")
		{
			PlayFoghornBark(FoghornDBBossFightFirstPhaseFlamethrowerWaspQueenHalfway, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseInitialWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseInitialWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseDamaged")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseDamaged, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseShieldWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseShieldWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseHandWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseHandWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseArmorDestroyedWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseArmorDestroyedWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseWaspPlaneWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseWaspPlaneWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseNewHandWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseNewHandWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseSwordWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseSwordWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightSecondPhaseScissorsWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightSecondPhaseScissorsWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightThirdPhaseInitialWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightThirdPhaseInitialWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightThirdPhaseSwordWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightThirdPhaseSwordWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightThirdPhaseShieldWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightThirdPhaseShieldWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightThirdPhaseHandWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightThirdPhaseHandWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightTauntGenericWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightTauntGenericWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightPlayerDeathGenericWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightPlayerDeathGenericWaspQueen, Actor);
		}
		else if (EventName == n"FoghornDBBossFightPlayerReviveGenericWaspQueen")
		{
			PlayFoghornBark(FoghornDBBossFightPlayerReviveGenericWaspQueen, Actor);
		}

		//Design Barks - Dialogues (Cody + May)
		else if (EventName == n"FoghornDBTreeWaspNestWaspQueenThirdPhase")
		{
			PlayFoghornDialogue(FoghornDBTreeWaspNestWaspQueenThirdPhase, nullptr);
		}

		//Design Barks - Barks (Cody + May)
		else if (EventName == n"FoghornDBTreeWaspNestWaspQueenDamage")
		{
			PlayFoghornBark(FoghornDBTreeWaspNestWaspQueenDamage, nullptr);
		}
		else if (EventName == n"FoghornDBTreeWaspNestWaspQueenFlamethrower")
		{
			PlayFoghornBark(FoghornDBTreeWaspNestWaspQueenFlamethrower, nullptr);
		}
		else if (EventName == n"FoghornDBTreeWaspNestWaspQueenWeakSpotBackCody")
		{
			PlayFoghornBark(FoghornDBTreeWaspNestWaspQueenWeakSpotBackCody, nullptr);
		}
		else if (EventName == n"FoghornDBTreeWaspNestWaspQueenWeakSpotBackMay")
		{
			PlayFoghornBark(FoghornDBTreeWaspNestWaspQueenWeakSpotBackMay, nullptr);
		}
		else if (EventName == n"FoghornDBTreeWaspNestWaspQueenBombs")
		{
			PlayFoghornBark(FoghornDBTreeWaspNestWaspQueenBombsMay, nullptr);
			PlayFoghornBark(FoghornDBTreeWaspNestWaspQueenBombsCody, nullptr);
		}

		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
