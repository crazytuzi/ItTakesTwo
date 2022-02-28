import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspShell;
import Cake.LevelSpecific.Tree.Wasps.Attacks.PlayerResponses.WaspExplosionHitResponseCapability;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspMortarTeam;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspMortarComponent;

class UWaspMortarCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	UWaspBehaviourComponent BehaviourComp;
	UWaspMortarComponent Mortar;

    UWaspMortarTeam MortarTeam = nullptr;
	UWaspComposableSettings Settings;
	AHazeActor Target = nullptr;

	float ShootTime = 0.f;
    FVector WalkFireDir;
    int32 ShotCount = 0;
    int32 NumSalvo = 1;

	TArray<AWaspShell> AvailableShells;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		Mortar = UWaspMortarComponent::Get(Owner);

        MortarTeam = Cast<UWaspMortarTeam>(Owner.GetJoinedTeam(n"WaspMortarTeam"));
		Settings = UWaspComposableSettings::GetSettings(Owner);

        // Add response capability for all players when there are members of the team
        BehaviourComp.Team.AddPlayersCapability(UWaspExplosionHitResponseCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.SustainedAttackCount == 0)
			return EHazeNetworkActivation::DontActivate;
		if (Time::GetGameTimeSeconds() > BehaviourComp.SustainedAttackEndTime)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.SustainedAttackCount == 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        if (Time::GetGameTimeSeconds() > BehaviourComp.SustainedAttackEndTime)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	FName GetParamShellName(int i)
	{
		return FName("Shell" + i);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddNumber(n"AttackCount", BehaviourComp.SustainedAttackCount);
		ActivationParams.AddValue(n"AttackDuration", BehaviourComp.SustainedAttackEndTime - Time::GetGameTimeSeconds());
		ActivationParams.AddObject(n"Target", BehaviourComp.Target);
		
		// Spawn shells to be launched 
		for (int i = 0; i < BehaviourComp.SustainedAttackCount; i++)
		{
			ActivationParams.AddObject(GetParamShellName(i), Mortar.GetShell());
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BehaviourComp.SustainedAttackCount = ActivationParams.GetNumber(n"AttackCount");
		BehaviourComp.SustainedAttackEndTime = ActivationParams.GetValue(n"AttackDuration") + Time::GetGameTimeSeconds();
		
		// Target should always be set and never change during a volley
		// In case we have any pending shots when deactivating we'd like to be sure they will be fired at the same target.
		Target = Cast<AHazeActor>(ActivationParams.GetObject(n"Target"));	

		AvailableShells.Empty(BehaviourComp.SustainedAttackCount);
		for (int i = 0; i < BehaviourComp.SustainedAttackCount; i++)
		{
			AWaspShell Shell = Cast<AWaspShell>(ActivationParams.GetObject(GetParamShellName(i)));
			if (ensure(Shell != nullptr))
			{
				Shell.DisableActor(this); // Start disabled
				AvailableShells.Add(Shell);
			}
		}

        SetMutuallyExclusive(n"Attack", true); 
		float ShootDelay = (BehaviourComp.SustainedAttackCount == 1) ? 1.1f : 1.42f; // Match with anim!
		ShootTime = Time::GetGameTimeSeconds() + ShootDelay;
        FVector ToTarget = Target.GetActorLocation() - Mortar.GetMuzzleLocation();
        WalkFireDir = ToTarget.GetSafeNormal2D(); 
        ShotCount = 0;

		// Salvo or single shot?
        float SalvoTime = BehaviourComp.SustainedAttackEndTime - Time::GetGameTimeSeconds();
        NumSalvo = BehaviourComp.SustainedAttackCount;
    }


	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		// Send over shot count so remote side can ensure it shoots the same number of shells. 
		// (just in case control side failed to shoot all of the intended shots for some reason)
		DeactivationParams.AddNumber(n"FinalShotCount", ShotCount);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        SetMutuallyExclusive(n"Attack", false); 
		
		// Remote side might be deactivated by crumb before reaching shoot time
		if (!HasControl() && !IsBlocked())
		{
			// Shoot any remaining shots here
			int FinalShotCount = DeactivationParams.GetNumber(n"FinalShotCount");
			for (int i = ShotCount; i < FinalShotCount; i++)
			{
				if (!ensure(AvailableShells.Num() > ShotCount))
					break;
				Shoot();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if ((Time::GetGameTimeSeconds() > ShootTime) && 
			(AvailableShells.Num() > ShotCount))
		{
			Shoot();
		}
	}

	void Shoot()
	{
		AWaspShell Shell = AvailableShells[ShotCount];
		if (ensure(Shell != nullptr) && ensure(Target != nullptr))
		{
			// Make the shots walk towards target
			FVector MuzzleLoc = Mortar.GetMuzzleLocation();
			FVector TargetLoc = Target.GetActorLocation();   
			FVector ToTargetLoc = TargetLoc - MuzzleLoc;
			float ToTargetDist = ToTargetLoc.Size2D();
			ShotCount++;
			float WalkFireInterval = ToTargetDist * 0.1f;
			FVector WalkFireLoc = TargetLoc - WalkFireDir * WalkFireInterval * (NumSalvo - ShotCount);

			FVector ToDetonationLoc = (WalkFireLoc - MuzzleLoc);
			float HDist = ToDetonationLoc.Size2D();
			float VDist = ToDetonationLoc.Z;
			VDist += BehaviourComp.TargetGroundVelocity.Value.Z + 0.5f; // Hack fix to mortar shooting at targets on elevator
			float Gravity = Shell.Gravity;
			float Speed = Settings.ProjectileLaunchSpeed;
			float SpeedSqr = FMath::Square(Speed);
			float SpeedQuad = FMath::Square(SpeedSqr);

			// Calculate aim height needed to hit target 
			float AimHeight; 
			float Discriminant = SpeedQuad - Gravity * ((Gravity * FMath::Square(HDist)) + (2.f * VDist * SpeedSqr));
			if (Discriminant < 0.f)
			{
				// Can't reach target, decrease gravity appropriately (we want a predictable horizontal speed)
				Gravity = SpeedSqr * (ToDetonationLoc.Size() - VDist) / FMath::Max(0.1f, FMath::Square(HDist));
				Shell.Gravity = Gravity;
				Discriminant = SpeedQuad - Gravity * ((Gravity * FMath::Square(HDist)) + (2.f * VDist * SpeedSqr));
				//if (!ensure(Discriminant >= 0.f))
				if (Discriminant < 0.f)
					Discriminant = 0.f; 
				// Discriminant should never be below 0, but the above seems to work all the same. 
				// TODO: Will need to check over equations again some time.						
			}

			// Select elevation 
			if (FMath::RandRange(0.001f, 1.f) > Settings.HighParabolaFraction)
				AimHeight = (SpeedSqr - FMath::Sqrt(Discriminant)) / Gravity; // Low elevation
			else
				AimHeight = (SpeedSqr + FMath::Sqrt(Discriminant)) / Gravity; // High elevation

			FVector AimDir = FVector(ToDetonationLoc.X, ToDetonationLoc.Y, AimHeight).GetSafeNormal();
			FVector Velocity = AimDir * Settings.ProjectileLaunchSpeed;
			Shell.EnableActor(this);
			Shell.Shoot(Owner, MuzzleLoc, Velocity, WalkFireLoc, Settings.ProjectileLifeTime);	
			
			ShootTime += Settings.SalvoShotInterval;
			BehaviourComp.SustainedAttackCount--;
		}
	}
};
