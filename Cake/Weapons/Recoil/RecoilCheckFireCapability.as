import Cake.Weapons.Recoil.RecoilComponent;
import Cake.Weapons.RangedWeapon.RangedWeapon;

/*
	Should run before RangedWeaponCapability to check if fire has stopped. lags behind one frame.
*/

class URecoilCheckFireCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 18;

	URecoilComponent Recoil;
	URangedWeaponComponent RangedWeapon;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Recoil = URecoilComponent::Get(Owner);
		RangedWeapon = URangedWeaponComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Recoil.bIsFiring = RangedWeapon.IsFiring();
	}
}
