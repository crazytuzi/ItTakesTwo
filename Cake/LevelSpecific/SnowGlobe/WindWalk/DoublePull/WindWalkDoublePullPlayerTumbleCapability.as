import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;

class UWindWalkDoublePullPlayerTumbleCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullPlayerTumble);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AHazePlayerCharacter PlayerOwner;
	AWindWalkDoublePullActor DoublePullActor;
	UDoublePullComponent DoublePullComponent;

	const float MaxHorizontalOffset = 100.f;
	const float TimeToReachHorizontalOffset = 3.f;

	float OffsetDirection = 1.f;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		// This is assuming May will always be on the left side
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		if(PlayerOwner.IsMay())
			OffsetDirection *= -1.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UObject DoublePullObject = GetAttributeObject(n"DoublePull");
		if(DoublePullObject == nullptr)
			return EHazeNetworkActivation::DontActivate;

		UDoublePullComponent DoublePull = Cast<UDoublePullComponent>(DoublePullObject);
		if(!DoublePull.AreBothPlayersInteracting())
			return EHazeNetworkActivation::DontActivate;

		if(!PlayerOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger))
			return EHazeNetworkActivation::DontActivate;

		if(!Cast<AWindWalkDoublePullActor>(DoublePull.Owner).bIsTumbling)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DoublePullComponent = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		DoublePullActor = Cast<AWindWalkDoublePullActor>(DoublePullComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;

		// Get offset
		float NormalOffset = Math::Saturate(ElapsedTime / TimeToReachHorizontalOffset);
		float HorizontalOffset = MaxHorizontalOffset * DoublePullComponent.EffortCurve.GetFloatValue(NormalOffset) * OffsetDirection;

		// Add noise to offset
		float OffsetMultiplier = FMath::PerlinNoise1D(ElapsedTime * 0.5f);

		// Apply local offset
		FVector RelativeLocationOffset = PlayerOwner.ActorTransform.InverseTransformVector(DoublePullActor.ActorRightVector) * HorizontalOffset;
		PlayerOwner.MeshOffsetComponent.OffsetRelativeLocationWithTime(RelativeLocationOffset + RelativeLocationOffset * OffsetMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!DoublePullComponent.AreBothPlayersInteracting())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(!PlayerOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!DoublePullActor.bIsTumbling)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.MeshOffsetComponent.ResetRelativeLocationWithTime(0.5f);
		ElapsedTime = 0.f;
	}
}