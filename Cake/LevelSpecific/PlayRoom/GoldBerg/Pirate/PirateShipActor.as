import Vino.Trajectory.TrajectoryStatics;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.ShootPirateCannonBallsComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBabyComponent;
import Cake.Environment.BreakableComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateEnemyComponent;
import Vino.PointOfInterest.PointOfInterestComponent;

event void FOnPirateShipExploded(APirateShipActor Ship);
event void FOnPirateShipActivated();

UCLASS(Abstract)
class APirateShipActor : AHazeActor
{
//Actor Components
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BoatRoot;

	UPROPERTY(DefaultComponent, Attach = BoatRoot)
	UBreakableComponent BreakableBoat;

	UPROPERTY(DefaultComponent, Attach = BoatRoot)
	UStaticMeshComponent CannonMesh;
	
	UPROPERTY(DefaultComponent, Attach = CannonMesh)
	USceneComponent CannonShootFromPosition;

	UPROPERTY(DefaultComponent)
	UCannonBallDamageableComponent CannonBallDamageableComponent;

	UPROPERTY(DefaultComponent)
	UShootPirateCannonBallsComponent ShootPirateCannonBallsComponent;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent, Attach = BoatRoot)
	UHazeOffsetComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UHazeSkeletalMeshComponentBase OctopusMesh;

	UPROPERTY(DefaultComponent)
	UOctopusBabyComponent OctopusBabyComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent AkComponent;
	
	UPROPERTY(DefaultComponent)
	UPirateEnemyComponent EnemyComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent DetectionCollider;
	default DetectionCollider.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PirateShipFireEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PirateShipDestroyEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MovementStart;

	UPROPERTY(Category = "Events")
	FOnPirateShipExploded OnPirateShipExploded;

	UPROPERTY(Category = "Events")
	FOnPirateShipActivated OnPirateShipActivated;

	UPROPERTY(EditInstanceOnly)
	UHazeSplineComponent SplineToFollow;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	float Speed = 700;

	bool bActivated = false;
	int32 MovementEventID;
	TArray<UCannonBallDamageableComponent> AttachedDamageableComps;	

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem OctopusExplodeEffect;

	UPROPERTY(EditDefaultsOnly)
	float BreakAfterExplosionDelay = 0.4f;
	UPROPERTY(EditDefaultsOnly)
	float OctopusExplodeAfterBreakDelay = 0.4f;
	UPROPERTY(EditDefaultsOnly)
	float CannonRotationSpeed = 4.f;

	bool bStartWithOctopusMH = true;
	bool bHasExploded = false;
	bool bReturnToMHAfterShooting = false;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		EnemyComponent.AddBeginOverlap(DetectionCollider, this, n"EnterDetection");
		EnemyComponent.AddEndOverlap(DetectionCollider, this, n"ExitDetection");
	}	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AkComponent.SetStopWhenOwnerDestroyed(false);
		CannonBallDamageableComponent.HealthWidgetAttachComponent = BoatRoot;

		ShootPirateCannonBallsComponent.SpawnLocationComponent = CannonShootFromPosition;

		OctopusBabyComp.SkeletalMesh = OctopusMesh;

		if(bStartWithOctopusMH)
			OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::MH);
		else
			OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::Float);		

		EnemyComponent.RotationRoot = OctopusMesh;

		BlockCapabilities(n"PirateEnemy", this);
		DetectionCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bActivated)
			return;

		if(CannonMesh.StaticMesh != nullptr && !bHasExploded)
		{
			if(ShootPirateCannonBallsComponent.bShooting || EnemyComponent.bAlerted)
			{
				FVector DirectionToBoat =  EnemyComponent.WheelBoat.ActorLocation - CannonMesh.WorldLocation;
				DirectionToBoat.Normalize();

				FRotator NewRotation = FMath::RInterpTo(CannonMesh.WorldRotation, DirectionToBoat.Rotation(), DeltaTime, CannonRotationSpeed);

				CannonMesh.SetWorldRotation(FRotator(0, NewRotation.Yaw, 0));
			}
		}

		if(!ShootPirateCannonBallsComponent.bShooting && bReturnToMHAfterShooting && !EnemyComponent.bAlerted)
		{
			bReturnToMHAfterShooting = false;
			NetSetDetected(false);
		}

		OctopusBabyComp.UpdateAnimation(DeltaTime);
	}

	UFUNCTION()
    void OnShipExploded()
    {
		DeactivateBoat();

		bHasExploded = true;
		OnPirateShipExploded.Broadcast(this);

		AkComponent.HazePostEvent(PirateShipDestroyEvent);
		AkGameplay::ExecuteActionOnPlayingID(AkActionOnEventType::Stop, MovementEventID, 500.f);

		BlockCapabilities(n"PirateCannonCapability", this);
		System::SetTimer(this, n"BreakShip", BreakAfterExplosionDelay, false);
    }

	UFUNCTION()
	void DeactivateBoat()
	{			
		bActivated = false;

		CannonBallDamageableComponent.OnExploded.Clear();
		ShootPirateCannonBallsComponent.OnCannonBallsLaunched.Clear();
		DetectionCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		SetActorEnableCollision(false);
		BlockCapabilities(n"PirateEnemy", this);
	}

	AWheelBoatActor GetWheelBoat()const property
	{
		return EnemyComponent.WheelBoat;
	}

	UFUNCTION()
    void BreakShip()
    {
		FBreakableHitData HitData;
		BreakableBoat.BreakWithDefault(HitData);

		if(CannonMesh.StaticMesh != nullptr)
		{
			CannonMesh.SetHiddenInGame(true, false);
		}
		
		System::SetTimer(this, n"ExplodeOctopus", OctopusExplodeAfterBreakDelay, false);
		System::SetTimer(this, n"DestroyShipActor", BreakableBoat.BreakablePreset.ChunkFadeTime, false);
    }

	UFUNCTION()
	void DestroyShipActor()
	{
		DestroyActor();
	}

	UFUNCTION()
	void ExplodeOctopus()
	{
		OctopusMesh.SetHiddenInGame(true, false);
		Niagara::SpawnSystemAtLocation(OctopusExplodeEffect, OctopusMesh.WorldLocation);
	}

	UFUNCTION()
    void PlayAttackAnimation(FVector SpawnLocation, FRotator SpawnRotation, APirateCannonBallActor CannonBall)
    {
		OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::Attack);
    }

	UFUNCTION()
    void PlayFireAudioEvent(FVector SpawnLocation,  FRotator SpawnRotation, APirateCannonBallActor CannonBall)
    {
		AkGameplay::PostEventAtLocation(PirateShipFireEvent, SpawnLocation, SpawnRotation, "");
    }

	UFUNCTION()
	void ActivatePirateShip()
	{
		bActivated = true;

		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"OnShipExploded");
		ShootPirateCannonBallsComponent.OnCannonBallsLaunched.AddUFunction(this, n"PlayFireAudioEvent");
		ShootPirateCannonBallsComponent.OnCannonBallsLaunched.AddUFunction(this, n"PlayAttackAnimation");

		SetActorEnableCollision(true);
		UnblockCapabilities(n"PirateEnemy", this);
		DetectionCollider.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		OnPirateShipActivated.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	protected void EnterDetection(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		if(!Boat.HasControl())
			return;

		if(EnemyComponent.bAlerted)
			return;
			
		NetSetDetected(true);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void ExitDetection(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		if(!HasControl())
			return;

		if(!EnemyComponent.bAlerted)
			return;
					
		NetSetDetected(false);
	}

	UFUNCTION(NetFunction)
	void NetSetDetected(bool bStatus)
	{
		EnemyComponent.bAlerted = bStatus;

		if(ShootPirateCannonBallsComponent.bShooting && !bStatus)
		{
			bReturnToMHAfterShooting = true;
			return;
		}

		if(bStatus && bReturnToMHAfterShooting)
			bReturnToMHAfterShooting = false;	

		if(bStatus)
		{
			OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::Alerted);
			EnemyComponent.bFacePlayer = true;
		}
		else
		{
			if(bStartWithOctopusMH)
				OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::MH);
			else
				OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::Float);	

			EnemyComponent.bFacePlayer = false;
		}
	}
}