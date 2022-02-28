import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class UWaspNestWaternadoVOBank : UFoghornVOBankDataAssetBase
{
	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeBoatTornadoCloseCody;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeBoatTornadoCloseMay;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeBoatTornadoInsideEffortCody;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeBoatTornadoInsideEffortMay;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset FoghornDBTreeBoatTornadoFreeFall;

	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{
		if(EventName == n"FoghornDBTreeBoatTornadoCloseCody")
			PlayFoghornBark(FoghornDBTreeBoatTornadoCloseCody, Actor);
		else if(EventName == n"FoghornDBTreeBoatTornadoCloseMay")
			PlayFoghornBark(FoghornDBTreeBoatTornadoCloseMay, Actor);
		else if(EventName == n"FoghornDBTreeBoatTornadoInsideEffortCody")
			PlayFoghornBark(FoghornDBTreeBoatTornadoInsideEffortCody, Actor);
		else if(EventName == n"FoghornDBTreeBoatTornadoInsideEffortMay")
			PlayFoghornBark(FoghornDBTreeBoatTornadoInsideEffortMay, Actor);
		else if(EventName == n"FoghornDBTreeBoatTornadoFreeFall")
			PlayFoghornBark(FoghornDBTreeBoatTornadoFreeFall, Actor);
		else
			DebugLogNoEvent(EventName);
	}

}
