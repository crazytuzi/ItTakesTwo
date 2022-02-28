import Cake.FlyingMachine.Melee.Audio.FlyingMachineMeleeAudioCapabilityBase;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeNut;

class UFlyingMachineMeleePlayerAudioCapability : UFlyingMachineMeleeAudioCapabilityBase
{
	UPROPERTY()
	UAkAudioEvent NutImpactEvent;

	UPROPERTY()
	UAkAudioEvent NutDissolveEvent;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"PlayerVelocityAudioData", this);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"PlayerVelocityAudioData", this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) override
	{
		Super::TickActive(DeltaTime);

		if(ConsumeAction(n"OnNutImpact") == EActionStateStatus::Active)
			UHazeAkComponent::HazePostEventFireForget(NutImpactEvent, FTransform());

		if(ConsumeAction(n"OnNutDissolve") == EActionStateStatus::Active)
			UHazeAkComponent::HazePostEventFireForget(NutDissolveEvent, FTransform());		
	}

}
