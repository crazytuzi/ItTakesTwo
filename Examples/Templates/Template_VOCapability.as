/*import Peanuts.Foghorn.FoghornStatics;

//Declare name of capability

class UFoghornTemplateVOCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Audio");
    default CapabilityDebugCategory = n"Audio";
    
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 100;

	//Data asset slots for Foghorn
	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset Bark01;

	UPROPERTY(Category = "Voiceover")
	UFoghornBarkDataAsset Bark02;

    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset Bark03;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset Bark04;
	
    UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset Bark05;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset Bark06;

	//Declare actor
    AActorName ActorName;

	//Cast to actor
    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        ActorName = Cast<AActorName>(Owner);
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
		if (ConsumeAction(n"FoghornEventName") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(Bark01, ActorName);
        }

		if (ConsumeAction(n"FoghornEventName") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(Bark02, ActorName);
        }

		if (ConsumeAction(n"FoghornEventName") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(Bark03, ActorName);
        }

		if (ConsumeAction(n"FoghornEventName") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(Bark04, ActorName);
        }

		if (ConsumeAction(n"FoghornEventName") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(Bark05, ActorName);
        }

		if (ConsumeAction(n"FoghornEventName") == EActionStateStatus::Active)
        {
           		PlayFoghornBark(Bark06, ActorName);
        }

    }
}