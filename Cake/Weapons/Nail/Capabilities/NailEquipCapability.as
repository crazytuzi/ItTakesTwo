
import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailSocketDefinition;
import Cake.Weapons.Nail.NailWeaponStatics;

/**
* Handles the equipping and unequipping of nails
*/

UCLASS()
class UNailEquipCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"NailEquip");
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default TickGroupOrder = 120;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	UNailWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WielderComp.HasNailsEquipped())
	 		return EHazeNetworkActivation::DontActivate;

		if(WielderComp.HasNailEquippedToHand())
	 		return EHazeNetworkActivation::DontActivate;

 		if(!WielderComp.bAiming)
	 		return EHazeNetworkActivation::DontActivate;

 		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WielderComp.HasNailEquippedToHand())
	 		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!WielderComp.HasNailsEquipped())
	 		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

 		if(!WielderComp.bAiming)
	 		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"NailToBeEquipped", WielderComp.NailsEquippedToBack.Last());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ANailWeaponActor NailBeingEquipped = Cast<ANailWeaponActor>(ActivationParams.GetObject(n"NailToBeEquipped"));

		// Might need to cancel recall on remote if we're very laggy.
		bool bWasForceRecalled = false;
		if(WielderComp.IsNailBeingRecalled(NailBeingEquipped))
		{
			ensure(!HasControl());
			WielderComp.ForceFinishNailRecallForNail(NailBeingEquipped);
			bWasForceRecalled = true;
		}

		Owner.BlockCapabilities(n"NailThrow", this);

		if (NailBeingEquipped == nullptr)
		{
			devEnsure(false, "Things are happening in the wrong order when Equiping the nail ... Let sydney know about this");
			return;
		}

 		WielderComp.EquipNailToHand(NailBeingEquipped);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"NailThrow", this);
	}

}






















