import Vino.Pickups.PickupActor;
import Vino.Pickups.PickupTags;

// Used to lerp actor to align location offset when picking up
class UPickupOffsetLerpCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupOffsetLerpCapability);

	default CapabilityDebugCategory = PickupTags::PickupSystem;

	APickupActor PickupOwner;

	FPickupOffsetLerpParams OffsetLerpParams;

	FVector LerpOrigin, LerpTarget;
	float LerpAlpha;

	bool bIsLerpingLocationOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupOwner = Cast<APickupActor>(Owner);
		PickupOwner.OnPickupOffsetLerpRequestedEvent.AddUFunction(this, n"OnPickupOffsetLerpRequested");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bIsLerpingLocationOffset)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LerpOrigin = Owner.RootComponent.GetRelativeTransform().GetTranslation();
		LerpTarget = PickupOwner.GetPlayerPickupOffset(OffsetLerpParams.PlayerCharacter).GetTranslation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LerpAlpha += DeltaTime * OffsetLerpParams.LerpSpeed;
		Owner.RootComponent.SetRelativeLocation(FMath::Lerp(LerpOrigin, LerpTarget, LerpAlpha));

		if(LerpAlpha >= 1.f)
		{
			Owner.RootComponent.SetRelativeLocation(LerpTarget);
			bIsLerpingLocationOffset = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bIsLerpingLocationOffset)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		OffsetLerpParams = FPickupOffsetLerpParams();
		LerpAlpha = 0.f;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPickupOffsetLerpRequested(FPickupOffsetLerpParams PickupOffsetLerpParams)
	{
		OffsetLerpParams = PickupOffsetLerpParams;
		bIsLerpingLocationOffset = true;
	}
}