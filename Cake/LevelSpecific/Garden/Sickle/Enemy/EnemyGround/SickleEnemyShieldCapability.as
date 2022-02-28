import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;

class USickleEnemyShieldCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 90;

	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;
	UVineImpactComponent VineImpactComponent;
	USickleCuttableHealthComponent SickleImpactComponent;
	USickleCuttableComponent ShieldCuttableComponent;

	EHazePlayer LockedPlayer = EHazePlayer::MAX;
	float TargetRadialProgress = 0;
	float TimeLeftToLoseVineHit = 0;

	bool bCodyIsBehind = false;
	bool bMayIsBehind = false;

	int ForceFaceMayInstigators = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
		VineImpactComponent = UVineImpactComponent::Get(AiOwner);
		VineImpactComponent.CurrentWidgetRadialProgress = 0;

		SickleImpactComponent = AiOwner.SickleCuttableComp;
		SickleImpactComponent.OnCutWithSickle.AddUFunction(this, n"OnSickleDamageReceived");

		ShieldCuttableComponent = USickleCuttableComponent::Get(AiOwner, n"ShieldCuttableComponent");
		ShieldCuttableComponent.OnActivationStatusChanged.AddUFunction(this, n"ForceFaceMay");
		ShieldCuttableComponent.GetCustomInvulnerabilityForPlayer.BindUFunction(this, n"GetShieldInvulderable");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(VineImpactComponent.CurrentWidgetRadialProgress != TargetRadialProgress)
		{
			const float Multiplier = TargetRadialProgress > 0 ? 3.f : 1.f;
			VineImpactComponent.CurrentWidgetRadialProgress = FMath::FInterpConstantTo(VineImpactComponent.CurrentWidgetRadialProgress, TargetRadialProgress, DeltaTime, Multiplier);
			if(VineImpactComponent.CurrentWidgetRadialProgress > 0.99f)
				VineImpactComponent.CurrentWidgetRadialProgress = 1.f;
		}

		TargetRadialProgress = 0;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!AiComponent.bHasShield)
			return EHazeNetworkActivation::DontActivate;

		if(AiComponent.bCanDropShield)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiComponent.bHasShield)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiComponent.bCanDropShield)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		VineImpactComponent.AttachmentMode = EVineAttachmentType::Component;
		AiOwner.SickleCuttableComp.GetCustomInvulnerabilityForPlayer.BindUFunction(this, n"GetCustomInvulnerabilityForPlayer");
		SetMayBehind(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		VineImpactComponent.AttachmentMode = EVineAttachmentType::Whip;
		AiOwner.SickleCuttableComp.BonusScoreMultiplier = 0.5f;
		AiOwner.SickleCuttableComp.GetCustomInvulnerabilityForPlayer.Clear();
		AiOwner.UnblockMovementWithInstigator(this);
	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		auto Cody = Game::GetCody();
		auto May = Game::GetMay();
		{
			const FVector HorizontalDirToMay = (AiOwner.GetActorLocation() - May.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			const float BehindAngle = HorizontalDirToMay.DotProduct(AiOwner.GetActorForwardVector());
			const bool bWantToBeBehind = BehindAngle > -0.5f && AiOwner.bIsBeeingHitByVine;
			if(bMayIsBehind != bWantToBeBehind)
				SetMayBehind(bWantToBeBehind);
		}

		if(AiOwner.bIsBeeingHitByVine)
		{
			AiOwner.SickleCuttableComp.BonusScoreMultiplier = 1.f;
			if(LockedPlayer != EHazePlayer::Cody)
			{
				AiOwner.LockPlayerAsTarget(Cody);
				LockedPlayer = EHazePlayer::Cody;
				AiOwner.BlockMovementWithInstigator(this);
			}

			const FVector DirToCody = (Cody.GetActorLocation() - AiOwner.GetActorLocation()).GetSafeNormal();
			AiComponent.SetTargetFacingDirection(DirToCody.GetSafeNormal(), 10.f);
		}
		else 
		{
			AiOwner.SickleCuttableComp.BonusScoreMultiplier = 0.2f;
			if(LockedPlayer == EHazePlayer::Cody)
			{
				AiOwner.SetFreeTargeting();
				LockedPlayer = EHazePlayer::MAX;
				AiOwner.UnblockMovementWithInstigator(this);
			}
		}

		
		if(LockedPlayer == EHazePlayer::MAX)
		{
			if(AiOwner.SickleCuttableComp.IsTargetedBy(May) || ForceFaceMayInstigators > 0)
			{
				AiOwner.LockPlayerAsTarget(May);
				LockedPlayer = EHazePlayer::May;
			}
		}
	
		if(LockedPlayer == EHazePlayer::May)
		{
			if(!AiOwner.SickleCuttableComp.IsTargetedBy(May))
			{
				AiOwner.SetFreeTargeting();
				LockedPlayer = EHazePlayer::MAX;
			}
		}

		if(ForceFaceMayInstigators > 0 && !AiOwner.bIsBeeingHitByVine)
		{
			// Force facing may when she is attacking
			const FVector DirToMay = (May.GetActorLocation() - AiOwner.GetActorLocation()).GetSafeNormal();
			AiComponent.SetTargetFacingDirection(DirToMay.GetSafeNormal(), 20.f);
		}

		// Vine stuff happens on codys side...	
		if(Cody.HasControl())
		{
		 	auto VineImpact = UVineImpactComponent::Get(Owner);
			//VineImpact.SetCanActivate(!AiOwner.bAttackingPlayer);
			
			VineImpact.CurrentWidgetRadialProgress = 0;
		 	if(AiOwner.bIsBeeingHitByVine)
		 	{
		 		TimeLeftToLoseVineHit += DeltaTime;
		 		TargetRadialProgress = FMath::Lerp(1.f, 0.f, FMath::Min(TimeLeftToLoseVineHit / AiComponent.TimeToLoseVineImpact, 1.f));
		 		VineImpactComponent.CurrentWidgetRadialProgress = TargetRadialProgress;
				
				// We add network ping here to make it snappier
				if(TimeLeftToLoseVineHit >= AiComponent.TimeToLoseVineImpact)
				{	
					UHazeCrumbComponent::Get(Cody).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_LoseVineHit"), FHazeDelegateCrumbParams());	
				}
		 	}
		 	else if(TimeLeftToLoseVineHit > 0)
		 	{
				if(TimeLeftToLoseVineHit > 0.5f)
				{
					NetResetSpawnManager();
				}

		 		TimeLeftToLoseVineHit = 0;
		 	}
		}
	}

	UFUNCTION(NetFunction)
	void NetResetSpawnManager()
	{
		AiComponent.EnableSpawning();
	}

	void SetMayBehind(bool bStatus)
	{	
		if(bStatus && AiOwner.bIsBeeingHitByVine)
		{
			bMayIsBehind = true;
			SickleImpactComponent.ChangeValidActivator(EHazeActivationPointActivatorType::May);
			ShieldCuttableComponent.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}
		else
		{
			bMayIsBehind = false;
			SickleImpactComponent.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			ShieldCuttableComponent.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_LoseVineHit(FHazeDelegateCrumbData CrumbData)
	{
		auto Cody = Game::GetCody();
		Cody.SetCapabilityActionState(n"ForceVineRelease", EHazeActionState::ActiveForOneFrame);
		AiOwner.SetAnimBoolParam(n"ForceVineRelease", true);	
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSickleDamageReceived(int DamageAmount)
	{	

		if(IsActive() && HasControl() && AiOwner.bIsBeeingHitByVine)
		{
			TimeLeftToLoseVineHit += 0.25f;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	bool GetCustomInvulnerabilityForPlayer(AHazePlayerCharacter ForPlayer) const
	{
		if(ForPlayer.IsCody())
		{
			return !bCodyIsBehind;
		}
		else
		{
			return !bMayIsBehind;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	bool GetShieldInvulderable(AHazePlayerCharacter ForPlayer) const
	{
		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void ForceFaceMay(bool bStatus)
	{
		if(bStatus)
		{
			AiOwner.bIsTakingSickleDamage = true;
			ForceFaceMayInstigators++;
		}
		else
		{
			AiOwner.bIsTakingSickleDamage = false;
			ForceFaceMayInstigators--;
		}
	}
}