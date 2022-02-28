import Peanuts.Foghorn.FoghornStatics;
import Cake.Weapons.Hammer.HammerWeaponActor;
import Cake.Weapons.Hammer.HammerWielderComponent;

class UHammerVOCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Audio");
    default CapabilityDebugCategory = n"Audio";
    
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 101;

    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MineMainHubNailTutorialHammerheadApproach;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset SB_MineMainHubNailTutorialHammerheadSuccess;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_NailSwingingHammerhead;
	
    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_EffortNailSwingingHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset SB_MainMineMainHubSecondNail;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset SB_MineMainHubGlassHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MineMachineRoomIntroEnterHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MineMachineRoomIntroCatapultHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset SB_MineMachineRoomActivateSwitchHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MineMachineRoomHalfwayHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MineMachineRoomEndHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset SB_MineMachineRoomEndingHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset SB_MainMineMachineRoomThirdNail;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MainToolBoxBossApproach;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MainToolBoxBossChaseStart;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MainToolBoxBossChase;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_MainToolBoxBossChaseHalfway;

	UPROPERTY(Category = "Voiceover")
    UFoghornDialogueDataAsset SB_MainToolBoxBossChaseHalfwayDialogue;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_HammerSwingHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_HammerCodyHammerhead;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset SB_NailMayHammerhead;


	UHammerWielderComponent	WielderComp = nullptr;

    AHammerWeaponActor Hammer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WielderComp = UHammerWielderComponent::GetOrCreate(Owner);
		Hammer = WielderComp.GetHammer();
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

		if (ConsumeAction(n"FoghornSBMineMainHubNailTutorialHammerheadApproach") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MineMainHubNailTutorialHammerheadApproach, Hammer);
        }
		
		if (ConsumeAction(n"FoghornSBMineMainHubNailTutorialHammerheadSuccess") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_MineMainHubNailTutorialHammerheadSuccess, Hammer);
        }

		if (ConsumeAction(n"FoghornSBNailSwingingHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_NailSwingingHammerhead, Hammer);
        }

		//if (ConsumeAction(n"FoghornSBEffortNailSwingingHammerhead") == EActionStateStatus::Active)
        {
           		//PlayFoghornBark(SB_EffortNailSwingingHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMainMineMainHubSecondNail") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_MainMineMainHubSecondNail, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMineMainHubGlassHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_MineMainHubGlassHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMineMachineRoomIntroEnterHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MineMachineRoomIntroEnterHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMineMachineRoomIntroCatapultHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MineMachineRoomIntroCatapultHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMineMachineRoomActivateSwitchHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_MineMachineRoomActivateSwitchHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMineMachineRoomHalfwayHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MineMachineRoomHalfwayHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMineMachineRoomEndHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MineMachineRoomEndHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMineMachineRoomEndingHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_MineMachineRoomEndingHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMainMineMachineRoomThirdNail") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_MainMineMachineRoomThirdNail, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMainToolBoxBossApproach") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MainToolBoxBossApproach, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMainToolBoxBossChase") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MainToolBoxBossChaseStart, Hammer);
				PlayFoghornBark(SB_MainToolBoxBossChase, Hammer);
        }

		if (ConsumeAction(n"FoghornSBMainToolBoxBossChaseHalfway") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_MainToolBoxBossChaseHalfway, Hammer);
				PlayFoghornDialogue(SB_MainToolBoxBossChaseHalfwayDialogue, Hammer);
        }

		if (ConsumeAction(n"FoghornSBHammerSwingHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_HammerSwingHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBHammerCodyHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_HammerCodyHammerhead, Hammer);
        }

		if (ConsumeAction(n"FoghornSBNailMayHammerhead") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(SB_NailMayHammerhead, Hammer);
        }

    }
}