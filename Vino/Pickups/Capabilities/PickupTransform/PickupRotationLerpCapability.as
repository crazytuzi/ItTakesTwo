import Vino.Pickups.PickupActor;
import Vino.Pickups.PickupTags;

// Used to lerp actor to align rotation offset when picking up AND to rotate back when putting down
class UPickupRotationLerpCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupRotationLerpCapability);

	default CapabilityDebugCategory = PickupTags::PickupSystem;

	APickupActor PickupOwner;

	FPickupRotationLerpParams RotationLerpParams;

	FQuat LerpOrigin;
	float LerpAlpha;

	bool bIsLerpingRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupOwner = Cast<APickupActor>(Owner);
		PickupOwner.OnPickupRotationLerpRequestedEvent.AddUFunction(this, n"OnPickupRotationLerpRequested");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bIsLerpingRotation)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LerpOrigin = RotationLerpParams.bWorldRotation ? Owner.GetActorRotation().Quaternion() : Owner.GetRootComponent().GetRelativeTransform().GetRotation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LerpAlpha += DeltaTime * RotationLerpParams.LerpSpeed;
		SetLerpedRotation(FQuat::FastLerp(LerpOrigin, RotationLerpParams.TargetRotation, LerpAlpha));

		if(LerpAlpha >= 1.f)
		{
			SetLerpedRotation(RotationLerpParams.TargetRotation);
			bIsLerpingRotation = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bIsLerpingRotation)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RotationLerpParams = FPickupRotationLerpParams();
		LerpAlpha = 0.f;
	}

	void SetLerpedRotation(FQuat LerpedRotation)
	{
		if(RotationLerpParams.bWorldRotation)
			PickupOwner.SetActorRotation(LerpedRotation);
		else
			PickupOwner.SetActorRelativeRotation(LerpedRotation.Rotator(), false, FHitResult(), true);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPickupRotationLerpRequested(FPickupRotationLerpParams PickupRotationLerpParams)
	{
		RotationLerpParams = PickupRotationLerpParams;
		bIsLerpingRotation = true;
	}
}