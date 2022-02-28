import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoSettings;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.GooComponent;

struct FTomatoDashHitInfo
{
	TArray<UTomatoDashTargetComponent> HitTargets;
}

class UTomatoDashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(MovementSystemTags::Dash);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 8;

	ATomato Tomato;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	AHazePlayerCharacter Player;
	UGooComponent GooComp;
	TArray<UTomatoDashTargetComponent> HitTargets;

	FHazeAcceleratedRotator CurrentRotation;
	FRotator TargetRotation;

	float RotationElapsed = 0.0f;

	float DistanceToTravelTarget = 2000.0f;
	float DistanceToTravelCurrent = 0.0f;

	FVector TargetDirection;
	FVector StartLocation;

	float Elapsed = 0.0f;
	float CooldownElapsed = 0.0f;

	UTomatoSettings Settings;

	bool bHitSomething = false;
	bool bInterruptDash = false;

	float RotationDuration = 0.25f;

	float GooElapsed = 0.0f;
	float GooTarget = 0.2f;

	bool bWasStandingOnGoo = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Tomato = Cast<ATomato>(Owner);
		Player = Tomato.OwnerPlayer;
		GooComp = UGooComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = UTomatoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Tomato.HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if(!Tomato.bWantsToDash)
			return EHazeNetworkActivation::DontActivate;

		if(CooldownElapsed > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(Tomato.bDashDisabledByGoo)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddVector(n"FacingDirection", DashFacingDirection);
		if(HasDashTarget())
			ActivationParams.AddActionState(n"HasDashTarget");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Tomato.BounceCounter = 0;
		Tomato.bIsDashing = true;
		bInterruptDash = false;
		
		Tomato.bIsBlockInput = true;
		
		const FVector FacingDirection = ActivationParams.GetVector(n"FacingDirection");
		ApplyDashImpulse(FacingDirection);

		Internal_OnDash(FacingDirection, ActivationParams.GetActionState(n"HasDashTarget"));
		Tomato.bApplyRotation = false;
		Tomato.BP_OnDashEnter();
		Owner.SetCapabilityActionState(n"TomatoDash", EHazeActionState::Active);
		Tomato.AccelerationCurrent = Settings.Acceleration;
		Tomato.MaxSpeedCurrent = Settings.MaxSpeed;
		Tomato.FrictionCurrent = Settings.Friction;
		bWasStandingOnGoo = GooComp.bIsStandingInsideGoo;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		ASickleEnemy Enemy = Cast<ASickleEnemy>(MoveComp.Impacts.ForwardImpact.Actor);
		if(Enemy != nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Settings.bExitDashBasedOnLength && StartLocation.DistSquared(Owner.ActorLocation) > FMath::Square(Settings.ExitDashLength))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Settings.bExitDashBasedOnVelocity && Tomato.Velocity.SizeSquared() < FMath::Square(Settings.ExitDashVelocity))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(HitTargets.Num() > 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bHitSomething)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bInterruptDash)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Tomato.bDashDisabledByGoo)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if(bHitSomething)
		{
			Tomato.Bounce(Tomato.Velocity.GetSafeNormal2D() * -1, 1.0f);
			DeactivationParams.AddActionState(n"HitSomething");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(DeactivationParams.GetActionState(n"HitSomething"))
		{
			Owner.SetCapabilityActionState(n"TomatoDashHit", EHazeActionState::Active);	// audio
			Tomato.PlayHitWallCameraShake();

			if(HasControl())
				Tomato.PlayHitWallForceFeedback();
		}
		
		Tomato.bIsDashing = false;
		Tomato.bIsBlockInput = false;
		Tomato.ClearSettingsByInstigator(this);
		Tomato.bApplyRotation = true;
		Tomato.BP_OnDashExit();
		Tomato.Velocity.Z = 0.0f;
		Tomato.StartIdleAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RotationElapsed -= DeltaTime;

		if(RotationElapsed > 0.0f)
		{
			CurrentRotation.AccelerateTo(TargetRotation, RotationDuration, DeltaTime);
			Tomato.TomatoRoot.SetWorldRotation(CurrentRotation.Value);
		}

		if(!HasControl())
			return;

		GetClosestHitTargets();

		if(!Settings.bMustDeactivateCapability && Tomato.bWantsToDash && CooldownElapsed < 0.0f)
		{
			const FVector FacingDirection = DashFacingDirection;
			ApplyDashImpulse(FacingDirection);
			OnDash(FacingDirection);
		}

		if(Tomato.CurrentPlayerInput.SizeSquared() > 0.1f && !HasDashTarget())
		{
			const float InputDot = Tomato.Velocity.GetSafeNormal2D().DotProduct(Tomato.CurrentPlayerInput);
			bInterruptDash = InputDot < 0.5f;
		}

		if(HitTargets.Num() == 0)
			bHitSomething = MoveComp.ForwardHit.bBlockingHit;
	}

	void ApplyDashImpulse(FVector FacingDirection)
	{
		StartLocation = Owner.ActorLocation;
		Tomato.Velocity = FacingDirection.GetSafeNormal() * Settings.DashImpulse;
		bHitSomething = false;
		CooldownElapsed = Settings.DashCooldown;
		DistanceToTravelCurrent = 0.0f;

		Tomato.ClearSettingsByInstigator(this);

		if(HasDashTarget())
			Tomato.ApplySettings(Tomato.TomatoLockOnSettings, this, EHazeSettingsPriority::Override);
		else
			Tomato.ApplySettings(Tomato.TomatoDashSettings, this, EHazeSettingsPriority::Override);
	}

	FVector GetDashFacingDirection() const property
	{
		const UTomatoDashTargetComponent TargetComponent = DashTarget;

		FVector FacingDirection = FVector::ZeroVector;

		if(TargetComponent != nullptr)
		{
			if(Tomato.bIsJumping)
			{
				FacingDirection = (TargetComponent.Owner.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			}
			else
			{
				FacingDirection = (TargetComponent.Owner.ActorLocation - Owner.ActorLocation).GetSafeNormal().ConstrainToPlane(MoveComp.WorldUp);
			}
		}
		else if(Tomato.CurrentPlayerInput.IsNearlyZero())
		{
			FacingDirection = Tomato.Camera.ViewRotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp);
		}
		else
		{
			FacingDirection = Tomato.CurrentPlayerInput;
		}

		return FacingDirection;
	}

	FVector CalculateRandomFaceDirectionToCamera()
	{
		return ((Tomato.Camera.ViewLocation - Tomato.TomatoRoot.WorldLocation).GetSafeNormal() + (FMath::VRand() * 0.7f)).GetSafeNormal();
	}

	UTomatoDashTargetComponent GetDashTarget() const property
	{
		UTomatoDashTargetComponent TargetComponent = Cast<UTomatoDashTargetComponent>(Player.GetActivePoint());
		if(TargetComponent == nullptr)
		{
			TargetComponent = Cast<UTomatoDashTargetComponent>(Player.GetTargetPoint(UTomatoDashTargetComponent::StaticClass()));
		}

		return TargetComponent;
	}

	bool HasDashTarget() const
	{
		return DashTarget != nullptr;
	}

	void SetTomatoFaceDirection(FVector TargetDirection)
	{
		Tomato.TomatoRoot.SetWorldRotation(TargetDirection.Rotation());
	}

	UFUNCTION()
	void Crumb_SetTomatoFaceDirection(const FHazeDelegateCrumbData& CrumbData)
	{
		FVector FaceDirection = CrumbData.GetVector(n"FaceRotation");
		SetTomatoFaceDirection(FaceDirection);
	}

	private void OnDash(FVector FacingDirection)
	{
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddVector(n"FacingDirection", FacingDirection);
		if(HasDashTarget())
			CrumbParams.AddActionState(n"HasDashTarget");
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnDash"), CrumbParams);
	}

	private void Internal_OnDash(FVector FacingDirection, bool bHasTarget)
	{
		if(Tomato.DashAnim != nullptr)
		{
			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = Tomato.DashAnim;
			Tomato.SkeletalMesh.PlaySlotAnimation(AnimParams);
		}

		RotationElapsed = RotationDuration;
		TargetRotation = FacingDirection.Rotation();
		CurrentRotation.Value = Tomato.TomatoRoot.WorldRotation;
	}

	UFUNCTION()
	void Crumb_OnDash(FHazeDelegateCrumbData CrumbData)
	{
		FVector FacingDirection = CrumbData.GetVector(n"FacingDirection");
		Internal_OnDash(FacingDirection, CrumbData.GetActionState(n"HasTarget"));
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Player.UpdateActivationPointAndWidgets(UTomatoDashTargetComponent::StaticClass());
		CooldownElapsed -= DeltaTime;

		if(!HasControl())
			return;

		if(GooComp.bIsStandingInsideGoo && !Tomato.bDashDisabledByGoo)
		{
			GooElapsed += DeltaTime;

			if(GooElapsed > GooTarget)
			{
				Tomato.bDashDisabledByGoo = true;
			}
		}

		if(bWasStandingOnGoo && !GooComp.bIsStandingInsideGoo)
		{
			GooElapsed = 0.0f;
			Tomato.bDashDisabledByGoo = false;
		}

		bWasStandingOnGoo = GooComp.bIsStandingInsideGoo;
	}

	void GetClosestHitTargets()
	{
		if(!HasControl())
			return;

		HitTargets.Empty();
		UHazeAITeam DashTargetTeam = HazeAIBlueprintHelper::GetTeam(n"TomatoDashTargetTeam");

		if(DashTargetTeam == nullptr)
			return;

		const TSet<AHazeActor>& DashTargetMembers = DashTargetTeam.GetMembers();
		const float TomatoHitRadiusSq = FMath::Square(Settings.HitRadius);

		for(AHazeActor Target : DashTargetMembers)
		{
			if(Target == nullptr)
				continue;

			UTomatoDashTargetComponent DashTargetComp = UTomatoDashTargetComponent::Get(Target);

			if(DashTargetComp == nullptr)
				continue;
			if(!DashTargetComp.bValidTarget)
				continue;
			if(DashTargetComp.bDead)
				continue;

			const float HitRadiusSq = FMath::Square(DashTargetComp.HitRadius);
			 
			const float DistanceSq = Owner.ActorLocation.DistSquared2D(Target.ActorLocation);

			if(DistanceSq < (HitRadiusSq + TomatoHitRadiusSq))
				HitTargets.Add(DashTargetComp);
		}

		if(HitTargets.Num() > 0)
		{
			Tomato.Bounce(Tomato.Velocity.GetSafeNormal2D() * -1, 1.0f);
			Tomato.PlayHitEnemyForceFeedback();

			FTomatoDashHitInfo HitInfo;
			for(UTomatoDashTargetComponent TargetComp : HitTargets)
				HitInfo.HitTargets.Add(TargetComp);

			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddStruct(n"HitTargets", HitInfo);
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_HandleHits"), CrumbParams);
		}
	}

	UFUNCTION()
	private void Crumb_HandleHits(FHazeDelegateCrumbData CrumbData)
	{
		FTomatoDashHitInfo HitInfo;
		CrumbData.GetStruct(n"HitTargets", HitInfo);
		bool bHitEnemy = false;

		for(UTomatoDashTargetComponent TargetComp : HitInfo.HitTargets)
		{
			if(TargetComp == nullptr)
				continue;
			
			TargetComp.HandleHitByTomato();
			Owner.SetCapabilityActionState(n"TomatoDashHit", EHazeActionState::Active);	// audio

			ASickleEnemy SickleEnemy = Cast<ASickleEnemy>(TargetComp.Owner);
			bHitEnemy = true;

			if(SickleEnemy != nullptr)
			{
				SickleEnemy.KilledByTomato();
				SickleEnemy.CapsuleComponent.SetCollisionProfileName(n"IgnorePlayerCharacter");
			}
		}

		if(bHitEnemy)
			Tomato.PlayHitEnemyCameraShake();
	}
}
