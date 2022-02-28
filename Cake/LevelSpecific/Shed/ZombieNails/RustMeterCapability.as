
class RustMeterCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;

    UPROPERTY()
    float AntiRustPercent = 1.f;

    float RustChange = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
        // return EHazeNetworkActivation::ActivateLocal;
        // return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// return EHazeNetworkDeactivation::DeactivateFromControl;
		// return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
        RustChange = GetAttributeValue(n"RustMeterChangeAmount");
        AntiRustPercent = FMath::Clamp(AntiRustPercent + (RustChange * DeltaTime), 0.f, 1.f);
	}
}