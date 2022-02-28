import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractShootCapability;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongPlayerUserComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.MusicTargetingComponent;

class UPowerfulSongPlayerShootCapability : UPowerfulSongAbstractShootCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	UHazeAkComponent HazeAkComp;
	USingingComponent SingingComp;
	AHazePlayerCharacter Player;
	UPowerfulSongPlayerUserComponent PlayerUser;
	UMusicTargetingComponent TargetingComp;
	USingingSettings Settings;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(FMath::IsNearlyZero(SingingComp.SongOfLifeCurrent))
			return EHazeNetworkActivation::DontActivate;
		
		if(SingingComp.PowerfulSongCooldown > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(ActionNames::PowerfulSongCharge))
			return EHazeNetworkActivation::DontActivate;

		if(!TargetingComp.bIsTargeting && !SingingComp.bShoutWithoutAim)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeAkComp = UHazeAkComponent::Get(Owner);
		SingingComp = USingingComponent::Get(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
		PlayerUser = UPowerfulSongPlayerUserComponent::Get(Owner);
		Settings = USingingSettings::GetSettings(Owner);

		// Create and cache
		SingingComp.InstantiateProjectile();
		SingingComp.InstantiateProjectile();
		SingingComp.InstantiateProjectile();
		SingingComp.InstantiateProjectile();
		SingingComp.InstantiateProjectile();
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UHazeActivationPoint BestPoint = Player.GetTargetPoint(USongReactionComponent::StaticClass());

		if(BestPoint != nullptr && BestPoint.IsA(USongReactionComponent::StaticClass()))
		{
			ActivationParams.AddObject(n"TargetImpact", BestPoint);
			const float StartingDistanceToTarget = FMath::Max(Owner.ActorLocation.Distance(BestPoint.WorldLocation), 1.0f);
			const float TargetTime = StartingDistanceToTarget / Settings.PowerfulSongMovementSpeed;
			ActivationParams.AddValue(n"TimeToReachTarget", TargetTime);
		}

		ActivationParams.AddVector(n"FacingDirection", SongUserComponent.GetPowerfulSongForward());
		ActivationParams.AddObject(n"Projectile", SingingComp.AvailableProjectileInstance);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		const float AmountToRemove  = Settings.SongOfLifeDurationMaximum * Settings.PowerfulSongCost;

		SingingComp.bIsShooting = true;

		SingingComp.SongOfLifeCurrent = FMath::Max(SingingComp.SongOfLifeCurrent - AmountToRemove, 0.0f);
		SingingComp.SongOfLifeState = ESongOfLifeState::Cooldown;
		SingingComp.SongOfLifeRechargeCooldownCurrent = Settings.SongOfLifeRechargeCooldown;

		const FVector StartLocation = PlayerUser.GetPowerfulSongStartLocation();
		const FVector StartRotation = ActivationParams.GetVector(n"FacingDirection");
		APowerfulSongProjectile Projectile = Cast<APowerfulSongProjectile>(ActivationParams.GetObject(n"Projectile"));

		USongReactionComponent TargetImpact = Cast<USongReactionComponent>(ActivationParams.GetObject(n"TargetImpact"));
		SingingComp.PowerfulSongCooldown = Settings.PowerfulSongCooldown;
		if(TargetImpact != nullptr)
		{
			Projectile.TargetActor = TargetImpact.Owner;
			Projectile.TargetComponent = TargetImpact;
			Projectile.TimeToReachTarget = ActivationParams.GetValue(n"TimeToReachTarget");
		}

		if(SingingComp.ShootingCameraShake.IsValid())
		{
			Player.PlayCameraShake(SingingComp.ShootingCameraShake);
		}

		if(SingingComp.PowerfulSongForceFeedback != nullptr)
		{
			Player.PlayForceFeedback(SingingComp.PowerfulSongForceFeedback, false, false, n"PowerfulSong");
		}
		
		if(Projectile.IsActorDisabled(SingingComp))
			Projectile.EnableActor(SingingComp);
			
		Projectile.OnShootProjectile(StartLocation, StartRotation, PlayerUser.PowerfulSongRange);
		PlayerUser.bWantsToShoot = false;
		
		/*
		Currently unused system, might be re-enabled in the future otherwise this code will be removed // J.S
		
		if(SingComp.PowerfulSongEvent != nullptr)
		{
			SingComp.LastUsedRTPC = SingComp.CurrentPowerfulSongRTPC;

			
			if(Owner.IsAnyCapabilityActive(n"PowerfulSongNoteSwitchUpdateCapability"))
			{
				ResetRTPCs(SingComp.CurrentPowerfulSongRTPC);
			}
			
			SingComp.CurrentPowerfulSongEventInstance = HazeAkComp.HazePostEvent(SingComp.PowerfulSongEvent);	
		}
		*/			
			
		SingingComp.ActivatePowerfulSong();	
		Player.SetCapabilityAttributeObject(n"AudioActivatedPowerfulSong", Projectile);		
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SingingComp.bIsShooting = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SingingComp.DestroyAllProjectiles();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		SingingComp.PowerfulSongCooldown -= DeltaTime;
	}
}
