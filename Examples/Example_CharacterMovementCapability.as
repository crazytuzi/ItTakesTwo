import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UExampleCharacterMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 40;
	

	FName DeactivationType = NAME_None;

	float InactiveTimer = 0.f;
	float ActiveTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (DeactivationType != NAME_None)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}


	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)const
	{
	}

	void LoadActivationVariables(const FCapabilityActivationParams& ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
	}

	
	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
        FHazeFrameMovement ExampleMove = MoveComp.MakeFrameMovement(n"ExampleMove");
        MoveCharacter(ExampleMove, FeatureName::LedgeGrab);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		return DebugText;
	}

};
