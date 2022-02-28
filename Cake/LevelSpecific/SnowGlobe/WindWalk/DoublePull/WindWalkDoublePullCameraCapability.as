import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;
import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;

class UWindWalkDoublePullCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullCamera);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AHazePlayerCharacter PlayerOwner;

	AWindWalkDoublePullActor DoublePullActor;
	UDoublePullComponent DoublePullComponent;

	FHazePointOfInterest PointOfInterest;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.Blend = 3.f;
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

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DoublePullComponent = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		DoublePullActor = Cast<AWindWalkDoublePullActor>(DoublePullComponent.Owner);

		PlayerOwner.ApplyCameraOffsetOwnerSpace(FVector::ZeroVector, 2.f, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PointOfInterest.FocusTarget.WorldOffset = DoublePullActor.ActorLocation + DoublePullActor.Spline.Spline.GetDirectionAtSplinePoint(0, ESplineCoordinateSpace::World) * 1000.f + DoublePullActor.ActorForwardVector * 500.f;
		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!DoublePullComponent.AreBothPlayersInteracting())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(DoublePullActor.bIsInStartZone && !DoublePullActor.BothPlayersAreActivatingMagnet())
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