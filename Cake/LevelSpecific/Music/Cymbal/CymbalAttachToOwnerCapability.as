import Cake.LevelSpecific.Music.Cymbal.CymbalTags;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

class UCymbalAttachToOwnerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	ACymbal Cymbal;
	UCymbalComponent CymbalComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Cymbal = Cast<ACymbal>(Owner);
		CymbalComp = UCymbalComponent::Get(Owner.Owner);
		Player = CymbalComp.Player;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Cymbal.bReturnToOwner)
			return EHazeNetworkActivation::DontActivate;

		if(!Cymbal.IsOverlappingOwnerPlayer())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	bool IsValidForActivation() const
	{
		return Cymbal.IsOverlappingOwnerPlayer() && Cymbal.bReturnToOwner;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(CymbalComp.ShouldPlayCatchAnimation())
		{
			CymbalComp.bCymbalWasCaught = true;
		}

		//Cymbal.CymbalState = ECymbalState::Equipped;
		CymbalComp.AttachCymbalToBack();
		Cymbal.bReturnToOwner = false;
		Owner.CleanupCurrentMovementTrail(true);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
