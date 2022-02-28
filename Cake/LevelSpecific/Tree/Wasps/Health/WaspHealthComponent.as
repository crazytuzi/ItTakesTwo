import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;
import Cake.Weapons.Sap.SapManager;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspDebugSlayerComponent;
import Peanuts.Health.HealthBarWidget;
import Peanuts.WeaponTrace.WeaponTraceStatics;
import Peanuts.Health.BossHealthBarWidget;
import Cake.Weapons.Sap.SapWeaponSettings;

event void FWaspOnTakeDamage(AHazeActor Wasp, int RemainingHitpoints);
event void FWaspOnDie(AHazeActor Wasp);
event void FWaspHitBySap();
event void FWaspHitByMatch();
event void FWaspPreDeath();

class UWaspHealthComponent : UActorComponent
{
	UPROPERTY(Category = "GUI")
	TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;
	UHealthBarWidget MayHealthBar;
	UHealthBarWidget CodyHealthBar;

	UPROPERTY(Category = "GUI")
	TSubclassOf<UBossHealthBarWidget> BossHealthBarWidgetClass;
	UBossHealthBarWidget BossHealthBar;

	UPROPERTY(Category = "GUI")
	FText BossHealthBarDesc;

    // Triggers when we take damage
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnTakeDamage OnTakeDamage;

    // Triggers when we die
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspOnDie OnDie;

	// Trigger when set to dead on remote side 
	FWaspPreDeath OnRemotePreDeath;

    // Triggers when we get hit by a match
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspHitByMatch OnHitByMatch;

    // Triggers when we get hit by sap
	FWaspHitBySap OnHitBySap;

	TArray<UObject> UnsappableInstigators;
	TArray<UActorComponent> Sappables;

	USkinnedMeshComponent ArmourComp = nullptr;
	int CustomSapMaterialIndex = 3;
	AHazeCharacter CharOwner = nullptr;

    // We have this much sap mass attached to us
    float SapMass = 0.f;

	int HitPoints = 1;
	bool bIsHurt = false;
	float TakeDamageCooldownTime = 0.f;	
	bool bIsDead = false;
	bool bShouldRemoveSap = false;
	float DelayedSappedTime = 0.f;
	UWaspComposableSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CharOwner = Cast<AHazeCharacter>(Owner);
		Settings = UWaspComposableSettings::GetSettings(Cast<AHazeActor>(Owner));
		Reset();

		TArray<UActorComponent> PrimComps = Owner.GetComponentsByClass(UPrimitiveComponent::StaticClass());
		for (UActorComponent Comp : PrimComps)
		{
			if (Comp.HasTag(n"SapStickable"))
				Sappables.Add(Comp);
		}

