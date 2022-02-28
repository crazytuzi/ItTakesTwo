import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;

class UBeanstalkLeafPreviewCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	ABeanstalk Beanstalk;
	UBeanstalkSettings Settings;

	float CurrentPreviewScale = 1.0f;

	FQuat PreviewRotationCurrent;

	FHazeAcceleratedVector LeafPairLocation;

	float DistanceCurrent = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
		Settings = UBeanstalkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Beanstalk.bSpawningDone)
			return EHazeNetworkActivation::DontActivate;

		if(Beanstalk.SplineComp.NumberOfSplinePoints < 2)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Beanstalk.bBeanstalkActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Beanstalk.SplineComp.NumberOfSplinePoints < 2)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LeafPairLocation.SnapTo(GetPreviewLocationTarget(0.0f));
		PreviewRotationCurrent = GetPreviewRotationTarget(0.0f).Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		DistanceCurrent = FMath::FInterpTo(DistanceCurrent, Beanstalk.GetLeafPairPreviewDistanceTarget(), DeltaTime, 7.5f);

		// Interpolate towards new rotation.
		FRotator TargetRotation = GetPreviewRotationTarget(DistanceCurrent);
		TargetRotation.Roll = 0.0f;

		PreviewRotationCurrent = FQuat::Slerp(PreviewRotationCurrent, TargetRotation.Quaternion(), DeltaTime * 4.0f);
		Beanstalk.LeafPreviewRoot.SetWorldRotation(PreviewRotationCurrent);

		// Interpolate towards new location.
		FVector TargetLocation = GetPreviewLocationTarget(Beanstalk.GetLeafPairPreviewDistanceTarget());

		LeafPairLocation.AccelerateTo(TargetLocation, 0.1f, DeltaTime);
		Beanstalk.LeafPreviewRoot.SetWorldLocation(LeafPairLocation.Value);

		const float DistanceToLastLeaf = DistanceCurrent - Beanstalk.GetNearestLeafPairDistanceAlongSpline();

		float PreviewScale = FMath::GetMappedRangeValueClamped(FVector2D(0, 350.f), FVector2D(0.25f, 1.f), DistanceToLastLeaf);

		if(Beanstalk.IsLeafPairBlocked())
		{
			PreviewScale = 0.45f;
		}

		CurrentPreviewScale = FMath::FInterpTo(CurrentPreviewScale, PreviewScale, DeltaTime, 8.0f);

		Beanstalk.LeafPreviewRoot.SetWorldScale3D(CurrentPreviewScale);
	}

	FVector GetPreviewLocationTarget(float DistanceOffset) const
	{
		return Beanstalk.VisualSpline.GetLocationAtDistanceAlongSpline(DistanceOffset, ESplineCoordinateSpace::World);
	}

	FRotator GetPreviewRotationTarget(float DistanceOffset) const
	{
		return Beanstalk.VisualSpline.GetRotationAtDistanceAlongSpline(DistanceOffset, ESplineCoordinateSpace::World);
	}
}
