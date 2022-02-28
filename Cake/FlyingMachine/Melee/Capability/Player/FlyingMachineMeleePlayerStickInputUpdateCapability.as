
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;

// This capability should never be blocked, it will update the stick values
class UFlyingMachineMeleePlayerStickInputUpdateCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeBlockedWhenGrabbed);
	
	default TickGroup = ECapabilityTickGroups::Input;
	default CapabilityDebugCategory = MeleeTags::Melee;


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

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
		const FVector RawInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
		FVector ConvertedInput = FVector(0.f, RawInput.Y, RawInput.X);
		UpdateStickInput(DeltaTime, ConvertedInput);

	}
}

