import Peanuts.ButtonMash.ButtonMashComponent;
import Peanuts.ButtonMash.ButtonMashHandleBase;
import Peanuts.ButtonMash.ButtonMashStatics;

class UButtonMashSilentHandle : UButtonMashHandleBase
{
	// Nothing here...
}

class UButtonMashSilentCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ButtonMashTags::ButtonMash);

	AHazePlayerCharacter Player;

	UButtonMashComponent MashComponent;
	UButtonMashSilentHandle Handle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParms)
	{
		MashComponent = UButtonMashComponent::GetOrCreate(Owner);

		// Get player
		Player = Cast<AHazePlayerCharacter>(Owner);
		devEnsure(Player != nullptr, "You can't put this capability on a non-player. Use the StartButtonMashDefault- static functions.");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MashComponent.CurrentButtonMash != nullptr &&
			MashComponent.CurrentButtonMash.IsA(UButtonMashSilentHandle::StaticClass()))
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MashComponent.CurrentButtonMash == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "Mash Rate: " + Handle.MashRateControlSide;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::ButtonMash))
			MashComponent.DoMashPulse();
	}
}

UFUNCTION(Category = "ButtonMash|Silent", meta = (ReturnDisplayName = Handle))
UButtonMashSilentHandle StartButtonMashSilent(AHazePlayerCharacter Player)
{
	// Create handle
	UButtonMashSilentHandle Handle = 
		Cast<UButtonMashSilentHandle>(
			CreateButtonMashHandle(
				Player,
				UButtonMashSilentHandle::StaticClass()
			)
		);

	// Push silent capability
	TSubclassOf<UHazeCapability> CapabilityClass(UButtonMashSilentCapability::StaticClass());
	Handle.PushCapability(CapabilityClass);

	// Start it up!
	StartButtonMashInternal(Handle);
	return Handle;
}