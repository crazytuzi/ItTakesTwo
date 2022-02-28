import Cake.LevelSpecific.Tree.Wasps.Weapons.HomingProjectile.WaspHomingProjectile;

class UWaspHomingProjectileLauncherCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 1.f;

	UWaspBehaviourComponent BehaviourComp;
	UHazeAkComponent AudioComp;
	
	AWaspHomingProjectile Projectile;
	float LaunchTime = 0.f;
	bool bProjectileLaunched = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		AudioComp = UHazeAkComponent::Get(Owner);

		UWaspHomingProjectileLauncherComponent Launcher = UWaspHomingProjectileLauncherComponent::Get(Owner);
		Projectile = Cast<AWaspHomingProjectile>(SpawnActor(Launcher.ProjectileClass, Launcher.WorldLocation, Launcher.WorldRotation, NAME_None, true, Owner.GetLevel()));
		Projectile.MakeNetworked(Owner, 0);
		Projectile.SetWielder(Owner);
		FinishSpawningActor(Projectile);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Time::GetGameTimeSeconds() > BehaviourComp.SustainedAttackEndTime)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (Time::GetGameTimeSeconds() > BehaviourComp.SustainedAttackEndTime)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        SetMutuallyExclusive(n"Attack", true); 
		AudioComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_IsAttacking", 1.f, 500);
		Projectile.HomingComp.OnReturn.AddUFunction(this, n"OnProjectileReturn");		
		Projectile.Launch(BehaviourComp.Target);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        SetMutuallyExclusive(n"Attack", false); 
		AudioComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_IsAttacking", 0.f, 500);
		Projectile.HomingComp.OnReturn.Unbind(this, n"OnProjectileReturn");		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Keep attack alive until projectile returns
		BehaviourComp.SustainedAttackEndTime = Time::GetGameTimeSeconds() + 1.f;
	}

	UFUNCTION()
	void OnProjectileReturn()
	{
		if (IsActive())
		{
			// Launch complete
			BehaviourComp.SustainedAttackEndTime = 0;
		}
	}
}