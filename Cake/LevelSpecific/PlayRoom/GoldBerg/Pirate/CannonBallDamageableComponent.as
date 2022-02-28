import Peanuts.DamageFlash.DamageFlashStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateShipPlayerHealthBarsComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.GoldbergVOBank;

event void FOnPirateDamageableCannonBallHit(FHitResult Hit);
event void FOnPirateDamageableExploded();
event void FOnPirateDamageableDestroyed();
event void FOnPirateDamageableHealthRestored();
event void FOnBreakPirateBlockers(FVector HitLocation, FVector HitDirection);

class UCannonBallDamageableComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	float MaximumHealth;

	UPROPERTY(NotEditable)
	float CurrentHealth;

	UPROPERTY()
	FOnPirateDamageableCannonBallHit OnCannonBallHit;
	UPROPERTY()
	FOnPirateDamageableExploded OnExploded;
	UPROPERTY()
	FOnPirateDamageableDestroyed OnDestroyed;
	UPROPERTY()
	FOnPirateDamageableHealthRestored OnHealthRestored;
	UPROPERTY()
	FOnBreakPirateBlockers OnBreakPirateBlockers;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionEffect;

	TArray<UCannonBallDamageableComponent> AttachedDamageableComps;

	UPROPERTY(EditDefaultsOnly)
	bool bDestroyAfterExploding = true;

	UPROPERTY(EditDefaultsOnly)
	bool bDisableIfNotDestroyed = true;

	UPROPERTY(EditDefaultsOnly)
	float DelayBeforeDestroyed = 0.0f;

	UPROPERTY(EditDefaultsOnly)
	bool bDelayExplosionEffect = false;	

	UPROPERTY(EditDefaultsOnly)
	FVector ExplosionOffset = FVector::ZeroVector;

	UPROPERTY()
	bool bIsBombBridge = false;
	UPROPERTY()
	bool bIsBombBox = false;

	UPROPERTY(EditDefaultsOnly)
	float DamageFlashDuration = 0.12f;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor DamageFlashColor = FLinearColor(0.5f, 0.5f, 0.5f, 0.15f);

	// The visual point
	USceneComponent HealthWidgetAttachComponent;

	UPROPERTY(Category = "Widget", EditDefaultsOnly)
	FVector WidgetPositionOffset = FVector(0.f, 0.f, 310.f);

	UPROPERTY(Category = "Widget", EditDefaultsOnly)
	TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

	private bool bExploding = false;
	//set back to private
	private bool bCanTakeDamage = true;

	AHazePlayerCharacter PlayerGivingDamage = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UGoldbergVOBank VOBank;
	default VOBank = Asset("/Game/Blueprints/LevelSpecific/PlayRoom/VOBanks/GoldbergVOBank.GoldbergVOBank");

	UPROPERTY(Category = "Audio")
	bool bPlayDefeatedBark = true;

	float HealthBarDisappearDelay = 0.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentHealth = MaximumHealth;
	}

	bool GetIsExploding()
	{
		return bExploding;
	}

	UFUNCTION()
	void ResetAfterExploding()
	{
		bExploding = false;
		bCanTakeDamage = true;
		RestoreHealth();
	}

	UFUNCTION()
	void SetAttachedDamagableComps(TArray<UCannonBallDamageableComponent> AttachedActorsWithDamageableComps)
	{
		if(HasControl())
		{
			NetSetAttachedDamagableComps(AttachedActorsWithDamageableComps);		
		}
	}

	UFUNCTION(NetFunction)
	void NetSetAttachedDamagableComps(TArray<UCannonBallDamageableComponent> AttachedActorsWithDamageableComps)
	{
		AttachedDamageableComps = AttachedActorsWithDamageableComps;
	}

	void CallOnCannonBallHit(FHitResult Hit, float Damage = 1.f, FVector Velocity = FVector(0.f), AHazePlayerCharacter CannonBallPlayerOwner = nullptr)
	{
		if(HasControl())
		{
			NetCallOnCannonBallHit(Hit, Damage, Velocity, CannonBallPlayerOwner);
		}
	}

	UFUNCTION(NetFunction)
	void NetCallOnCannonBallHit(FHitResult Hit, float Damage, FVector Velocity, AHazePlayerCharacter CannonBallPlayerOwner)
	{
		PlayerGivingDamage = CannonBallPlayerOwner;
		OnCannonBallHit.Broadcast(Hit);
		TakeDamage(Damage, Hit.ImpactPoint, Velocity);
	}

	private void TakeDamage(float DamageAmount, FVector HitLocation = FVector(0.f), FVector Velocity = FVector(0.f))
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);

        FlashActor(HazeOwner, DamageFlashDuration, DamageFlashColor);
		
		CurrentHealth -= DamageAmount;
		
		if(CurrentHealth <= 0)
		{
			if(bIsBombBridge)
			{
				if(HasControl())
				{
					if(AttachedDamageableComps.Num() > 0 && AttachedDamageableComps[0] != nullptr)
					{
						AttachedDamageableComps[0].NetExplode(false);
					}
					else
					{
						Print("bomb bridge has no bomb attached?");
					}
				}

			}
			else
			{
				Explode(HitLocation, Velocity);
			}
		}
	}

	bool CanTakeDamage()const
	{
		if(bExploding)
			return false;
		if(!bCanTakeDamage)
			return false;
		return true;
	}

	void DisableDamageTaking()
	{
		bCanTakeDamage = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableDamageTaking()
	{
		bCanTakeDamage = true;
	}

	UFUNCTION(NetFunction)
	void NetExplode(bool bNullDelay)
	{
		if(bNullDelay)
			DelayBeforeDestroyed = 0.0f;

		Explode();
	}

	UFUNCTION()
	void Explode(FVector HitLocation = FVector(0.f), FVector Velocity = FVector(0.f))
	{
		if(bExploding)
			return;

		bExploding = true;
		
		OnExploded.Broadcast();

		if(PlayerGivingDamage != nullptr && bPlayDefeatedBark)
		{
			FName EventName = PlayerGivingDamage.IsMay() ? n"FoghornDBPlayRoomGoldbergEnemyDefeatedGenericMay" : n"FoghornDBPlayRoomGoldbergEnemyDefeatedGenericCody";

			PlayFoghornVOBankEvent(VOBank, EventName);
		}
		
		OnBreakPirateBlockers.Broadcast(HitLocation, Velocity);
		
		if(ExplosionEffect != nullptr && !bDelayExplosionEffect)
		{
			auto NiagaraComponent = Niagara::SpawnSystemAtLocation(ExplosionEffect, Owner.ActorLocation + ExplosionOffset);
			NiagaraComponent.SetTranslucentSortPriority(3);
		}
			
		if(DelayBeforeDestroyed > 0.0f)
		{ 
			System::SetTimer(this, n"DelayedDestroy", DelayBeforeDestroyed, false);
		}
		else if(bDestroyAfterExploding)
		{
			OnDestroyed.Broadcast();
			ExplodeAttachActors();
			Owner.DestroyActor();

			AHazeActor HazeOwner;

			HazeOwner = Cast<AHazeActor>(Owner);

			if (HazeOwner != nullptr) 
			{
				if (!HazeOwner.IsActorDisabled())
					HazeOwner.DisableActor(this);	
			}
		}
		else if(!bDestroyAfterExploding)
		{
			ExplodeAttachActors();
			DelayedDestroy();
		}
	}

	UFUNCTION()
	void RestoreHealth()
	{
		CurrentHealth = MaximumHealth;
		OnHealthRestored.Broadcast();
	}

	void ExplodeAttachActors()
	{
		if(AttachedDamageableComps.Num() > 0)
		{
			for (int i = 0; i < AttachedDamageableComps.Num(); i++)
			{
				if(AttachedDamageableComps[i] != nullptr && AttachedDamageableComps[i].Owner != nullptr)
				{
					bool bNullDelay = false;
					if(bIsBombBox && AttachedDamageableComps[i].bIsBombBox)
						bNullDelay = true;
					
					AttachedDamageableComps[i].NetExplode(bNullDelay);
				}
			}
			AttachedDamageableComps.Reset();
		}
	}

	UFUNCTION()
	void DelayedDestroy()
	{
		if(ExplosionEffect != nullptr && bDelayExplosionEffect)
			Niagara::SpawnSystemAtLocation(ExplosionEffect, Owner.ActorLocation + ExplosionOffset);

		OnDestroyed.Broadcast();

		if(HasControl())
			ExplodeAttachActors();
		
		if(bDestroyAfterExploding)
			Owner.DestroyActor();	

		HazeDisable();
	}

	UFUNCTION()
	void DestroyOwningActor()
	{
		OnDestroyed.Broadcast();

		HazeDisable();

		Owner.DestroyActor();	
	}

	UFUNCTION(NetFunction)
	void NetDeactivateAndDestroyActor()
	{	
		DeactivateAndDestroyActor();
	}

	UFUNCTION()
	void DeactivateAndDestroyActor()
	{
		bExploding = true;
		
		if(HasControl())
		{
			if(AttachedDamageableComps.Num() > 0)
			{
				for (int i = 0; i < AttachedDamageableComps.Num(); i++)
				{
					if(AttachedDamageableComps[i] != nullptr && AttachedDamageableComps[i].Owner != nullptr)
						if(!AttachedDamageableComps[i].bExploding)
							AttachedDamageableComps[i].DeactivateAndDestroyActor();
				}
				AttachedDamageableComps.Reset();
			}
		}
	

		Owner.DestroyActor();
		HazeDisable();
	}

	UFUNCTION()
	void HazeDisable()
	{
		if(!bDisableIfNotDestroyed)
			return;
			
		AHazeActor HazeOwner;

		HazeOwner = Cast<AHazeActor>(Owner);

		if (HazeOwner != nullptr) 
		{
			if (!HazeOwner.IsActorDisabled())
				HazeOwner.DisableActor(this);	
		}
	}
}