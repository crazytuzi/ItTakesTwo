class USkiLiftSequenceLocomotionRequestCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkiLiftLocomotionRequest");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 90;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData LocomotionRequest;
		LocomotionRequest.AnimationTag = n"SkiLift";
		PlayerOwner.RequestLocomotion(LocomotionRequest);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
}