import Cake.LevelSpecific.Tree.Beetle.Settings.BeetleSettings;
import Peanuts.Aiming.AutoAimTarget;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Sap.SapManager;
import Peanuts.Health.BossHealthBarWidget;

event void FBeetleTakeDamage(float RemainingHealth, AHazePlayerCharacter Attacker, float BatchDamage, const FVector& DamageDir);

class UBeetleHealthComponent : UActorComponent
{
	float RemainingHealth = 10;
	bool bSappable = false;
	float LastAttackedTime = 0.f;
	AHazeActor LastAttacker;

	// We'll only take the highest of any damage during a set period of time
	float BatchDamageTime = 0.f;
	float BatchDamage = 0.f;

	bool bBlockingGameOver = false;

	UBeetleSettings Settings = nullptr;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBeetleTakeDamage OnTakeDamage;

	UPROPERTY()
	USapResponseComponent SapResponseComp;

	UPROPERTY()
	USceneComponent SapTargetComp;

	UPROPERTY()
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(Category = "GUI")
	TSubclassOf<UBossHealthBarWidget> HealthBarWidgetClass;
	UBossHealthBarWidget HealthBar;

	UCapsuleComponent Capsule;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UBeetleSettings::GetSettings(Cast<AHazeActor>(Owner));
		RemainingHealth = Settings.HitPoints;
		Capsule = UCapsuleComponent::Get(Owner);
	}

	float GetHealthFraction()
	{
		if (Settings.HitPoints == 0.f)
			return 0.f;
		return RemainingHealth / Settings.HitPoints;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBars();
		UnblockGameOverInternal();
	}

	UFUNCTION()
	void ReadyForFight()
	{
		SetupHealthBars();
	}

	void SetSappable()
	{
		// Beetle is never sappable for now
		// bSappable = true;
		// if (SapTargetComp != nullptr)
		// 	SapTargetComp.AddTag(n"SapStickable");
		// if (AutoAimTargetComp != nullptr)
		// 	AutoAimTargetComp.bIsAutoAimEnabled = true;
	}

	void SetUnsappable()
	{
		bSappable = false;
		if (SapTargetComp != nullptr)
			SapTargetComp.RemoveTag(n"SapStickable");
		if (AutoAimTargetComp != nullptr)
			AutoAimTargetComp.bIsAutoAimEnabled = false;
	}

    UFUNCTION(NotBlueprintCallable)
    void OnMatchImpact(AActor IgnitionSource, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
    {
		OnAttacked(Game::GetMay());
    }

    UFUNCTION(NotBlueprintCallable)
    void OnMatchBounce(AActor IgnitionSource, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
    {
		OnAttacked(Game::GetMay());
    }

    UFUNCTION(NotBlueprintCallable)
	void OnSapMassAdded(FSapAttachTarget Where, float Mass)
	{
		OnAttacked(Game::GetCody());
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSapMassRemoved(FSapAttachTarget Where, float Mass)
	{
	}

    UFUNCTION(NotBlueprintCallable)
    void OnSapBounce(FSapAttachTarget Where, float Mass)
    {
		OnAttacked(Game::GetCody());
    }

	void OnAttacked(AHazeActor Attacker)
	{
		LastAttackedTime = Time::GetGameTimeSeconds();
		LastAttacker = Attacker;
	}

    UFUNCTION(NotBlueprintCallable)
    void OnSapExplosionProximity(FSapAttachTarget Where, float Mass, float Distance)
    {
		AHazePlayerCharacter MatchWielder = Game::GetMay();
		OnAttacked(MatchWielder);

		if (Where.Actor == Owner)
			return; //Handled by OnSapAttachedExplosion

		// Project explosion to capsule center line
		FVector CapDir = Capsule.WorldRotation.Vector();
		float HalfHeight = Capsule.ScaledCapsuleHalfHeight;
		FVector ClosestLoc = Capsule.WorldLocation;
		float Fraction = 0.f;
		Math::ProjectPointOnLineSegment(Capsule.WorldLocation - CapDir * HalfHeight, Capsule.WorldLocation + CapDir * HalfHeight, Where.WorldLocation, ClosestLoc, Fraction);

		// Check if explosion was below and close enough
		float HeightDelta = ClosestLoc.Z - Where.WorldLocation.Z;
		if (HeightDelta < 0.f)
			return;
		if (HeightDelta - Capsule.ScaledCapsuleRadius > Settings.GroundExplosionMaxHeight)
			return;
		
		// Check if explosion was close enough horizontally
		ClosestLoc.Z = Where.WorldLocation.Z;
		if (!Where.WorldLocation.IsNear(ClosestLoc, Settings.GroundExplosionRadius + Capsule.ScaledCapsuleRadius))  
			return;

		FVector FromDamage = (Owner.ActorLocation + FVector(0.f, 0.f, 100.f) - Where.WorldLocation);
		TakeDamage(MatchWielder, Mass, FromDamage.GetSafeNormal());		
	}

    UFUNCTION(NotBlueprintCallable)
    void OnSapAttachedExplosion(FSapAttachTarget Where, float Mass)
    {
		AHazePlayerCharacter MatchWielder = Game::GetMay();
		OnAttacked(MatchWielder);
		TakeDamage(MatchWielder, Mass, -Owner.ActorForwardVector); // Always count as damage from the front
    }

	void TakeDamage(AHazeActor Attacker, float Damage, const FVector& DamageDir)
	{
		// Exploding sap is triggered by the player shooting matches, 
		// so their control side should always decide if we took damage
		if (!Attacker.HasControl())
			return;

		// Send damage over network through attacker crump component so it'll sync with their time line
		UHazeCrumbComponent AttackerCrumbComp = UHazeCrumbComponent::Get(Attacker);
		if (!ensure(AttackerCrumbComp != nullptr))
			return;

		// Completely ignore weak enough damage
		if (Damage < Settings.MinDamage)
			return;

		// In case both players have already died, we will ignore damage so we don't risk a restart/defeat conflict
		UPlayerRespawnComponent PlayerRespawnComp = UPlayerRespawnComponent::Get(Attacker);
		if ((PlayerRespawnComp != nullptr) && PlayerRespawnComp.bIsGameOver)
			return;

		// Ignore any damage less than current batch maximum so we won't get lots of damage 
		// from a "minefield" of small sap blobs, but only take damage from the largest blob.
		float FinalDamage = Damage;
		if (Time::GetGameTimeSince(BatchDamageTime) < Settings.DamageBatchDuration)
		{
			if (Damage < (BatchDamage + 0.9f))
				return;

			// New max damage in batch
			FinalDamage -= BatchDamage;
			BatchDamage = Damage;
		}
		else
		{
			// Note that we only need to keep track of this on match wielder side in network
			BatchDamageTime = Time::GetGameTimeSeconds();
			BatchDamage = Damage;
		}

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Attacker", Attacker);
		CrumbParams.AddValue(n"Damage", FinalDamage);
		CrumbParams.AddValue(n"BatchDamage", BatchDamage);
		CrumbParams.AddVector(n"DamageDir", DamageDir);
		AttackerCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbTakeDamage"), CrumbParams);
	}

    UFUNCTION(NotBlueprintCallable)
	void CrumbTakeDamage(const FHazeDelegateCrumbData& CrumbParams)
	{
		AHazePlayerCharacter Attacker = Cast<AHazePlayerCharacter>(CrumbParams.GetObject(n"Attacker"));
		float Damage = CrumbParams.GetValue(n"Damage");
		BatchDamage =  CrumbParams.GetValue(n"BatchDamage");
		FVector DamageDir = CrumbParams.GetVector(n"DamageDir");
        RemainingHealth -= Damage;
		bSappable = true;
		OnTakeDamage.Broadcast(RemainingHealth, Attacker, BatchDamage, DamageDir);

		// Make sure we don't have any remaining sap attached
		DisableAllSapsAttachedTo(Owner.RootComponent);

		if (RemainingHealth > 0)
		{
			HealthBar.SetHealthAsDamage(RemainingHealth);
		}
		else
		{
			// We're defeated!
			RemoveHealthBars();

			// Make sure players won't trigger game over 
			if (!bBlockingGameOver)
			{
				bBlockingGameOver = true;
				Game::May.BlockCapabilities(n"GameOver", this);
				Game::Cody.BlockCapabilities(n"GameOver", this);
				if (Game::May.HasControl())
					System::SetTimer(this, n"UnblockGameOver", 5.f, false);
			}
		}
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
		return false;
	}

	void SetupHealthBars()
	{
		if (HealthBarWidgetClass.IsValid())
		{
			RemoveHealthBars();
			if (Settings.HitPoints > 1)
			{
				FText BossName = NSLOCTEXT("GiantBeetle", "Name", "Giant Beetle");
				HealthBar = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarWidgetClass));
				HealthBar.InitBossHealthBar(BossName, Settings.HitPoints);
			}
		}
	}

	void RemoveHealthBars()
	{
		if (HealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(HealthBar);
			HealthBar = nullptr;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UnblockGameOver()
	{
		if (!bBlockingGameOver)
			return;

		// Unblock game over once at least one player is respawned
		if (!IsPlayerDead(Game::May) || !IsPlayerDead(Game::Cody))
			NetUnblockGameOver();	
		else
			System::SetTimer(this, n"UnblockGameOver", 2.f, false);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetUnblockGameOver()
	{
		UnblockGameOverInternal();
	}

	void UnblockGameOverInternal()
	{
		if (bBlockingGameOver)
		{
			bBlockingGameOver = false;
			Game::May.UnblockCapabilities(n"GameOver", this);
			Game::Cody.UnblockCapabilities(n"GameOver", this);
		}
	}
}
