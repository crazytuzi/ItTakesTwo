import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspShootyTeam;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;

class UWaspBlasterCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	UWaspBehaviourComponent BehaviourComp;
	USceneComponent Blaster;
	UWaspComposableSettings Settings;

	float ShootTime = 0.f;

    UWaspShootyTeam ShootyTeam = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
		Blaster = UStaticMeshComponent::Get(Owner);
        ShootyTeam = Cast<UWaspShootyTeam>(Owner.GetJoinedTeam(n"WaspShootyTeam"));
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
		ShootTime = Time::GetGameTimeSeconds();
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        SetMutuallyExclusive(n"Attack", false); 
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (Time::GetGameTimeSeconds() > ShootTime)
		{
			AWaspBlasterBolt Bolt = ShootyTeam.GetAvailableBlasterBolt();
			if ((Bolt != nullptr) && (BehaviourComp.Target != nullptr))
			{
				FVector MuzzleLoc = Blaster.GetWorldLocation();
				FVector AimDir = (BehaviourComp.Target.GetActorLocation() - MuzzleLoc).GetSafeNormal();
				FVector Velocity = AimDir * Settings.ProjectileLaunchSpeed;
				Bolt.Shoot(Owner, MuzzleLoc, Velocity, Settings.ProjectileLifeTime);	
				ShootTime += Settings.SalvoShotInterval;
			}
		}
	}
};
