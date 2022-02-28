import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.Environment.BreakableComponent;
import Cake.Environment.BreakableStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

import void ReturnPowerfulSongProjectile(AHazeActor, APowerfulSongProjectile) from "Cake.LevelSpecific.Music.Singing.SingingComponent";
import Cake.LevelSpecific.Music.MusicWeaponTargetingComponent;

event void FPowerfulSongProjectileImpactDelegate(APowerfulSongProjectile Projectile, AActor HitActor);

struct FPowerfulSongProjectileDebugHit
{
	AActor HitTarget;
	FVector StartLocation;
	FVector EndLocation;
	FVector BoxExtent;
	FVector Origin;
	float Elapsed = 2.0f;
}

UCLASS(Abstract)
class APowerfulSongProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::High;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent Direction;

	UPROPERTY(DefaultComponent)
	UMusicWeaponTargetingComponent TargetingComponent;

	bool bActive = false;

	FVector StartLocation;
	float MaxDistance = 2500.f;
	float Speed = 8000.f;

	UPROPERTY(Category = Movement)
	float MovementSpeed = 8000.0f;

	float MovementDistanceModifier = 500.0f;

	UPROPERTY()
	FVector BoxHalfSize = FVector(50, 50, 50);

	AActor TargetActor = nullptr;
	USceneComponent TargetComponent = nullptr;

	// Song user associated with this projectile.
	AActor OwnerActor = nullptr;

	FTimerHandle HideTimerHandle;

	AHazePlayerCharacter OwnerPlayer;

	TArray<FPowerfulSongProjectileDebugHit> DebugHitCollection;

	//UPROPERTY()
	//FPowerfulSongProjectileImpactDelegate OnImpact;

	UAkAudioEvent AttachedPowerfulSongEvent;
	UAkAudioEvent AttachedPowerfulSongEchoEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent PowerfulSongBlastEchoEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent PowerfulSongScreamEchoEvent;

	float TimeToReachTarget = 0;

	void InitCapabilities()
	{
		AddCapability(n"PowerfulSongProjectileSeekCapability");
		AddCapability(n"PowerfulSongProjectileMovementCapability");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		System::ClearAndInvalidateTimerHandle(HideTimerHandle);
	}

	void OnShootProjectile(FVector InStartLocation, FVector FacingDirection, float Range)
	{
		SetActorLocationAndRotation(InStartLocation, FacingDirection.Rotation());
		BP_OnProjectileShow();
		System::ClearAndInvalidateTimerHandle(HideTimerHandle);
		//SetActorHiddenInGame(false);
		MaxDistance = Range;
		StartLocation = InStartLocation;
		bActive = true;
	}

	// When the projectile has hit something or it has moved its maximum allowed distance.
	void ProjectileLifetimeExpired()
	{
		bActive = false;
		UHazeAkComponent ProjectileHazeAkComp = UHazeAkComponent::Get(this);
		if(ProjectileHazeAkComp != nullptr)
		{
			ProjectileHazeAkComp.HazePostEvent(AttachedPowerfulSongEchoEvent);
			ProjectileHazeAkComp.HazePostEvent(PowerfulSongBlastEchoEvent);
			ProjectileHazeAkComp.HazePostEvent(PowerfulSongScreamEchoEvent);
		}

		BP_OnProjectileDestroyed();
		HideTimerHandle = System::SetTimer(this, n"HandleHideTimerDone", 2.0f, false);
		ReturnPowerfulSongProjectile(OwnerPlayer, this);
	}

	// Used for debug purposes, drawing hits etc
	void AddDebugHit(AActor HitTarget)
	{
#if !RELEASE
		if(HitTarget == nullptr)
			return;

		FPowerfulSongProjectileDebugHit DebugHit;
		DebugHit.HitTarget = HitTarget;
		DebugHit.StartLocation = StartLocation;
		DebugHit.EndLocation = ActorCenterLocation;
		HitTarget.GetActorBounds(false, DebugHit.Origin, DebugHit.BoxExtent);
		DebugHitCollection.Add(DebugHit);
#endif // !RELEASE
	}

#if !RELEASE
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateDebugHits(DeltaTime);
	}
#endif // !RELEASE

	private void UpdateDebugHits(float DeltaTime)
	{
		for(int Index = DebugHitCollection.Num() - 1; Index >= 0; --Index)
		{
			FPowerfulSongProjectileDebugHit& DebugHit = DebugHitCollection[Index];
			DebugHit.Elapsed -= DeltaTime;

			if(DebugHit.Elapsed < 0.0f)
			{
				DebugHitCollection.RemoveAt(Index);
			}
		}
	}

	void DrawDebugHits(float Duration = 0.0f) const
	{
		for(FPowerfulSongProjectileDebugHit DebugHit : DebugHitCollection)
		{
			System::DrawDebugLine(DebugHit.StartLocation, DebugHit.EndLocation, FLinearColor::Green, Duration, 15);
			System::DrawDebugBox(DebugHit.Origin, DebugHit.BoxExtent * 1.2f, FLinearColor::Blue, FRotator::ZeroRotator, Duration, 30);
		}
	}

	UFUNCTION()
	void HandleHideTimerDone()
	{
		BP_OnProjectileHide();
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Projectile Show"))
	void BP_OnProjectileShow() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Projectile Hide"))
	void BP_OnProjectileHide() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Projectile Lifetime Expired"))
	void BP_OnProjectileDestroyed() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Projectile Bounce"))
	void BP_OnProjectileBounce() {}
}
