import Peanuts.Foghorn.FoghornStatics;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;


class UBullBossVOCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Audio");
    default CapabilityDebugCategory = n"Audio";
    
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 100;


	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset DB_BullBossChargePlatform;


    AClockworkBullBoss BullBoss;

	AHazePlayerCharacter PlayerOwner;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BullBoss = Cast<AClockworkBullBoss>(Owner);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
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

		if (ConsumeAction(n"FoghornDBBullBossChargePlatform") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(DB_BullBossChargePlatform, nullptr);
        }

	}
}