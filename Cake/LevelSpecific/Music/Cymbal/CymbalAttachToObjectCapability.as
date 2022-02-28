import Cake.LevelSpecific.Music.Cymbal.CymbalTags;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;

class UCymbalAttachToObjectCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 40;

	ACymbal Cymbal;

	// If the attachment is not on an Actor
	bool bEmptyAttach = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Cymbal = Cast<ACymbal>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		//if(Cymbal.CymbalState != ECymbalState::AttachedToObject)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		//return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(Cymbal.AttachObject != nullptr)
		{
			// Because BSPs may not be Actors, or if we want to stop the Cymbal mid-air for whatever reason
			ActivationParams.AddObject(n"AttachObject", Cymbal.AttachObject);
		}

		ActivationParams.AddVector(n"AttachLocation", Cymbal.AttachLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cymbal.ClearAttachToObject();
		bEmptyAttach = true;
		const FVector AttachLocation = ActivationParams.GetVector(n"AttachLocation");
		Owner.SetActorLocation(AttachLocation);

		AActor AttachObject = Cast<AActor>(ActivationParams.GetObject(n"AttachObject"));

		if(AttachObject != nullptr)
		{
			Owner.AttachToActor(AttachObject, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			bEmptyAttach = false;
		}

		Cymbal.bAttachedToObject = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AActor AttachParent = Owner.GetAttachParentActor();

		if(AttachParent != nullptr)
		{
			Owner.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			UCymbalImpactComponent CymbalImpactComponent = UCymbalImpactComponent::Get(AttachParent);

			if(CymbalImpactComponent != nullptr)
			{
				CymbalImpactComponent.CymbalRemoved();
			}
		}
		
		Cymbal.bAttachedToObject = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		//if(Cymbal.CymbalState != ECymbalState::AttachedToObject)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		//return EHazeNetworkDeactivation::DontDeactivate;
	}
}
