import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Vino.Checkpoints.Statics.LivesStatics;
import Cake.LevelSpecific.Tree.Wasps.WaspPlayerTakeDamageEffect;
import Vino.PlayerHealth.PlayerHealthStatics;

class UWaspExplosionHitResponseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspHitResponse");
	default CapabilityDebugCategory = n"WaspResponses";
	default TickGroup = ECapabilityTickGroups::GamePlay;

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
		if(GetAttributeObject(n"WaspExplosion") != nullptr)
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
		AHazeActor Explosive = Cast<AHazeActor>(GetAttributeObject(n"WaspExplosion"));
		ActivationParams.AddObject(n"WaspExplosion", Explosive);

		FVector ImpactForce = (Player.GetActorLocation() - Explosive.GetActorLocation());
		ImpactForce = ImpactForce.GetSafeNormal2D() * 1000.f;
		ImpactForce.Z = 1500.f;
		ActivationParams.AddVector(n"WaspExplosionForce", ImpactForce);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AHazeActor Explosive = Cast<AHazeActor>(ActivationParams.GetObject(n"WaspExplosion"));
        if (!ensure(Explosive != nullptr))
            return;            
        
		// Give player a wallop  
		FVector WaspExplosionForce = ActivationParams.GetVector(n"WaspExplosionForce");
		WaspExplosionForce.Z = FMath::Max(1000.f, WaspExplosionForce.Z);

		Player.SetCapabilityAttributeVector(n"KnockdownDirection", WaspExplosionForce);
		Player.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);

        // Do damage
		DamagePlayerHealth(Player, 0.5f, TSubclassOf<UPlayerDamageEffect>(UWaspPlayerTakeDamageEffect::StaticClass()));

        // Always deactivate this capability after a set maximum time to allow further damage
		ReleaseTime = Time::GetGameTimeSeconds() + 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetCapabilityAttributeObject(n"WaspExplosion", nullptr);
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