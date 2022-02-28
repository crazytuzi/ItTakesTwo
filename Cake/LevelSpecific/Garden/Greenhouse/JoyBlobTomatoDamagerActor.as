import Cake.LevelSpecific.Garden.Greenhouse.Joy;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetComponent;

event void FOnBlobTomatoDamageActorDestroyed();
event void FOnBlobTomatoDamageActorActivated();
event void FOnBlobTomatoDamageActorDeactivated();

class AJoyBlobTomatoDamageActor : AHazeCharacter
{
	//UPROPERTY(DefaultComponent, Attach = RootComp)
	//UJoyBlobSickleCuttableComponent SickleHealthComponent;
	
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UTomatoDashTargetComponent TomatoComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY()
	FOnBlobTomatoDamageActorDestroyed OnBlobDestroyed;
	UPROPERTY()
	FOnBlobTomatoDamageActorActivated OnBlobTomatoDamageActorActivated;
	UPROPERTY()
	FOnBlobTomatoDamageActorDeactivated OnBlobTomatoDamageActorDeactivated;
	UPROPERTY()
	UNiagaraSystem HitReactionEffect;
	UPROPERTY()
	UNiagaraSystem ExitEffect;

	int HitsRequired = 3;
	int TimesHit;
	bool DoOnce = false;
	FVector StartLocationOfTomatoComponent;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TomatoComponent.OnHitByTomato.AddUFunction(this, n"OnHitByTomatoDash");
		StartLocationOfTomatoComponent = TomatoComponent.GetWorldLocation();
		TomatoComponent.SetWorldLocation(FVector(0, 0, -30000));
		//SickleHealthComponent.bOwnerForcesDeactivation = true;
		//SickleHealthComponent.bInvulnerable = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds){}


	UFUNCTION()
	void OnHitByTomatoDash()
	{
		if(Game::GetCody().HasControl())
		{
			NetOnHitByTomatoDash();
		}
	}
	UFUNCTION(NetFunction)
	void NetOnHitByTomatoDash()
	{
		TimesHit += 1;

		if(TimesHit >= 3)
		{
			OnThisPlantDestroyed();
		}
		else
		{
			Niagara::SpawnSystemAtLocation(HitReactionEffect, GetActorLocation(), GetActorRotation(), bAutoDestroy=true);
			SetAnimBoolParam(n"TookDamage", true);
		}
	}
	UFUNCTION()
	void OnThisPlantDestroyed()
	{
		if(DoOnce == false)
		{
			DoOnce = true;
			//Hack to make component not targaetable by tomato
			TomatoComponent.SetWorldLocation(FVector(0,0,0));
			Niagara::SpawnSystemAtLocation(ExitEffect, GetActorLocation());
			OnBlobTomatoDamageActorDeactivated.Broadcast();
			OnBlobDestroyed.Broadcast();	
			DisableActor(nullptr);
		}
	}

	
	UFUNCTION()
	void ManualDisable()
	{
		if(this.HasControl())
		{
			NetManualDisable();
		}
	}
	UFUNCTION(NetFunction)
	void NetManualDisable()
	{
		//Hack to make component not targaetable by tomato
		TomatoComponent.SetWorldLocation(FVector(0,0,0));
		OnBlobTomatoDamageActorDeactivated.Broadcast();
	}


	UFUNCTION()
	void RestoreBlob()
	{
		if(this.HasControl())
		{
			NetRestoreBlob();
		}
	}
	UFUNCTION(NetFunction)
	void NetRestoreBlob()
	{
		DoOnce = false;
		EnableActor(nullptr);
	}


	UFUNCTION()
	void ActivateBlob()
	{
		if(this.HasControl())
		{
			NetActivateBlob();
		}
	}
	UFUNCTION(NetFunction)
	void NetActivateBlob()
	{
		DoOnce = false;
		TimesHit = 0;
		//SickleHealthComponent.bOwnerForcesDeactivation = false;
		TomatoComponent.SetWorldLocation(StartLocationOfTomatoComponent);
		OnBlobTomatoDamageActorActivated.Broadcast();
	}


	UFUNCTION()
	void ManuallyDestroy()
	{
		if(this.HasControl())
		{
			NetManuallyDestroy();
		}
	}
	UFUNCTION(NetFunction)
	void NetManuallyDestroy()
	{
		DestroyActor();
	}
}