
import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailWeaponStatics;
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailSocketDefinition;

/**
* Handles the equipping and unequipping of nails
*/

UCLASS()
class UNailUnequipCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NailUnequip");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default TickGroupOrder = 130;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	ANailWeaponActor NailBeingUnequipped = nullptr;
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
		if (!WielderComp.HasNailsEquipped())
	 		return EHazeNetworkActivation::DontActivate;

		if(!WielderComp.HasNailEquippedToHand())
	 		return EHazeNetworkActivation::DontActivate;

 		if (WielderComp.bAiming)
	 		return EHazeNetworkActivation::DontActivate;

 		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!WielderComp.HasNailEquippedToHand())
	 		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

 		if(WielderComp.bAiming)
	 		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		ensure(WielderComp.NailEquippedToHand != nullptr);
		OutParams.AddObject(n"NailToBeUnequipped", WielderComp.NailEquippedToHand);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		NailBeingUnequipped = Cast<ANailWeaponActor>(ActivationParams.GetObject(n"NailToBeUnequipped"));

		// Might need to cancel recall on remote if we're very laggy.
		bool bWasForceRecalled = false;
		if(WielderComp.IsNailBeingRecalled(NailBeingUnequipped))
		{
			ensure(!HasControl());
			WielderComp.ForceFinishNailRecallForNail(NailBeingUnequipped);
			bWasForceRecalled = true;
		}

		if(NailBeingUnequipped != WielderComp.NailEquippedToHand)
		{
			devEnsure(false, "Things are happening in the wrong order in UnEquipCapability... Let sydney know about this");
			WielderComp.NailEquippedToHand = NailBeingUnequipped;
		}

		Owner.BlockCapabilities(n"NailEquip", this);

		WielderComp.UnequipNailFromHand();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"NailEquip", this);
	}

}






















