import Cake.Weapons.RangedWeapon.RangedWeaponSettings;
import Cake.Weapons.RangedWeapon.RangedWeaponProjectileSettings;
import Cake.Weapons.RangedWeapon.RangedWeaponProjectile;
import Cake.Weapons.RangedWeapon.RangedWeaponImpactComponent;

#if !RELEASE
const FConsoleVariable CVar_RangedWeaponDebugDraw("RangedWeapon.DebugDraw", 0);
const FConsoleVariable CVar_RangedWeaponUnlimitedAmmo("RangedWeapon.UnlimitedAmmo", 0);
#endif // !RELEASE

settings RangedWeaponSettingsDefault for URangedWeaponSettings
{

}

settings RangedWeaponProjectileSettingsDefault for URangedWeaponProjectileSettings
{

}

// Currently empty because in the future, maybe we can fill it in with something
struct FRangedWeaponFireInfo
{
	UPROPERTY()
	FHitResult Hit;
	UPROPERTY()
	URangedWeaponComponent RangedWeapon;
}

event void FOnRangedWeaponFireDelegate(const FRangedWeaponFireInfo& RangedWeaponFireInfo);

class URangedWeaponComponent : UActorComponent
{
	UPROPERTY(Category = Setup)
	URangedWeaponSettings RangedWeaponSettings = RangedWeaponSettingsDefault;
	URangedWeaponSettings RangedWeaponDefaultSettings;

	UPROPERTY(Category = Setup)
	URangedWeaponProjectileSettings RangedWeaponProjectileSettings = RangedWeaponProjectileSettingsDefault;
	URangedWeaponProjectileSettings ProjectileDefaultSettings;

	UPROPERTY()
	FOnRangedWeaponFireDelegate OnRangedWeaponFire;

	UPROPERTY(NotEditable, Category = Ammo, BlueprintReadOnly)
	int AmmoTotalCurrent = 0;
	UPROPERTY(NotEditable, Category = Ammo, BlueprintReadOnly)
	int AmmoClipCurrent = 0;
	
	float FireRateElapsed = 0.0f;

	UFUNCTION(BlueprintPure)
	float GetFireRateElapsedCurrent() const { return FireRateElapsed; }

	float FireRateMultiplier = 1.0f;
	bool bFiredBullet = false;
	private bool bIsFiring = false;

	bool bFireButtonDown = false;

	UFUNCTION(BlueprintPure)
	bool IsFiring() const 
	{ 
		return !IsClipOutOfAmmo() && bFireButtonDown;
	}

	// only used for network purpose
	private int BulletSpawnCount = 0;

