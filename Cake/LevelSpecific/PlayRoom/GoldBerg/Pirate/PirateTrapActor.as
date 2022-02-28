import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatCameraShakeComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatAvoidPointComponent;

event void FOnPirateTrapExploded();

UCLASS(Abstract)
class APirateTrapActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapCollider;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent, Attach = RightRoot)
	USceneComponent RightExplosionPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = LeftRoot)
	USceneComponent LeftExplosionPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent OctoExplosionPoint1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent OctoExplosionPoint2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent OctoExplosionPoint3;

	UPROPERTY(DefaultComponent)
	UCannonBallDamageableComponent CannonBallDamageableComponent;
	default CannonBallDamageableComponent.bDestroyAfterExploding = false;

	UPROPERTY(DefaultComponent)
	UWheelBoatCameraShakeComponent WheelBoatCamShakeComp;

	UPROPERTY(DefaultComponent)
	UWheelBoatAvoidPointComponent WheelBoatAvoidPointComp;
	default WheelBoatAvoidPointComp.bIsActive = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PirateTrapExplosionAudioEvent;

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;
	
	UPROPERTY()
	UNiagaraSystem OctoExplosionEffect;

	UPROPERTY()
	FOnPirateTrapExploded OnPirateTrapExploded;

	float DamageAmount = 3.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"OnShotByBoat");
		OverlapCollider.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		HazeAkComp.SetStopWhenOwnerDestroyed(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AWheelBoatActor Boat = Cast<AWheelBoatActor>(OtherActor);

		if (Boat == nullptr)
			return;

		ExplodeTrap(Boat);
		//NetBoatEnteredDetection(Boat);
	}

	UFUNCTION()
	void OnShotByBoat()
	{
		ExplodeTrap(nullptr);
	}

	UFUNCTION(BlueprintEvent)
	void ExplodeTrap(AWheelBoatActor Boat)
	{
		if(Boat != nullptr)
			Boat.BoatWasHit(DamageAmount, EWheelBoatHitType::CannonBall);

		Niagara::SpawnSystemAtLocation(ExplosionEffect, RightExplosionPoint.WorldLocation, LeftExplosionPoint.WorldRotation);
		Niagara::SpawnSystemAtLocation(ExplosionEffect, LeftExplosionPoint.WorldLocation, LeftExplosionPoint.WorldRotation);

		Niagara::SpawnSystemAtLocation(OctoExplosionEffect, OctoExplosionPoint1.WorldLocation, OctoExplosionPoint1.WorldRotation);
		Niagara::SpawnSystemAtLocation(OctoExplosionEffect, OctoExplosionPoint2.WorldLocation, OctoExplosionPoint2.WorldRotation);
		Niagara::SpawnSystemAtLocation(OctoExplosionEffect, OctoExplosionPoint3.WorldLocation, OctoExplosionPoint3.WorldRotation);

		HazeAkComp.HazePostEvent(PirateTrapExplosionAudioEvent);
		
		WheelBoatCamShakeComp.CameraReaction();
		WheelBoatAvoidPointComp.ActivateAvoidPoint(1.5f, 4500.f, 6000.f);
		
		OnPirateTrapExploded.Broadcast();
		DisableActor(this);
	}
}