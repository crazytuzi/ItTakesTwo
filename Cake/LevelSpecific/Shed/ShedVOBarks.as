import Peanuts.Foghorn.FoghornStatics;
import Cake.Weapons.Hammer.HammerWeaponActor;
import Cake.Weapons.Hammer.HammerWielderComponent;

class UShedVOCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Audio");
    default CapabilityDebugCategory = n"Audio";
    
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 100;


	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset SB_ShedAwakeningDivorceIntro;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset SB_ShedAwakeningFusesocketJumpOut;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset SB_ShedAwakeningSawSuccessPart1;

	UPROPERTY(Category = "Voiceover")
	UFoghornDialogueDataAsset SB_ShedAwakeningSawSuccessPart2;


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

		if (ConsumeAction(n"FoghornSBShedAwakeningDivorceIntro") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_ShedAwakeningDivorceIntro, nullptr);
        }

		if (ConsumeAction(n"FoghornSBShedAwakeningFusesocketJumpOut") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_ShedAwakeningFusesocketJumpOut, nullptr);
        }

		if (ConsumeAction(n"FoghornSBShedAwakeningSawSuccessPart1") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_ShedAwakeningSawSuccessPart1, nullptr);
        }

		if (ConsumeAction(n"FoghornSBShedAwakeningSawSuccessPart2") == EActionStateStatus::Active)
        {
           		PlayFoghornDialogue(SB_ShedAwakeningSawSuccessPart2, nullptr);
        }

	}
}