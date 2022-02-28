import Peanuts.Foghorn.FoghornStatics;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBoss;

class UVacuumBossVOCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Audio");
    default CapabilityDebugCategory = n"Audio";
    
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 100;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset GenericTaunt;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset KillTaunt;

    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset RespawnTaunt;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset EndingIdle;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset EndingRaiseTubes;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset FoghornDBShedVacuumBossFightEndIdle;
	
    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset EndingRaiseTubesHalfway;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset EndingRaiseTubesCough;

	
    AVacuumBoss VacuumBoss;


    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        VacuumBoss = Cast<AVacuumBoss>(Owner);
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

		if (ConsumeAction(n"FoghornVacuumBossTaunt") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(GenericTaunt, VacuumBoss);
        }

		if (ConsumeAction(n"FoghornVacuumBossKillTaunt") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(KillTaunt, VacuumBoss);
        }

		if (ConsumeAction(n"FoghornVacuumBossRespawnTaunt") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(RespawnTaunt, VacuumBoss);
        }
		
		if (ConsumeAction(n"FoghornEndingIdle") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(EndingIdle, VacuumBoss);
				PlayFoghornDialogue(FoghornDBShedVacuumBossFightEndIdle, nullptr);
        }

		if (ConsumeAction(n"FoghornEndingRaiseTubes") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(EndingRaiseTubes, VacuumBoss);
        }

		if (ConsumeAction(n"FoghornEndingRaiseTubesHalfway") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(EndingRaiseTubesHalfway, VacuumBoss);
        }

		if (ConsumeAction(n"FoghornEndingRaiseTubesCough") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(EndingRaiseTubesCough, VacuumBoss);
        }

    }
}