// There is no place to put the cookie down!
// Teleport to feet until a sweeter solution is found - find better name?
import Vino.Pickups.Putdown.Capabilities.PutdownCapabilityBase;

class UTeleportPutdownCapability : UPutdownCapabilityBase
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
    default CapabilityTags.Add(PickupTags::PutdownTeleportCapability);

    float RotationSpeed = 4.0f;
    bool bObjectWasTeleported;

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		// DON'T USE TELEPORT PUTDOWN FOR NOW!! It will kill player if 
		// the putdown object has collisions with player enabled
		return EHazeNetworkActivation::DontActivate;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        bObjectWasTeleported = false;

        BlockCapabilitiesBeforePutdown();

        PlayPutdownAnimation();
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        return bObjectWasTeleported ? EHazeNetworkDeactivation::DeactivateLocal : EHazeNetworkDeactivation::DontDeactivate;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		PlayerOwner.UnbindAnimNotifyDelegate(UAnimNotify_Pickup::StaticClass(), PutDownNotify);
        Super::OnDeactivated(DeactivationParams);
    }

    UFUNCTION()
    void OnObjectPutDown(AHazeActor HazeActor, UHazeSkeletalMeshComponentBase SkeletalMesh, UAnimNotify AnimNotify) override
    {
        FVector Origin, Extents;
        PutdownActor.GetActorBounds(true, Origin, Extents);

        PickupComponent.PutDown();

        // PickupComponent.StartPutdownRotationLerping(RotationSpeed);

        FVector PutdownLocation = PlayerOwner.GetActorLocation() - (Extents * FVector::RightVector) / 2;
        PutdownActor.SetActorLocation(PutdownLocation);
    }

    UFUNCTION()
    void OnAnimationEnded() override
    {
		if(!IsActive())
			return;

        bObjectWasTeleported = true;
    }
}