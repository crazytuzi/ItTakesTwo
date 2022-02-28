import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHat;
import Cake.LevelSpecific.SnowGlobe.PirateShip.PirateShipWheel;
import Cake.LevelSpecific.SnowGlobe.VOBanks.SnowGlobeLakeVOBank;

class AMagnetHatsPiratesVOManager : AHazeActor
{
	UPROPERTY()
	USnowGlobeLakeVOBank VOBank;

	UPROPERTY(Category = "Pirates VO")
	AMagnetHat PirateHat1;
	
	UPROPERTY(Category = "Pirates VO")
	AMagnetHat PirateHat2;

	UPROPERTY(Category = "Pirates VO")
	APirateShipWheel PirateShipWheel;

	FName VOTogether = n"FoghornDBSnowGlobeLakePirateShipHat";

	FName MayHatVO = n"FoghornDBSnowGlobeLakePirateShipHatSoloMay";
	FName CodyHatVO = n"FoghornDBSnowGlobeLakePirateShipHatSoloCody";

	FName MayPirateSteering = n"FoghornDBSnowGlobeLakePirateShipHatWheelMay";
	FName CodyPirateSteering = n"FoghornDBSnowGlobeLakePirateShipHatWheelCody";

	bool bPlayedPirateHatTogetherVO;
	bool bPlayedMayHatVO;
	bool bPlayedCodyHatVO;

	bool bMayHasPirateHat;
	bool bCodyHasPirateHat;

	bool bMaySpunWheel;
	bool bCodySpunWheel;

	float VOReactionTime;
	float DefaultVOReactionTime = 1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PirateHat1.OnNewAttached.AddUFunction(this, n"PiratesAttachedHat");
		PirateHat2.OnNewAttached.AddUFunction(this, n"PiratesAttachedHat");
		PirateHat1.OnHatDetatched.AddUFunction(this, n"PiratesDetatchedHat");
		PirateHat2.OnHatDetatched.AddUFunction(this, n"PiratesDetatchedHat");
		PirateShipWheel.OnWheelSpin.AddUFunction(this, n"WheelSpun");
		VOReactionTime = DefaultVOReactionTime;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bPlayedPirateHatTogetherVO || !bPlayedCodyHatVO || bPlayedMayHatVO)
		{
			if (bMayHasPirateHat || bCodyHasPirateHat)
			{
				VOReactionTime -= DeltaTime;

				if (VOReactionTime <= 0.f)
				{
					if (bMayHasPirateHat && bCodyHasPirateHat && !bPlayedPirateHatTogetherVO)
					{
						PlayHatPirateTogether();
						bPlayedPirateHatTogetherVO = true;
						VOReactionTime = DefaultVOReactionTime;
					}
					else if (bMayHasPirateHat && !bPlayedMayHatVO)
					{
						PlayHatPirateMay();
						bPlayedMayHatVO = true;
						VOReactionTime = DefaultVOReactionTime;
					}
					else if (bCodyHasPirateHat && !bPlayedCodyHatVO)
					{
						PlayHatPirateCody();
						bPlayedCodyHatVO = true;
						VOReactionTime = DefaultVOReactionTime;
					}
				}
			}
		}
	}

	UFUNCTION()
	void PiratesAttachedHat(AHazePlayerCharacter Player, AMagnetHat MagnetHat)
	{
		if (Player.IsMay())
			bMayHasPirateHat = true;
		else
			bCodyHasPirateHat = true;
	}

	UFUNCTION()
	void PiratesDetatchedHat(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			bMayHasPirateHat = false;
		else
			bCodyHasPirateHat = false;
	}

	UFUNCTION()
	void WheelSpun(AHazePlayerCharacter Player)
	{
		if (Player.IsMay() && !bMaySpunWheel)
		{
			bMaySpunWheel = true;
			PirateWheelPlayMay();
		}
		else if (Player.IsCody() && !bCodySpunWheel)
		{
			bCodySpunWheel = true;
			PirateWheelPlayCody();
		}
	}

	UFUNCTION()
	void PlayHatPirateTogether()
	{
		PlayFoghornVOBankEvent(VOBank, VOTogether);
	}

	UFUNCTION()
	void PlayHatPirateMay()
	{
		PlayFoghornVOBankEvent(VOBank, MayHatVO);
	}

	UFUNCTION()
	void PlayHatPirateCody()
	{
		PlayFoghornVOBankEvent(VOBank, CodyHatVO);
	}

	UFUNCTION()
	void PirateWheelPlayMay()
	{
		PlayFoghornVOBankEvent(VOBank, MayPirateSteering);
	}

	UFUNCTION()
	void PirateWheelPlayCody()
	{
		PlayFoghornVOBankEvent(VOBank, CodyPirateSteering);
	}
}