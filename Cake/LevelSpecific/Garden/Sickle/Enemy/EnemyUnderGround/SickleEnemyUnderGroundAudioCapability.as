import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

class USickleEnemyUnderGroundAudioCapability : UHazeCapability
{
	ASickleEnemy Burrower;

	UPROPERTY(Category = "Movement")
	UAkAudioEvent BodyMovementLoopEvent;

	UPROPERTY(Category = "Movement")
	UAkAudioEvent OnStartBurrowEvent;
	
	UPROPERTY(Category = "Movement")
	UAkAudioEvent OnShowHeadEvent;

	UPROPERTY(Category = "Projectile")
	UAkAudioEvent OnShootProjectileEvent;
	
	// Need seperate event for hit ground/player?
	UPROPERTY(Category = "Projectile")
	UAkAudioEvent OnProjectileImpactEvent;

	UPROPERTY(Category = "Vine")
	UAkAudioEvent OnCaughtByVineEvent;

	UPROPERTY(Category = "Vine")
	UAkAudioEvent OnReleasedFromVineEvent;

	UPROPERTY(Category = "Health")
	UAkAudioEvent OnTakeDamageEvent;

	UPROPERTY(Category = "Health")
	UAkAudioEvent OnKilledEvent;
	
	UPROPERTY(Category = "Health")
	UAkAudioEvent OnDeathDespawnEvent;

	UPROPERTY(EditConst, Category = "RTPC")
	const FString IsBurrowedRTPC = "RTPC_Character_Enemy_Garden_Burrower_IsBelowGround";

	private bool bVineWasAttached = false;
	private bool bWasReleasedFromVine = false;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Burrower = Cast<ASickleEnemy>(Owner);
		Burrower.HazeAkComp.AttachTo(Burrower.Mesh, n"LowerJaw", EAttachLocation::SnapToTarget);
		Burrower.OnKilled.AddUFunction(this, n"OnKilled");
		Burrower.SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"OnTakeDamage");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Burrower.IsActorDisabled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Burrower.IsActorDisabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Burrower.HazeAkComp.HazePostEvent(BodyMovementLoopEvent);
		Burrower.HazeAkComp.HazePostEvent(OnStartBurrowEvent);
		Burrower.HazeAkComp.SetRTPCValue(IsBurrowedRTPC, 1.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioOnBurrow") == EActionStateStatus::Active)
		{
			if(!bWasReleasedFromVine)
			{
				Burrower.HazeAkComp.HazePostEvent(OnStartBurrowEvent);
			}

			bWasReleasedFromVine = false;
			Burrower.HazeAkComp.SetRTPCValue(IsBurrowedRTPC, 1.f, 1.f);
			//PrintToScreenScaled("On Start Burrow", 2.f, FLinearColor :: LucBlue, 2.f);
		}

		if(ConsumeAction(n"AudioOnShowHead") == EActionStateStatus::Active)
		{
			Burrower.HazeAkComp.HazePostEvent(OnShowHeadEvent);
			Burrower.HazeAkComp.SetRTPCValue(IsBurrowedRTPC, 0.f, 1.f);
			//PrintToScreenScaled("On show head", 2.f, FLinearColor :: LucBlue, 2.f);
		}

		if(ConsumeAction(n"AudioOnShootProjectile") == EActionStateStatus::Active)
		{
			Burrower.HazeAkComp.HazePostEvent(OnShootProjectileEvent);
			//PrintToScreenScaled("on shoot projectile", 2.f, FLinearColor :: LucBlue, 2.f);
		}

		FVector ProjectileImpactLoc;
		if(ConsumeAttribute(n"AudioOnProjectileImpact", ProjectileImpactLoc))
		{
			UHazeAkComponent::HazePostEventFireForget(OnProjectileImpactEvent, FTransform(ProjectileImpactLoc));
			//PrintToScreenScaled("projectile impact", 2.f, FLinearColor :: LucBlue, 2.f);
		}

		if(!bVineWasAttached && Burrower.bIsBeeingHitByVine)
		{
			bVineWasAttached = true;
			Burrower.HazeAkComp.HazePostEvent(OnCaughtByVineEvent);
			//PrintToScreenScaled("caught by vine", 2.f, FLinearColor :: LucBlue, 2.f);
		}
		else if(bVineWasAttached && !Burrower.bIsBeeingHitByVine)
		{
			bVineWasAttached = false;
			bWasReleasedFromVine = true;
			Burrower.HazeAkComp.HazePostEvent(OnReleasedFromVineEvent);
			//PrintToScreenScaled("released from vine", 2.f, FLinearColor :: LucBlue, 2.f);
		}
	}

	UFUNCTION()
	void OnKilled(ASickleEnemy Actor, bool bInitialDeath)
	{
		UAkAudioEvent DeathEvent = bInitialDeath ? OnKilledEvent : OnDeathDespawnEvent;
		Burrower.HazeAkComp.HazePostEvent(DeathEvent);
		//PrintToScreenScaled("on killed", 2.f, FLinearColor :: LucBlue, 2.f);
	}

	UFUNCTION()
	void OnTakeDamage(int Damage)
	{
		Burrower.HazeAkComp.HazePostEvent(OnTakeDamageEvent);
		//PrintToScreenScaled("on take damage", 2.f, FLinearColor :: LucBlue, 2.f);
	}

}