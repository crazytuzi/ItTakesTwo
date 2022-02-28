import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleTags;


class UMarbleLockInPlaceCapability : UHazeCapability
{
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMarbleBall Marble;
	USceneComponent LockInPlaceComponent;
	bool HasInterpolatedIntoPosition = false;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Marble = Cast<AMarbleBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (GetAttributeObject(FMarbleTags::LockinplaceComponent) != nullptr)
        {
            return EHazeNetworkActivation::ActivateFromControl;
        }
        else
        {
            return EHazeNetworkActivation::DontActivate;
        }   
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"LockInPlaceComponent", GetAttributeObject(FMarbleTags::LockinplaceComponent));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Marble.BlockCapabilities(FMarbleTags::MarblePhysics, this);
		Marble.BlockCapabilities(FMarbleTags::MarbleNetworkSync, this);
		HasInterpolatedIntoPosition = false;
		Marble.Mesh.SetSimulatePhysics(false);
		LockInPlaceComponent = Cast<USceneComponent>(ActivationParams.GetObject(n"LockInPlaceComponent"));
		Marble.AttachToComponent(LockInPlaceComponent, n"", EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Marble.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Marble.UnblockCapabilities(FMarbleTags::MarblePhysics, this);
		Marble.UnblockCapabilities(FMarbleTags::MarbleNetworkSync, this);
		HasInterpolatedIntoPosition = false;
		Marble.Mesh.SetSimulatePhysics(true);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetAttributeObject(FMarbleTags::LockinplaceComponent) == nullptr)
        {
            return EHazeNetworkDeactivation::DeactivateFromControl;
        }
        else
        {
            return EHazeNetworkDeactivation::DontDeactivate;
        }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
        if (!HasInterpolatedIntoPosition)
		{
			UpdateLerpPositioning(DeltaTime);
		}
	}

	void UpdateLerpPositioning(float DeltaTime)
	{
		FVector Newposition = FVector::ZeroVector;
		Newposition = FMath::Lerp(Owner.ActorLocation, LockInPlaceComponent.GetWorldLocation(), DeltaTime * 3);
		Marble.SetActorLocation(Newposition);

		if (LockInPlaceComponent.WorldLocation.Distance(Marble.ActorLocation) < 10)
		{
			HasInterpolatedIntoPosition = true;
		}
	}
}