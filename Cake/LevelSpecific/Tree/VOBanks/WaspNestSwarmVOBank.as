import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UWaspNestSwarmVOBank : UFoghornVOBankDataAssetBase
{
	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornDBTreeWaspNestSwarmHammer;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeWaspNestSwarmDamage;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeWaspNestSwarmDamageGenericCody;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeWaspNestSwarmDamageGenericMay;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset FoghornDBTreeWaspNestSwarmKill;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeWaspNestSwarmRevive;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeWaspNestSwarmFloorBreak;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeWaspNestSwarmStart;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		if(EventName == n"FoghornDBTreeWaspNestSwarmHammer")
			PlayFoghornDialogue(FoghornDBTreeWaspNestSwarmHammer, Actor);
		else if(EventName == n"FoghornDBTreeWaspNestSwarmDamage")
			PlayFoghornBark(FoghornDBTreeWaspNestSwarmDamage, Actor);
		else if(EventName == n"FoghornDBTreeWaspNestSwarmDamageGenericCody")
			PlayFoghornBark(FoghornDBTreeWaspNestSwarmDamageGenericCody, Actor);
		else if(EventName == n"FoghornDBTreeWaspNestSwarmDamageGenericMay")
			PlayFoghornBark(FoghornDBTreeWaspNestSwarmDamageGenericMay, Actor);
		else if(EventName == n"FoghornDBTreeWaspNestSwarmKill")
			PlayFoghornDialogue(FoghornDBTreeWaspNestSwarmKill, Actor);
		else if(EventName == n"FoghornDBTreeWaspNestSwarmRevive")
			PlayFoghornBark(FoghornDBTreeWaspNestSwarmRevive, Actor);
		else if(EventName == n"FoghornDBTreeWaspNestSwarmFloorBreak")
			PlayFoghornBark(FoghornDBTreeWaspNestSwarmFloorBreak, Actor);
		else if (EventName == n"FoghornDBTreeWaspNestSwarmStart")
			PlayFoghornBark(FoghornDBTreeWaspNestSwarmStart, nullptr);

		else
			DebugLogNoEvent(EventName);
	}

}
