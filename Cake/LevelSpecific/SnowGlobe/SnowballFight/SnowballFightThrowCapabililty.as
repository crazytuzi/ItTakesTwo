import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightNames;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightComponent;
import Vino.Movement.Components.MovementComponent;

class USnowballFightThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(SnowballFightTags::Throw);
	default CapabilityTags.Add(n"SnowGlobeSideContent");
	default CapabilityTags.Add(n"SnowballFight");

	default CapabilityDebugCategory = n"GamePlay";
	
	AHazePlayerCharacter Player;
	USnowballFightComponent SnowballComp;
	UHazeMovementComponent MoveComp;

	private float LaunchTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		SnowballComp = USnowballFightComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

 		if (!SnowballComp.bIsAiming)
			return EHazeNetworkActivation::DontActivate;

 		if (SnowballComp.HasCooldown())
			return EHazeNetworkActivation::DontActivate;

 		if (SnowballComp.PoolSize <= 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds > LaunchTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		// Sync thrown projectile
		int ProjectileIndex = SnowballComp.GetNextProjectileIndex();
			
		Params.AddNumber(n"ProjectileIndex", ProjectileIndex);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params) 
	{
		int ProjectileIndex = Params.GetNumber(n"ProjectileIndex");
		auto Projectile = SnowballComp.GetProjectileByIndex(ProjectileIndex);

		if (Projectile == nullptr)
			return;

		SnowballComp.Throw(Projectile);

		// Complete tutorial if not completed already
		if (!SnowballComp.bHaveCompletedTutorial)
		{
			SnowballComp.RemovePrompts(Player);	
			SnowballComp.bHaveCompletedTutorial = true;
		}

		// Timestamp launch
		LaunchTime = Time::GameTimeSeconds + SnowballComp.LaunchDelay;

		Player.PlayForceFeedback(SnowballComp.ThrowForceFeedback, false, true, n"SnowballThrow");
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& Params)
	{
		// Might not have anything to throw, in which case the data is useless
		if (SnowballComp.HeldProjectile == nullptr)
			return;

		FSnowballFightTargetData TargetData;
		TargetData.bIsWithinCollision = SnowballComp.bIsWithinCollision;
		TargetData.Component = SnowballComp.AimTargetComponent;
		TargetData.RelativeLocation = (SnowballComp.AimTargetComponent != nullptr ? 
			SnowballComp.TargetRelativeLocation : 
			SnowballComp.AimTarget);

		Params.AddStruct(n"TargetData", TargetData);
		Params.AddVector(n"LaunchLocation", SnowballComp.HeldProjectile.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params) 
	{
		// Might not have anything to throw
		if (SnowballComp.HeldProjectile == nullptr)
			return;

		FSnowballFightTargetData TargetData;
		Params.GetStruct(n"TargetData", TargetData);
		FVector LaunchLocation = Params.GetVector(n"LaunchLocation");

		SnowballComp.Launch(TargetData, LaunchLocation);
	}
};