		ArmourComp = UPoseableMeshComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBars();
	}

	UFUNCTION()
	void Reset()
	{
		HitPoints = Settings.HitPoints;
		bIsHurt = false;
		bIsDead = false;

		USapResponseComponent SapComp = USapResponseComponent::Get(Owner);
		if (SapComp != nullptr)
			DisableAllSapsAttachedTo(Owner.RootComponent);
		SapMass = 0.f;
		UpdateCustomSapBlob();
		bShouldRemoveSap = false;
		DelayedSappedTime = 0.f;

		UnsappableInstigators.Empty();
		for (UActorComponent Sappable : Sappables)
		{
			Sappable.AddTag(n"SapStickable");
		}

		// Reset gets called from BeginPlay, and adding widgets from BeginPlay is dangerous
		//SetupHealthBars();
	}

    UFUNCTION()
    void OnSapExploded(FSapAttachTarget Where, float Mass)
    {
        TakeDamage(Mass);
    }

    UFUNCTION()
    void OnSapExplodedProximity(FSapAttachTarget Where, float Mass, float Distance)
    {
		if (Distance < Settings.ExplodingSapDeathRadius)
        	TakeDamage(Mass * (1.f - 0.8f * (Distance / Settings.ExplodingSapDeathRadius)));
    }

    UFUNCTION()
    void OnMatchImpact(AActor IgnitionSource, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
    {
		if (WeaponTrace::IsProjectileBlockingComponent(HitResult.Component))
			return;

        OnHitByMatch.Broadcast();

		if ((SapMass > 0.f) && (Settings.IgniteAttachedSapRadius > 0.f))
		{	
			USapResponseComponent SapComp = USapResponseComponent::Get(Owner);
			if (SapComp != nullptr)
				SapTriggerExplosionAtPoint(HitResult.Location, Settings.IgniteAttachedSapRadius);
		}
#if TEST
		AHazePlayerCharacter MatchWielder = Game::GetMay();
		if (MatchWielder != nullptr)
		{
			UWaspDebugSlayerComponent SlayerComp = UWaspDebugSlayerComponent::Get(MatchWielder);
			if ((SlayerComp != nullptr) && SlayerComp.bSlay)
				TakeDamage(1000.f);
		}
#endif
    }

	UFUNCTION()
	void TakeDamage(float Damage)
	{
		if (Damage <= 0.f)
			return;

		// Only take damage on match wielder control side
		AHazePlayerCharacter MatchWielder = Game::GetMay();
		if (!ensure(MatchWielder != nullptr) || !MatchWielder.HasControl())
			return;

		// Send damage over network through attacker crump component so it'll sync with their time line
		UHazeCrumbComponent MatchWielderCrumbComp = UHazeCrumbComponent::Get(MatchWielder);
		if (!ensure(MatchWielderCrumbComp != nullptr))
			return;		

		if (Time::GetGameTimeSeconds() < TakeDamageCooldownTime)
			return; // Can't be hurt again yet

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddValue(n"Damage", Damage);
		MatchWielderCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbTakeDamage"), CrumbParams);
	}

    UFUNCTION(NotBlueprintCallable)
	void CrumbTakeDamage(const FHazeDelegateCrumbData& CrumbParams)
	{
		bIsHurt = true;
		TakeDamageCooldownTime = Time::GetGameTimeSeconds() + Settings.TakeDamageCooldown;
		if (HitPoints > 0)
			HitPoints -= FMath::CeilToInt(CrumbParams.GetValue(n"Damage")); 
		OnTakeDamage.Broadcast(Cast<AHazeActor>(Owner), HitPoints);
		if (HitPoints <= 0)
		{
			Die();
		}
		else 
		{
			if (HealthBarWidgetClass.IsValid())
			{
				UpdateHealthBar(MayHealthBar);
				UpdateHealthBar(CodyHealthBar);
			}
			if (BossHealthBarWidgetClass.IsValid())
				UpdateHealthBar(BossHealthBar);
		}
	}

	UFUNCTION()
    void Die()
    {
		bIsDead = true;
		RemoveHealthBars();

		// If we're on match wielder remote side, it'll take a while before 
		// death capability kicks in, so let's do some visual stuff early
		if (!HasControl())
			OnRemotePreDeath.Broadcast();
    }

	bool IsSapped()
	{
		if (Settings.SapAmountToStun >= 100)
			return false;

		if (Time::GetGameTimeSeconds() < DelayedSappedTime)
			return false;

		return (SapMass >= Settings.SapAmountToStun);
	}

    UFUNCTION()
    void OnSapMassAdded(FSapAttachTarget Where, float Mass)
    {
        SapMass += Mass;

		// Sap custom attach will hide actual sap blob, this'll set custom blob material param 
		UpdateCustomSapBlob();

        OnHitBySap.Broadcast(); 
		if (DelayedSappedTime == 0.f)
			DelayedSappedTime = Time::GetGameTimeSeconds() + Settings.StunDelay;
    }

    UFUNCTION()
    void OnSapMassRemoved(FSapAttachTarget Where, float Mass)
    {
    	SapMass -= Mass;
	 	UpdateCustomSapBlob();

		DelayedSappedTime = 0.f;
    }

	void UpdateCustomSapBlob()
	{
		if (Sap::Batch::MaxMass == 0)
			return;

	 	CharOwner.Mesh.SetScalarParameterValueOnMaterialIndex(CustomSapMaterialIndex, n"SapFraction", SapMass / Sap::Batch::MaxMass);
		if (ArmourComp != nullptr)
			ArmourComp.SetScalarParameterValueOnMaterialIndex(CustomSapMaterialIndex, n"SapFraction", SapMass / Sap::Batch::MaxMass);			
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		SetupHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		RemoveHealthBars();
		USapResponseComponent SapComp = USapResponseComponent::Get(Owner);
		if (SapComp != nullptr)
			DisableAllSapsAttachedTo(Owner.RootComponent);
		return false;
	}

	void SetupHealthBars()
	{
		if (HealthBarWidgetClass.IsValid() || BossHealthBarWidgetClass.IsValid())
		{
			RemoveHealthBars();
			if (Settings.HitPoints > 1)
			{
				if (HealthBarWidgetClass.IsValid())
				{
					MayHealthBar = AddHealthBarWidget(Game::GetMay());
					CodyHealthBar = AddHealthBarWidget(Game::GetCody());
				}
				if (BossHealthBarWidgetClass.IsValid())
				{
					BossHealthBar = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(BossHealthBarWidgetClass));
					BossHealthBar.InitBossHealthBar(BossHealthBarDesc, Settings.HitPoints);
				}
#if EDITOR
				System::SetTimer(this, n"UpdateHealthBarSettings", 1.f, true);
#endif
			}
		}
	}

	UHealthBarWidget AddHealthBarWidget(AHazePlayerCharacter Player)
	{
		if (!HealthBarWidgetClass.IsValid())
			return nullptr;

		UHealthBarWidget HealthBar = Cast<UHealthBarWidget>(Player.AddWidget(HealthBarWidgetClass));
		HealthBar.InitHealthBar(Settings.HitPoints);
		UpdateSingleHealthBarSettings(HealthBar);
		return HealthBar;
	}

	void UpdateHealthBar(UHealthBarWidget HealthBar)
	{
		HealthBar.SetHealthAsDamage(HitPoints);
	}

	void RemoveHealthBars()
	{
		if (MayHealthBar != nullptr)
		{
			Game::GetMay().RemoveWidget(MayHealthBar);
			MayHealthBar = nullptr;
		}
		if (CodyHealthBar != nullptr)
		{
			Game::GetCody().RemoveWidget(CodyHealthBar);
			CodyHealthBar = nullptr;
		}
		if (BossHealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(BossHealthBar);
			BossHealthBar = nullptr;	
		}
#if EDITOR
		System::ClearTimer(this, "UpdateHealthBarSettings");
#endif
	}

	UFUNCTION()
	void UpdateHealthBarSettings()
	{
		if (!HealthBarWidgetClass.IsValid())
			return;
		UpdateSingleHealthBarSettings(MayHealthBar);
		UpdateSingleHealthBarSettings(CodyHealthBar);
		if (BossHealthBar != nullptr)
			BossHealthBar.SetHealthAsDamage(HitPoints);
	}
	void UpdateSingleHealthBarSettings(UHealthBarWidget HealthBar)
	{	
		if (HealthBar == nullptr)
			return;

		USceneComponent AttachComp = USceneComponent::Get(Owner, Settings.HealthBarAttachComponent);
		if (AttachComp == nullptr)
			AttachComp = Owner.RootComponent;

		HealthBar.AttachWidgetToComponent(AttachComp, Settings.HealthBarAttachSocket);
		HealthBar.SetWidgetRelativeAttachOffset(Settings.HealthBarOffset);
		HealthBar.SetHealthAsDamage(HitPoints);
	}

	float GetHealthFraction()
	{
		return (HitPoints * 1.f) / (Settings.HitPoints * 1.f);
	}

	void SetSappable(bool bSappable, UObject Instigator)
	{
		// We're only sappable if everyone agrees we should be
		if (bSappable)
		{
			if (UnsappableInstigators.Num() > 0)
			{
				UnsappableInstigators.Remove(Instigator);
				if (UnsappableInstigators.Num() == 0)
				{
					for (UActorComponent Sappable : Sappables)
					{
						Sappable.AddTag(n"SapStickable");
					}
				}
			}
		}
		else
		{
			if (UnsappableInstigators.Num() == 0)
			{
				for (UActorComponent Sappable : Sappables)
				{
					Sappable.RemoveTag(n"SapStickable");
				}
			}
			UnsappableInstigators.AddUnique(Instigator);
		}
	}
}