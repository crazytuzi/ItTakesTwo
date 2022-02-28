import Cake.Weapons.Hammer.HammerWielderComponent;

UCLASS(abstract)
class UHammerEventHandler : UHazeCapability
{
	default CapabilityTags.Add(n"HammerEvents");
	default CapabilityTags.Add(n"HammerWeapon");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	UPROPERTY()
	AHammerWeaponActor Hammer = nullptr;

	UPROPERTY()
	UHammerWielderComponent WielderComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WielderComp = UHammerWielderComponent::GetOrCreate(Owner);
		Hammer =  WielderComp.GetHammer();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WielderComp.OnHammerSwingSwitchedDirection.AddUFunction(this, n"HandleHammerSwingSwitchedDirection");
		WielderComp.OnHammerSwingStarted.AddUFunction(this, n"HandleHammerSwingStarted");
		WielderComp.OnHammerSwingEnded.AddUFunction(this, n"HandleHammerSwingEnded");
		WielderComp.OnHammerHit.AddUFunction(this, n"HandleHammerHit");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WielderComp.OnHammerSwingSwitchedDirection.Unbind(this, n"HandleHammerSwingSwitchedDirection");
		WielderComp.OnHammerSwingStarted.Unbind(this, n"HandleHammerSwingStarted");
		WielderComp.OnHammerSwingEnded.Unbind(this, n"HandleHammerSwingEnded");
		WielderComp.OnHammerHit.Unbind(this, n"HandleHammerHit");
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleHammerHit(FHitResult HammerNoseHitData) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleHammerSwingSwitchedDirection() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleHammerSwingStarted() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleHammerSwingEnded() {}

}