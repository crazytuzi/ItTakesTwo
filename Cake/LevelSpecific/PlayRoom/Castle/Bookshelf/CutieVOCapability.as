import Peanuts.Foghorn.FoghornStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFleeing;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Cutie;

//Declare name of capability

class UCutieVOCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Audio");
    default CapabilityDebugCategory = n"Audio";
    
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 100;

	//Data asset slots for Foghorn
	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset DB_EffortRunningCutie;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset DB_ClawMachineRunCutie;


	//Declare actor
    ACutieFleeing CutieFleeing;
	ACutie Cutie;

	//Cast to actor
    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        CutieFleeing = Cast<ACutieFleeing>(Owner);
		Cutie = Cast<ACutie>(Owner);
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

	//Use consume action states usually to listen to events sent.
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {   
		if (ConsumeAction(n"FoghornDBEffortRunningCutie") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(DB_EffortRunningCutie, CutieFleeing);
        }

		// if (ConsumeAction(n"FoghornDBClawMachineRunCutie") == EActionStateStatus::Active)
        // {
        //    		PlayFoghornBark(DB_ClawMachineRunCutie, CutieFleeing);
        // }


    }
}