import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobTrigger;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingTargetComponent;

import void AddAmmoContainer(AParentBlobAmmoContainerActor, AParentBlob) from "Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingComponent";
import void RemoveAmmoContainer(AParentBlobAmmoContainerActor, AParentBlob) from "Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingComponent";
import void TriggerImpactDelegate(AParentBlob, AHazePlayerCharacter, AParentBlobShootingProjectile, UParentBlobShootingTargetComponent) from "Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingComponent";
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;

delegate void FParentBlobAmmoContainerProjectileCreated(AParentBlobShootingProjectile Projectile);

class AParentBlobShootingProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(meta = (ClampMin = 0.1))
	float ChargeTime = 1.f;

	UFUNCTION(BlueprintEvent)
	void OnFullyCharged() {}

	void ChargeUp(float Amount)
	{
		if(ActiveChargeTime >= ChargeTime)
			return;

		ActiveChargeTime += Amount;
		if(ActiveChargeTime >= ChargeTime)
		{
			ActiveChargeTime = ChargeTime;
			OnFullyCharged();
		}
	}

	bool IsFullyCharged() const
	{
		return ActiveChargeTime >= ChargeTime - KINDA_SMALL_NUMBER;
	}

	float GetChargeAlpha() const
	{
		return ActiveChargeTime / ChargeTime;
	}

	private float ActiveChargeTime = 0;
	float TimeToTarget = -1;
	
	FVector CurrentVelocity;
}

struct FParentBlobAmmoContainerActiveProjectileData
{
	AParentBlobShootingProjectile Projectile;
	AParentBlob ShootingParentBlob;
	AHazePlayerCharacter ShootingPlayer;
	UParentBlobShootingTargetComponent Target;
}

class AParentBlobAmmoContainerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AmmoLerpFrom;

	UPROPERTY(DefaultComponent, Attach = AmmoLerpFrom)
	UParentBlobKineticInteractionComponent InteractionComponent;

	UPROPERTY(Category = "Projectile")
	bool bUseInfiniteAmmo = false;

	UPROPERTY(Category = "Projectile", meta = (ClampMin = 1, EditCondition = "!bUseInfiniteAmmo"))
	int AmmoCount = 3;

	UPROPERTY(Category = "Projectile")
	TSubclassOf<AParentBlobShootingProjectile> ProjectileClass;
	default ProjectileClass = AParentBlobShootingProjectile::StaticClass();

	UPROPERTY(Category = "Projectile")
	float ProjectileGravity = 980.f;

	UPROPERTY(Category = "Projectile")
	float ProjectileArcHeight = 1000.f;

	// The trigger that makes this container valid
	UPROPERTY(EditInstanceOnly, Category = "Activation")
	AParentBlobTrigger Trigger;

	private int UsedAmmo = 0;
	private TArray<FParentBlobAmmoContainerActiveProjectileData> ActiveProjectiles;
	private TArray<AParentBlobShootingProjectile> PendingProjectiles;
	private TArray<AParentBlobShootingProjectile> ReturningProjectiles;

	private FParentBlobAmmoContainerProjectileCreated MayCreatedProjetile;
	private FParentBlobAmmoContainerProjectileCreated CodyCreatedProjetile;

	private AParentBlob ActiveParentBlob;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{		
		if(Trigger != nullptr)
		{
			Trigger.OnActorEnter.AddUFunction(this, n"EnterTrigger");
			Trigger.OnActorLeave.AddUFunction(this, n"ExitTrigger");
			System::SetTimer(this, n"ValidateOverlaps", KINDA_SMALL_NUMBER, false);
		}
		else
		{
			// Validation
			devEnsure(Trigger != nullptr, "ParentBlobAmmoContainer " + GetName() + " is missing a activation trigger");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(int i = ActiveProjectiles.Num() - 1; i >= 0; --i)
		{
			auto Projectile = ActiveProjectiles[i].Projectile;
			Projectile.AddActorWorldOffset(Projectile.CurrentVelocity * DeltaSeconds);
			Projectile.CurrentVelocity.Z -= ProjectileGravity * DeltaSeconds;
			Projectile.TimeToTarget -= DeltaSeconds;
			
			// We have reaced the target
			if(Projectile.TimeToTarget <= 0)
			{
				TriggerImpactDelegate(
					ActiveProjectiles[i].ShootingParentBlob, 
					ActiveProjectiles[i].ShootingPlayer,
					ActiveProjectiles[i].Projectile,
					ActiveProjectiles[i].Target);

				Projectile.DestroyActor();
				ActiveProjectiles.RemoveAtSwap(i);
			}
		}

		for(int i = ReturningProjectiles.Num() - 1; i >= 0; --i)
		{
			const FVector TargetLocation = AmmoLerpFrom.GetWorldLocation();
			FVector NewLocation = ReturningProjectiles[i].GetActorLocation();

			NewLocation = FMath::VInterpTo(NewLocation, TargetLocation, DeltaSeconds, 10.f);
			if(NewLocation.DistSquared(TargetLocation) < FMath::Square(10))
			{
				ReturningProjectiles[i].DestroyActor();
				ReturningProjectiles.RemoveAtSwap(i);
			}
			else
			{
				ReturningProjectiles[i].SetActorLocation(NewLocation);
			}
		}

		// Nothing more can come out of this
		if(UsedAmmo >= AmmoCount 
			&& ActiveProjectiles.Num() == 0 
			&& PendingProjectiles.Num() == 0)
		{
			// Todo, send event
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void ValidateOverlaps()
	{
		if(ActiveParentBlob != nullptr)
			return;

		TArray<AActor> Overlaps;
		Trigger.GetOverlappingActors(Overlaps, AParentBlob::StaticClass());
		for(AActor OverlappingActor : Overlaps)
			Trigger.ActorBeginOverlap(OverlappingActor);
	}

	UFUNCTION(NotBlueprintCallable)
	private void EnterTrigger(AHazeActor OtherActor)
	{
		if(ActiveParentBlob != nullptr)
			return;

		auto OverlappingPlayer = Cast<AParentBlob>(OtherActor);
		if(OverlappingPlayer != nullptr)
		{
			ActiveParentBlob = OverlappingPlayer;
			AddAmmoContainer(this, OverlappingPlayer);
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitTrigger(AHazeActor OtherActor)
	{
		if(ActiveParentBlob == nullptr)
			return;

		auto OverlappingPlayer = Cast<AParentBlob>(OtherActor);
		if(OverlappingPlayer != nullptr)
		{
			ActiveParentBlob = nullptr;
			RemoveAmmoContainer(this, OverlappingPlayer);
		}
	}

	void TakeProjectile(AHazePlayerCharacter Player, UObject FunctionHolder, FName FunctionName)
	{
		// TODO, this needs to be validated in network
		
		if(!bUseInfiniteAmmo)
			UsedAmmo++;

		auto Projectile = Cast<AParentBlobShootingProjectile>(SpawnActor(ProjectileClass, GetActorLocation(), Level = Player.GetLevel()));
		PendingProjectiles.Add(Projectile);
		if(Player.IsMay())
		{
			MayCreatedProjetile.BindUFunction(FunctionHolder, FunctionName);
			MayCreatedProjetile.ExecuteIfBound(Projectile);
		}
		else
		{

			CodyCreatedProjetile.BindUFunction(FunctionHolder, FunctionName);
			CodyCreatedProjetile.ExecuteIfBound(Projectile);
		}
	}

	bool Launch(AParentBlobShootingProjectile Projectile, AHazePlayerCharacter ShootingPlayer, AParentBlob ShootingBlob)
	{
		PendingProjectiles.RemoveSwap(Projectile);

		// This projectile cant be launched
		auto TargetComponent = GetShootAtTarget();

		if(!Projectile.IsFullyCharged() || TargetComponent == nullptr)
		{
			UsedAmmo--;
			ReturningProjectiles.Add(Projectile);
			return false;
		}
		
		// Calculate the trajectory for the projectile
		FVector ShootAtLocation = TargetComponent.GetWorldLocation();

		const FOutCalculateVelocity TrajectoryData = CalculateParamsForPathWithHeight(
			Projectile.GetActorLocation(), 
			ShootAtLocation, 
			_GravityMagnitude = ProjectileGravity, 
			Height = ProjectileArcHeight);

		Projectile.CurrentVelocity = TrajectoryData.Velocity;
		Projectile.TimeToTarget = TrajectoryData.Time;

		FParentBlobAmmoContainerActiveProjectileData NewData;
		NewData.Projectile = Projectile;
		NewData.ShootingParentBlob = ShootingBlob;
		NewData.ShootingPlayer = ShootingPlayer;
		NewData.Target = TargetComponent;
		ActiveProjectiles.Add(NewData);
		return true;
	}

	int GetRemainingAmmo() const
	{
		return AmmoCount - UsedAmmo;
	}
}