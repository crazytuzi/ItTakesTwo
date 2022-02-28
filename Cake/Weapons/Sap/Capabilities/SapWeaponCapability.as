import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Peanuts.Outlines.Outlines;

class USapWeaponCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Weapon);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AddMeshToPlayerOutline(Wielder.Weapon.Mesh, Player, this);
		AddMeshToPlayerOutline(Wielder.Weapon.Container.Mesh, Player, this);
		Player.AddLocomotionAsset(Wielder.Locomotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveMeshFromPlayerOutline(Wielder.Weapon.Mesh, this);
		RemoveMeshFromPlayerOutline(Wielder.Weapon.Container.Mesh, this);
		Player.ClearLocomotionAssetByInstigator(this);
	}

	int BlockCounter = 0;
	ASapWeapon DisabledWeapon;

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		BlockCounter++;
		if (BlockCounter == 1 && Wielder.Weapon != nullptr)
		{
			Wielder.Weapon.DisableActor(this);
			DisabledWeapon = Wielder.Weapon;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		BlockCounter--;
		if (BlockCounter == 0 && System::IsValid(DisabledWeapon) && DisabledWeapon.IsActorDisabled(this))
		{
			DisabledWeapon.EnableActor(this);
		}
	}
}