import Cake.LevelSpecific.Tree.Beetle.Health.BeetleHealthComponent;
import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;
import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimFeature;
import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimationComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;

class UBeetleDefeatCapability : UHazeCapability
{
	UBeetleHealthComponent HealthComp;
	float DefeatTime = 0.f;
	UBeetleAnimFeature AnimFeature;
	UBeetleBehaviourComponent BehaviourComp;
	bool bHasBeenDefeated = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HealthComp = UBeetleHealthComponent::Get(Owner);
		BehaviourComp = UBeetleBehaviourComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HealthComp.RemainingHealth > 0)
			return EHazeNetworkActivation::DontActivate;
		if (bHasBeenDefeated)
			return EHazeNetworkActivation::DontActivate; // Only accept defeat once!
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BehaviourComp.LogEvent("Activating defeat.");
		AnimFeature = UBeetleBehaviourComponent::Get(Owner).AnimFeature;
		DefeatTime = Time::GetGameTimeSeconds() + AnimFeature.Stunned_Start.GetPlayLength();
		UBeetleAnimationComponent::Get(Owner).PlayStartMH(AnimFeature.Stunned_Start, AnimFeature.Stunned_MH);
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Time::GetGameTimeSeconds() > DefeatTime)
		   	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	   	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Curses, foiled again!
		BehaviourComp.LogEvent("Triggering defeat event.");
		bHasBeenDefeated = true;
		UBeetleBehaviourComponent::Get(Owner).OnDefeat.Broadcast();
    }
}