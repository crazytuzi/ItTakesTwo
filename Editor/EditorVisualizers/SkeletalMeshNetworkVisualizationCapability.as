
class USkeletalMeshNetworkVisualizationCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"NetworkMeshVisualization");
	
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UHazeSkeletalMeshNetworkVisualizationComponent VisualizerComponent;
	AHazePlayerCharacter PlayerOwner;
	UHazeCrumbComponent CrumbComp;
	bool bShouldBeActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);

		VisualizerComponent = UHazeSkeletalMeshNetworkVisualizationComponent::Create(Owner);
		VisualizerComponent.MaxDistance = 300.f;
		VisualizerComponent.TriggerDistance = 10.f;
		VisualizerComponent.PowerCurveValue = 2.f;
		VisualizerComponent.Initialize(PlayerOwner.Mesh);
		VisualizerComponent.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler FreezeHandler = DebugValues.AddFunctionCall(n"ToggleNetworkMeshVisualization", "Show Network Ghost");
		FreezeHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Network");
	}

	UFUNCTION(NotBlueprintCallable)
	void ToggleNetworkMeshVisualization()
	{
		bShouldBeActive = !bShouldBeActive;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (VisualizerComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!bShouldBeActive)
		 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bShouldBeActive)
		  	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		VisualizerComponent.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		VisualizerComponent.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		VisualizerComponent.DestroyComponent(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HasControl())
		{
			VisualizerComponent.SetGhostColor(FLinearColor(16.f, 16.f, 0.f));
		}
		else
		{
			VisualizerComponent.SetGhostColor(FLinearColor(0.f, 16.f, 0.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		return "";
	}
};


