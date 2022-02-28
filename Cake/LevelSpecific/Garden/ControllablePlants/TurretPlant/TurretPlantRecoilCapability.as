import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlant;
import Cake.Weapons.Recoil.RecoilCapability;

class UTurretPlantRecoilCapability : URecoilCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	ATurretPlant TurretPlant;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		TurretPlant = Cast<ATurretPlant>(Owner);
		PlayerCameraUser = UCameraUserComponent::Get(TurretPlant.OwnerPlayer);
		Recoil = URecoilComponent::Get(Owner);
		RangedWeapon = URangedWeaponComponent::Get(Owner);
	}

	FVector2D GetInputCompensation() const
	{
		return TurretPlant.CurrentPlayerInput;
	}
}
