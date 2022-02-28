import Cake.LevelSpecific.Tree.Wasps.WaspCommon;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspMovementComponent;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspSpinningWeaponComponent;

event void FWaspHomingProjectileReturn();

// To be able to launch a homing projectile, you'll need this class to control what projectile to spawn. 
// This should be attached to where homing projectile should attach.
class UWaspHomingProjectileLauncherComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<AWaspHomingProjectile> ProjectileClass;
}

// Common data for homing projectile, used by capabilities.
class UWaspHomingProjectileComponent : UActorComponent
{
	AHazeActor Wielder = nullptr;
	UWaspHomingProjectileLauncherComponent Launcher = nullptr;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeathExploEvent;

	// Triggers when projectile returns after being launched or if launch is aborted
	UPROPERTY(Category = "Wasp Events")
	FWaspHomingProjectileReturn OnReturn;

	bool bLaunched = false;

	void Launched()
	{
		bLaunched = true;
	}

	void Returned()
	{
		bLaunched = false;
		OnReturn.Broadcast();
	}
}


// We're using a pared down wasp to make this as cheap as possible to build
UCLASS(Abstract, hideCategories="StartingAnimation Animation Mesh Materials Physics Collision Activation Lighting Shape Navigation Character Clothing Replication Rendering Cooking Input Actor LOD AssetUserData")
class AWaspHomingProjectile : AHazeCharacter
{
	// Start hidden, we get shown when in action
	default bHidden = true;
	default ActorEnableCollision = false;

	UPROPERTY(DefaultComponent)
	UWaspHomingProjectileComponent HomingComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent) 
	UWaspMovementComponent MovementComponent;
	default MovementComponent.DefaultMovementSettings = AIWaspDefaultMovementSettings;
   	default CapsuleComponent.SetCollisionProfileName(n"WaspNPC");

    UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
    UWaspBehaviourComponent BehaviourComponent;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspAnimationComponent AnimComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspHealthComponent HealthComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspEffectsComponent EffectsComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

    // Triggers when we die
	UPROPERTY(Category = "Wasp Events")
	FWaspOnDie OnDie;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(CapsuleComponent);

		AddCapability(n"WaspUpdateBehaviourStateCapability");
		AddCapability(n"WaspFlyingRotationCapability");
		AddCapability(n"WaspFlyingMovementCapability");
		AddCapability(n"WaspDeathCapability");
		AddCapability(n"WaspTakeDamageCapability");
		AddCapability(n"WaspAttackRunCapability");
		AddCapability(n"WaspEnemyIndicatorCapability");
		AddCapability(n"WaspWeaponSpinnerCapability");

        AddCapability(n"WaspHomingProjectileIdleCapability");
        AddCapability(n"WaspHomingProjectilePreLaunchCapability");
        AddCapability(n"WaspHomingProjectileAttackCapability");
        AddCapability(n"WaspHomingProjectileReturnCapability");

		HealthComp.OnDie.AddUFunction(this, n"OnDied");
    }

	UFUNCTION()
	void SetWielder(AHazeActor Wielder)
	{
		if (!ensure(Wielder != nullptr))
			return;

		AddTickPrerequisiteActor(Wielder);
		HomingComp.Wielder = Wielder;
		HomingComp.Launcher = UWaspHomingProjectileLauncherComponent::Get(Wielder);
		if (!ensure(HomingComp.Launcher != nullptr))
			return;	

		UWaspRespawnerComponent WielderRespawnComp = UWaspRespawnerComponent::Get(Wielder);
		if (WielderRespawnComp != nullptr)
		{
			WielderRespawnComp.OnReset.AddUFunction(BehaviourComponent, n"Reset");
			WielderRespawnComp.OnReset.AddUFunction(AnimComp, n"Reset");
			WielderRespawnComp.OnReset.AddUFunction(HealthComp, n"Reset");
			WielderRespawnComp.OnReset.AddUFunction(this, n"Reset");
		}

		UWaspHealthComponent WielderHealthComp = UWaspHealthComponent::Get(Wielder);
		if (WielderHealthComp != nullptr)
		{
			WielderHealthComp.OnDie.AddUFunction(this, n"OnWielderDeath");
		}
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		CrumbComponent.SetCrumbDebugActive(this, false);
    }

	UFUNCTION(NotBlueprintCallable)
	private void OnDied(AHazeActor Wasp)
	{
		OnDie.Broadcast(this);
		if (ensure(HomingComp.Launcher != nullptr))
		{
			UHazeAkComponent::HazePostEventFireForget(HomingComp.DeathExploEvent, GetActorTransform());
			HazeAkComp.HazePostEvent(HomingComp.StopFlyingEvent);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnWielderDeath(AHazeActor Wasp)
	{
		// Kill projectile as well
		HealthComp.TakeDamage(HealthComp.HitPoints + 1);
	}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		SetActorHiddenInGame(true);	
		SetActorEnableCollision(false);

		// Show wielder weapon (for now)
		UWaspWeaponSpinningComponent LaunchedWeapon = UWaspWeaponSpinningComponent::Get(UWaspHomingProjectileComponent::Get(Owner).Wielder);
		LaunchedWeapon.SetHiddenInGame(false);	
	}

	void Launch(AHazeActor Target)
	{
		BehaviourComponent.Target = Target;
	}
};

