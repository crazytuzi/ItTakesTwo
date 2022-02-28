import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineFlakProjectile;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineOrientation;
import Cake.LevelSpecific.Tree.GliderSquirrel.EscapeSquirrelProjectile;
import Peanuts.Aiming.AutoAimTarget;
import Peanuts.Health.HealthBarWidget;
import Vino.AI.GUI.EnemyIndicatorWidget;

event void FOnSquirrelTakeDamage();

float RandValue() 
{
	return FMath::RandRange(0.f, 1.f);
}

UFUNCTION(Category = "Escape")
void EscapeDestroyAllSquirrels()
{
	TArray<AActor> Squirrels;
	GetAllActorsOfClass(AGliderSquirrel::StaticClass(), Squirrels);

	for(auto Squirrel : Squirrels)
		Squirrel.DestroyActor();
}

class AGliderSquirrel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UBoxComponent CollisionBox;

	UPROPERTY()
	AFlyingMachine Target;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftMuzzle;

	UPROPERTY(DefaultComponent)
	USceneComponent RightMuzzle;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTarget;

	UPROPERTY(DefaultComponent)
	UFlyingMachineFlakHittableComponent FlakHittable;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY()
	TSubclassOf<AEscapeSquirrelProjectile> ProjectileClass;

	UPROPERTY()
	TSubclassOf<UHealthBarWidget> WidgetClass;

	UPROPERTY()
	TSubclassOf<UEnemyIndicatorWidget> IndicatorWidgetClass;
	TPerPlayer<UEnemyIndicatorWidget> IndicatorWidget;

	FOnSquirrelTakeDamage OnTakeDamage;

	int MaxHealth = 7;
	int Health = MaxHealth;
	FFlyingMachineOrientation Orientation;

	FVector CurrentVelocity;

	bool bShouldHoldFire = false;

	float ShootFrequencyScale = 1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlakHittable.OnHit.AddUFunction(this, n"HandleHit");
		ShootFrequencyScale = FMath::RandRange(0.5f, 1.f);

		ShowIndicatorWidget();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		HideIndicatorWidget();
	}

	UFUNCTION()
	void AddCapabilities()
	{
		AddCapability(n"GliderSquirrelFollowCapability");
		AddCapability(n"GliderSquirrelShootCapability");
		AddCapability(n"GliderSquirrelNoseDiveCapability");
		AddCapability(n"GliderSquirrelWidgetCapability");
	}

	UFUNCTION(BlueprintPure)
	bool IsDead()
	{
		return Health <= 0;
	}

	USceneComponent GetMuzzle(bool bRight)
	{
		return bRight ? RightMuzzle : LeftMuzzle;
	}

	UFUNCTION()
	void HandleHit(AFlyingMachineFlakProjectile Projectile, UPrimitiveComponent HitComponent)
	{
		if (IsDead())
			return;

		Health--;
		OnTakeDamage.Broadcast();

		if (IsDead())
		{
			HideIndicatorWidget();
			AutoAimTarget.bIsAutoAimEnabled = false;
			BP_OnBeginNoseDive();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Game::Cody.IsPlayerDead())
			DestroyActor();
	}

	// Called when the squirrels health is reduced to zero, and it begins to nose dive
	UFUNCTION(BlueprintEvent)
	void BP_OnBeginNoseDive()
	{
	}

	// Called when hitting something during a nose-dive
	UFUNCTION(BlueprintEvent)
	void BP_OnDeath()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFire(bool bRightMuzzle)
	{
	}

	UFUNCTION()
	void SetHoldFire(bool bHoldFire)
	{
		bShouldHoldFire = bHoldFire;
		if (bShouldHoldFire)
			HideIndicatorWidget();
		else
			ShowIndicatorWidget();
	}

	void PulseIndicatorWidget()
	{
		ShowIndicatorWidget();
		for(auto Player : Game::Players)
			IndicatorWidget[Player].Highlight(1.f);
	}

	void ShowIndicatorWidget()
	{
		if (IndicatorWidget[0] != nullptr)
			return;

		for(auto Player : Game::Players)
		{
			auto Widget = Cast<UEnemyIndicatorWidget>(Player.AddWidget(IndicatorWidgetClass));
			Widget.AttachWidgetToComponent(Mesh);
			Widget.SetScreenspaceOffset(FVector2D(0.f, -50.f));
			IndicatorWidget[Player] = Widget;
		}
	}

	void HideIndicatorWidget()
	{
		if (IndicatorWidget[0] == nullptr)
			return;

		for(auto Player : Game::Players)
		{
			Player.RemoveWidget(IndicatorWidget[Player]);
			IndicatorWidget[Player] = nullptr;
		}
	}
}