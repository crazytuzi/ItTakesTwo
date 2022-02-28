import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;
import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;
import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullHazard;

class UWindWalkDoublePullHazardCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullHazardCamera);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AHazePlayerCharacter PlayerOwner;

	AWindWalkDoublePullActor DoublePullActor;
	UDoublePullComponent DoublePullComponent;

	FHazePointOfInterest PointOfInterest;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		PointOfInterest.Blend = 2.f;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UDoublePullComponent DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		if(DoublePull == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!DoublePull.AreBothPlayersInteracting())
			return EHazeNetworkActivation::DontActivate;

		AWindWalkDoublePullActor WindWalkDoublePull = Cast<AWindWalkDoublePullActor>(DoublePull.Owner);
		if(WindWalkDoublePull.bIsInStartZone && !WindWalkDoublePull.BothPlayersAreActivatingMagnet())
			return EHazeNetworkActivation::DontActivate;

		if(WindWalkDoublePull.SpawnedHazards.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		if(GetAttributeNumber(n"ValidCameraHazardCount") == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DoublePullComponent = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		DoublePullActor = Cast<AWindWalkDoublePullActor>(DoublePullComponent.Owner);

		PlayerOwner.ApplyCameraOffset((-PlayerOwner.ActorForwardVector).ConstrainToPlane(PlayerOwner.MovementWorldUp) * 200.f + PlayerOwner.MovementWorldUp * 100.f, 2.f, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MinDistance = BIG_NUMBER;
		float AverageDistance = 0.f;
		int ValidCameraHazardCount = 0;
		FVector AverageVector = FVector::ZeroVector;
		for(AWindWalkDoublePullHazard Hazard : DoublePullActor.SpawnedHazards)
		{
			if(Hazard.ShouldLoseCameraFocus(DoublePullActor.ActorLocation))
				continue;

			FVector PlayerToHazard = Hazard.ActorLocation - PlayerOwner.ActorLocation;
			if(PlayerToHazard.Size() < MinDistance)
				MinDistance = PlayerToHazard.Size();

			AverageVector += PlayerToHazard.GetSafeNormal();
			AverageDistance += PlayerToHazard.Size();
			ValidCameraHazardCount++;
		}

		AverageVector.Normalize();

		if(ValidCameraHazardCount > 0)
			AverageDistance /= ValidCameraHazardCount;

		PointOfInterest.FocusTarget.WorldOffset = PlayerOwner.ActorLocation + AverageVector * AverageDistance * 0.5f;
		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!DoublePullComponent.AreBothPlayersInteracting())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(DoublePullActor.bIsInStartZone && !DoublePullActor.BothPlayersAreActivatingMagnet())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(DoublePullActor.SpawnedHazards.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(GetAttributeNumber(n"ValidCameraHazardCount") == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.ClearCameraOffsetByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(this);
	}
}