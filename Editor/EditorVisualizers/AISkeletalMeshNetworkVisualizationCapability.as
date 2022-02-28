
class UAISkeletalMeshNetworkVisualizationCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"NetworkMeshVisualization");
	
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UHazeSkeletalMeshNetworkVisualizationComponent VisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AHazeCharacter CharacterOwner = Cast<AHazeCharacter>(Owner);
		if(CharacterOwner != nullptr)
		{
			VisualizerComponent = UHazeSkeletalMeshNetworkVisualizationComponent::Create(Owner);
			VisualizerComponent.MaxDistance = 300.f;
			VisualizerComponent.TriggerDistance = 10.f;
			VisualizerComponent.PowerCurveValue = 2.f;
			VisualizerComponent.Initialize(CharacterOwner.Mesh);
			VisualizerComponent.SetHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsFlag(n"NetworkMeshVisualization", "Shows the network visualization");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (VisualizerComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (!Owner.GetDebugFlag(n"NetworkMeshVisualization"))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Owner.GetDebugFlag(n"NetworkMeshVisualization"))
			return EHazeNetworkDeactivation::DontDeactivate;
		return EHazeNetworkDeactivation::DeactivateLocal;
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
	FString GetDebugString() const
	{
		return "";
	}
};


