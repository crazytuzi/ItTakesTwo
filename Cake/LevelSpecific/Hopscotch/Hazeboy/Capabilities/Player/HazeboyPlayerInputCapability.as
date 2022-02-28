import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyPlayerComponent;

class UHazeboyPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 101;

	AHazePlayerCharacter Player;
	UHazeboyPlayerComponent HazeboyComp;
	AHazeboyTank Tank;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeboyComp = UHazeboyPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HazeboyComp.CurrentDevice == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (HazeboyComp.CurrentDevice == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Tank = HazeboyComp.CurrentDevice.TargetTank;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Tank != nullptr)
		{
			Tank.SetCapabilityAttributeVector(AttributeVectorNames::CameraDirection, FVector::ZeroVector);
			Tank.SetCapabilityAttributeVector(AttributeVectorNames::MovementRaw, FVector::ZeroVector);
			SetActionState(ActionNames::WeaponFire, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Tank.SetCapabilityAttributeVector(AttributeVectorNames::CameraDirection, GetAttributeVector(AttributeVectorNames::CameraDirection));
		Tank.SetCapabilityAttributeVector(AttributeVectorNames::MovementRaw, GetAttributeVector(AttributeVectorNames::MovementRaw));
		SetActionState(ActionNames::WeaponFire, IsActioning(ActionNames::WeaponFire) || IsActioning(ActionNames::MovementJump));
	}

	void SetActionState(FName ActionName, bool bActive)
	{
		Tank.SetCapabilityActionState(ActionName, bActive ? EHazeActionState::Active : EHazeActionState::Inactive);
	}
}