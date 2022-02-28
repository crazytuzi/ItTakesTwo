import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonBoss;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboon;
import Peanuts.Foghorn.FoghornStatics;

class UMoonBaboonBossVOCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Audio");
    default CapabilityDebugCategory = n"Audio";
    
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 100;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset ChargeUpLaserPointerBark;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset LaserPointerTauntBark;

    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset LaserArrayBark;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset LaserArrayFinalBark;
	
    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset LaserBombBark;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset RocketApproachBark;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset TauntBark;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset HitReactionOnMoon;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset TauntOnMoonInitialBark;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset TauntOnMoonBark;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset ShieldOnMoon;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset LaserPointerKillTaunt;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset LaserPointerRespawnTaunt;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SlamLaserKillTaunt;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SlamLaserRespawnTaunt;

	
    AMoonBaboonBoss MoonBaboon;
	AMoonBaboon MoonBaboonOnMoon;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        MoonBaboon = Cast<AMoonBaboonBoss>(Owner);
		MoonBaboonOnMoon = Cast<AMoonBaboon>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        return EHazeNetworkDeactivation::DontDeactivate;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {

    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
    
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {   
		if (ConsumeAction(n"FoghornChargeUpLaserPointer") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(ChargeUpLaserPointerBark, MoonBaboon);
        }

		if (ConsumeAction(n"FoghornLaserPointerTaunt") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(LaserPointerTauntBark, MoonBaboon);
        }

        if (ConsumeAction(n"FoghornLaserSpinnerStarts") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(LaserArrayBark, MoonBaboon);
        }

		if (ConsumeAction(n"FoghornLaserSpinnerFinalStarts") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(LaserArrayFinalBark, MoonBaboon);
        }

		if (ConsumeAction(n"FoghornLaserBombsStart") == EActionStateStatus::Active)
        {
				PlayFoghornBark(LaserBombBark, MoonBaboon);			
        }

		if (ConsumeAction(n"FoghornRocketApproach") == EActionStateStatus::Active)
        {
				PlayFoghornBark(RocketApproachBark, MoonBaboon);			
        }

		if (ConsumeAction(n"FoghornMoonBaboonTaunt") == EActionStateStatus::Active)
        {
				PlayFoghornBark(TauntBark, MoonBaboon);			
        }

		if (ConsumeAction(n"FoghornMoonBaboonTauntOnMoonInitial") == EActionStateStatus::Active)
        {
				PlayFoghornBark(TauntOnMoonInitialBark, MoonBaboonOnMoon);			
        }

		if (ConsumeAction(n"FoghornMoonBaboonHitReactionOnMoon") == EActionStateStatus::Active)
        {
				PlayFoghornBark(HitReactionOnMoon, MoonBaboonOnMoon);			
        }

		if (ConsumeAction(n"FoghornMoonBaboonShieldOnMoon") == EActionStateStatus::Active)
        {
				PlayFoghornBark(ShieldOnMoon, MoonBaboonOnMoon);			
        }

		if (ConsumeAction(n"FoghornMoonBaboonTauntOnMoon") == EActionStateStatus::Active)
        {
				PlayFoghornBark(TauntOnMoonBark, MoonBaboonOnMoon);			
        }

		if (ConsumeAction(n"FoghornLaserPointerKillTaunt") == EActionStateStatus::Active)
        {
				PlayFoghornBark(LaserPointerKillTaunt, MoonBaboon);			
        }

		if (ConsumeAction(n"FoghornLaserPointerRespawnTaunt") == EActionStateStatus::Active)
        {
				PlayFoghornBark(LaserPointerRespawnTaunt, MoonBaboon);			
        }

		if (ConsumeAction(n"FoghornSlamLaserKillTaunt") == EActionStateStatus::Active)
        {
				PlayFoghornBark(SlamLaserKillTaunt, MoonBaboon);			
        }

		if (ConsumeAction(n"FoghornSlamLaserRespawnTaunt") == EActionStateStatus::Active)
        {
				PlayFoghornBark(SlamLaserRespawnTaunt, MoonBaboon);			
        }
    }
}