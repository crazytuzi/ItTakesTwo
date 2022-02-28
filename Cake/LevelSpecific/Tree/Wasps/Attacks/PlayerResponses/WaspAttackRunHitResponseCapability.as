import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Vino.Checkpoints.Statics.LivesStatics;
import Vino.Movement.Capabilities.KnockDown.CharacterKnockDownCapability;
import Cake.LevelSpecific.Tree.Wasps.WaspPlayerTakeDamageEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;

class UWaspAttackRunHitResponseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspHitResponse");
	default CapabilityDebugCategory = n"WaspResponses";
	default TickGroup = ECapabilityTickGroups::GamePlay;

    ULocomotionFeatureHeroWasp AnimFeature = nullptr;
    AHazePlayerCharacter Player = nullptr;

	float ReleaseTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ensure(Player != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"AttackingWasp") != nullptr)
        	return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (Time::GetGameTimeSeconds() > ReleaseTime)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		AHazeActor Attacker = Cast<AHazeActor>(GetAttributeObject(n"AttackingWasp"));
		ActivationParams.AddObject(n"AttackingWasp", Attacker);
		ActivationParams.AddVector(n"AttackerVelocity",UHazeBaseMovementComponent::Get(Attacker).GetVelocity());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AHazeActor Attacker = Cast<AHazeActor>(ActivationParams.GetObject(n"AttackingWasp"));
        UWaspComposableSettings Settings = UWaspComposableSettings::GetSettings(Attacker);

		// Give player a wallop 
        FVector ImpactForce = ActivationParams.GetVector(n"AttackerVelocity");
		ImpactForce.Z = FMath::Max(1000.f, ImpactForce.Z);
		ImpactForce = ImpactForce.GetClampedToMaxSize(Settings.KnockBackForce);

		Player.SetCapabilityAttributeVector(n"KnockdownDirection", ImpactForce);
		Player.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);

		// Do Damage
		DamagePlayerHealth(Player, Settings.AttackRunDamage, TSubclassOf<UPlayerDamageEffect>(UWaspPlayerTakeDamageEffect::StaticClass()));

        // Always deactivate this capability after a set maximum time to allow further attacks
		ReleaseTime = Time::GetGameTimeSeconds() + 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetCapabilityAttributeObject(n"AttackingWasp", nullptr);
        ReleaseTime = 0.f;
	}

    UFUNCTION()
    void OnResponseAnimDone()
    {
        ReleaseTime = 0.f;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
    }
}