	private AHazeActor HazeOwner;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FireRateElapsed += DeltaTime;
		bFiredBullet = false;
	}

	UFUNCTION(BlueprintPure)
	float GetRemainingAmmoInClipAsFraction() const
	{
		return float(AmmoClipCurrent) / float(RangedWeaponDefaultSettings.AmmoClip);
	}

	int GetAmmoClipMaximum() const
	{
		return RangedWeaponDefaultSettings.AmmoClip;
	}

	int GetAmmoTotalMaximum() const
	{
		return RangedWeaponDefaultSettings.AmmoTotal;
	}

	bool IsClipOutOfAmmo() const
	{
		return AmmoClipCurrent <= 0;
	}

	bool IsClipFull() const
	{
		return AmmoClipCurrent >= RangedWeaponDefaultSettings.AmmoClip;
	}

	float GetFireRate() const
	{
		return RangedWeaponDefaultSettings.FireRate * FireRateMultiplier;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.ApplySettings(RangedWeaponSettings, this, EHazeSettingsPriority::Gameplay);
		HazeOwner.ApplySettings(RangedWeaponProjectileSettings, this, EHazeSettingsPriority::Gameplay);

		RangedWeaponDefaultSettings = URangedWeaponSettings::GetSettings(HazeOwner);
		ProjectileDefaultSettings = URangedWeaponProjectileSettings::GetSettings(HazeOwner);
		AmmoTotalCurrent = RangedWeaponDefaultSettings.AmmoTotal;
		AmmoClipCurrent = RangedWeaponDefaultSettings.AmmoClip;
	}

	UFUNCTION(BlueprintPure)
	bool CanFire() const
	{
		return FireRateElapsed > GetFireRate() && AmmoClipCurrent > 0;
	}

	bool Fire(FHitResult& OutHit)
	{
		return Fire(OutHit, Owner.ActorLocation, Owner.ActorForwardVector);
	}

	bool Fire(FHitResult& OutHit, FVector ForwardDirection)
	{
		return Fire(OutHit, Owner.ActorLocation, ForwardDirection);
	}

	// Used on the remote to simulate fire, already knowing what we are going to hit
	void Fire_ReplicatedHit(FVector StartLocation, FVector ImpactPoint, FVector ImpactNormal, UPrimitiveComponent HitComponent)
	{
		FRangedWeaponFireInfo Info;
		Info.RangedWeapon = this;
		Info.Hit.SetBlockingHit(HitComponent != nullptr);
		Info.Hit.TraceStart = StartLocation;
		Info.Hit.TraceEnd = StartLocation + (ImpactPoint - StartLocation).GetSafeNormal() * ProjectileDefaultSettings.Range;
		//System::DrawDebugSphere(Info.Hit.TraceEnd);
		//System::DrawDebugLine(Info.Hit.TraceStart, Info.Hit.TraceEnd, FLinearColor::Green, 1);
		Info.Hit.ImpactPoint = ImpactPoint;
		Info.Hit.ImpactNormal = ImpactNormal;
		Info.Hit.Actor = HitComponent != nullptr ? HitComponent.Owner : nullptr;
		Info.Hit.Component = HitComponent;
		OnRangedWeaponFire.Broadcast(Info);
		bFiredBullet = true;

		if(HitComponent != nullptr)
		{
			URangedWeaponImpactComponent ImpactComponent = URangedWeaponImpactComponent::Get(HitComponent.Owner);

			if(ImpactComponent != nullptr)
			{
				ImpactComponent.HandleImpact(HazeOwner, Info.Hit);
			}
		}
	}

	bool Fire(FHitResult& OutHit, FVector StartLocation, FVector ForwardDirection)
	{
		if(!CanFire())
		{
			return false;
		}

		bIsFiring = true;

		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(HazeOwner);
		const FVector EndLocation = StartLocation + (ForwardDirection * ProjectileDefaultSettings.Range);
		EDrawDebugTrace DrawDebugTrace = EDrawDebugTrace::None;

#if !RELEASE
		if(CVar_RangedWeaponDebugDraw.GetInt() == 1)
		{
			DrawDebugTrace = EDrawDebugTrace::ForDuration;
		}
#endif // !RELEASE

		System::LineTraceSingle(StartLocation, EndLocation, ETraceTypeQuery::Visibility, false, IgnoreActors, DrawDebugTrace, OutHit, false);

		

		if(ProjectileDefaultSettings.ProjectileType == ERangedWeaponProjectileType::Hitscan && OutHit.Actor != nullptr)
		{
			URangedWeaponImpactComponent ImpactComponent = URangedWeaponImpactComponent::Get(OutHit.Actor);

			if(ImpactComponent != nullptr)
			{
				ImpactComponent.HandleImpact(HazeOwner, OutHit);
			}
		}
		else if(ProjectileDefaultSettings.ProjectileType == ERangedWeaponProjectileType::Projectile)
		{
			const FVector SpawnLocation = StartLocation;
			const FRotator SpawnRotation = ForwardDirection.Rotation();

			ARangedWeaponProjectile RangedWeaponProjectile = Cast<ARangedWeaponProjectile>(SpawnActor(ProjectileDefaultSettings.ProjectileClass, SpawnLocation, SpawnRotation, bDeferredSpawn = true));
			RangedWeaponProjectile.MakeNetworked(Name, BulletSpawnCount);
			BulletSpawnCount++;
			RangedWeaponProjectile.SetControlSide(HazeOwner);
			RangedWeaponProjectile.DamageCauser = HazeOwner;
			RangedWeaponProjectile.OriginLocation = StartLocation;
			FinishSpawningActor(RangedWeaponProjectile);
		}

		FireRateElapsed = 0.0f;

		if(!RangedWeaponDefaultSettings.bInfiniteAmmoClip
#if !RELEASE
			&& CVar_RangedWeaponUnlimitedAmmo.GetInt() == 0
#endif // !RELEASE
			)
		{
			AmmoClipCurrent--;
		}

		FRangedWeaponFireInfo Info;
		Info.RangedWeapon = this;

		if(OutHit.Actor == nullptr)
		{
			OutHit.ImpactPoint = StartLocation + (ForwardDirection * 20000.0f);
			OutHit.Normal = ForwardDirection * -1.0f;
			OutHit.ImpactNormal = ForwardDirection * -1.0f;
		}

		Info.Hit = OutHit;
		OnRangedWeaponFire.Broadcast(Info);
		bFiredBullet = true;
		
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool CanReload() const
	{
		if(AmmoClipCurrent == RangedWeaponDefaultSettings.AmmoClip)
		{
			return false;
		}

		if(RangedWeaponDefaultSettings.bInfiniteAmmoTotal)
		{
			return true;
		}

		return AmmoTotalCurrent > 0;
	}

	bool Reload()
	{
		if(!CanReload())
		{
			return false;
		}

		const int OldAmmoTotal = AmmoTotalCurrent;
		const int OldAmmoClip = AmmoClipCurrent;
		
		if(RangedWeaponDefaultSettings.bInfiniteAmmoTotal)
		{
			AmmoClipCurrent = RangedWeaponDefaultSettings.AmmoClip;
		}
		else
		{
			const int WantedReloadAmount = RangedWeaponDefaultSettings.AmmoClip - AmmoClipCurrent;

			// We just need to verify that the total amount of ammo is enough so we reload with the correct amount.
			if(WantedReloadAmount <= AmmoTotalCurrent)
			{
				AmmoTotalCurrent -= WantedReloadAmount;
				AmmoClipCurrent = RangedWeaponDefaultSettings.AmmoClip;
			}
			else
			{
				// We know that the remaining ammo is not enough to fill the clip so let's take what we can.
				AmmoClipCurrent += AmmoTotalCurrent;
				AmmoTotalCurrent = 0;
			}
		}

		BP_OnReload(OldAmmoClip, OldAmmoTotal);

		return true;
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Reload"))
	void BP_OnReload(int OldAmmoClip, int OldAmmoTotal) {}
}
