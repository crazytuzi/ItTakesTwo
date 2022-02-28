import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

class USnowGlobeIceSkatingVOBank : UFoghornVOBankDataAssetBase
{

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeIceSkatingCheerCody;

		UPROPERTY(Category = "Voiceover")
		UFoghornBarkDataAsset FoghornDBSnowGlobeIceSkatingCheerMay;


	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4)
	{

		//Ice Skating Cheers - Barks
		if (EventName == n"FoghornDBSnowGlobeIceSkatingCheerCody")
		{
			PlayFoghornBark(FoghornDBSnowGlobeIceSkatingCheerCody, nullptr);
		}
		else if (EventName == n"FoghornDBSnowGlobeIceSkatingCheerMay")
		{
			PlayFoghornBark(FoghornDBSnowGlobeIceSkatingCheerMay, nullptr);
		}


		else
		{
			DebugLogNoEvent(EventName);
		}
	}
}
