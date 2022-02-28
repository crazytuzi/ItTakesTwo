import Cake.LevelSpecific.Hopscotch.RotatingPlatformManager;

class URotatingPlatformCapability : UHazeCapability
{

    ARotatingPlatformManager RotatingPlatformManager;

	default CapabilityTags.Add(n"RotatingPlatform");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"AffectRollingPlatform")) 
            return EHazeNetworkActivation::ActivateFromControl;

        else
            return EHazeNetworkActivation::DontActivate;
             
        // return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!IsActioning(n"AffectRollingPlatform"))
		    return EHazeNetworkDeactivation::DeactivateFromControl;

        else
		    return EHazeNetworkDeactivation::DontDeactivate;

		// return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        RotatingPlatformManager = Cast<ARotatingPlatformManager>(GetAttributeObject(n"RotatingPlatformManagerAttribute"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
        RotatingPlatformManager.ReceiveInputAxis(GetInputAxis(), Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

    UFUNCTION()
    float GetInputAxis()
    {
        FVector MovementRaw = GetAttributeVector(AttributeVectorNames::MovementRaw);
        float InputFloat = MovementRaw.Size();
        return InputFloat;
    }
}