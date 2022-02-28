import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;

class UWaspDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Death");

	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	UWaspBehaviourComponent BehaviourComp;
	UWaspHealthComponent HealthComp;
	UWaspEffectsComponent EffectsComp;
	float RemoteDeathTime = -1000.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		HealthComp = UWaspHealthComponent::Get(Owner);
		EffectsComp = UWaspEffectsComponent::Get(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (BehaviourComp.DeathBark != nullptr)
			PlayFoghornBark(BehaviourComp.DeathBark, Owner);

		if (!HasControl())
			HealthComp.bIsDead = true;
		HealthComp.OnDie.Broadcast(Owner);
		Owner.DisableActor(Owner);

		if (Time::GetGameTimeSince(RemoteDeathTime) > 4.f)
			EffectsComp.DeathEffect();

		USapResponseComponent SapComp = USapResponseComponent::Get(Owner);
		if (SapComp != nullptr)
			DisableAllSapsAttachedTo(Owner.RootComponent);

		// Do not leave wasp team here, we stay in team until endplay
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRemotePreDeath()
	{
		if (HasControl())
			return; // Remote side only

		RemoteDeathTime = Time::GameTimeSeconds;
		EffectsComp.DeathEffect();
		BehaviourComp.HideMeshes();	// Meshes are shown in BehaviourComp.Reset	
	}
}
