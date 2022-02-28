import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Greenhouse.BossRoomSubmersibleSoil;

event void FOnBulbExploded();

class ABossRoomRootBulb : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent, Attach = SphereCollision)
	USickleCuttableHealthComponent SickleCuttableComp;
	default SickleCuttableComp.MaxHealth = 30.0f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightBarrierRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftBarrierRoot;

	UPROPERTY()
	ABossRoomSubmersibleSoil ConnectedSubmersibleSoil;

	UPROPERTY()
	int SectionNumber = 2;	

	UPROPERTY()
	FOnBulbExploded OnBulbExploded;

	UPROPERTY()
	UNiagaraSystem NiagaraFX;

	bool bCodyInSoil = false;

	float RightBarrierCurrentValue = 0.0f;
	float LeftBarrierCurrentValue = 0.0f;

	float OpeningBarrierSpeed = 1.0f;
	float SlowerClosingBarrierSpeed = 1.0f;
	float ClosingBarrierSpeed = 5.0f;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat BarrierOpeningCurve;
	
	UPROPERTY(EditDefaultsOnly)
	UCurveFloat BarrierClosingCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"OnCutWithSickle");
		ConnectedSubmersibleSoil.OnPlayerSubmergedInBossSoil.AddUFunction(this, n"PlayerEnteredSoil");
		SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		AddCapability(n"BossRoomRootBulbBarrierCapability");
	}

	UFUNCTION()
	void PlayerEnteredSoil(AHazePlayerCharacter  Player)
	{
		bCodyInSoil = true;
	}
	
	UFUNCTION()
	void OnCutWithSickle(int DamageAmount)
	{
		if(SickleCuttableComp.Health <= 0)
		{
			Explode();
		}
	}

	UFUNCTION()
	void Explode()
	{
		Niagara::SpawnSystemAtLocation(NiagaraFX, GetActorLocation());
		OnBulbExploded.Broadcast();
		if(ConnectedSubmersibleSoil != nullptr)
		{
			if(ConnectedSubmersibleSoil.PlayerInSoil != nullptr)
			{
				AHazePlayerCharacter Player = ConnectedSubmersibleSoil.PlayerInSoil;
				Player.TeleportActor(ActorLocation, ActorRotation);
				ConnectedSubmersibleSoil.LeaveBossSoil();
			}
		}

		DestroyActor();
	}
}
