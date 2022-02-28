import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHatManager;
import Cake.LevelSpecific.SnowGlobe.VOBanks.SnowGlobeTownVOBank;

class AMagnetHatsDiscoVOManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	AMagnetHatManager MagnetHatManager;

	UPROPERTY()
	USnowGlobeTownVOBank VOBank;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (MagnetHatManager == nullptr)
			return;

		for (AMagnetHat Hat : MagnetHatManager.Hats)
		{
			Hat.OnNewAttached.AddUFunction(this, n"OnHatAttachedToPlayer");
		}
	}

	UFUNCTION()
	void OnHatAttachedToPlayer(AHazePlayerCharacter Player, AMagnetHat MagnetHat)
	{
		if (Player.IsMay())
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBSnowGlobeTownMagnetHatsGetNewMay");
		else	
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBSnowGlobeTownMagnetHatsGetNewCody");
	}
}