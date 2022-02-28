import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.ShootPirateCannonBallsComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBabyComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateEnemyComponent;
import Peanuts.Audio.AudioStatics;

UCLASS(Abstract)
class AStaticCannonEnemyActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CannonMesh;

	UPROPERTY(DefaultComponent, Attach = CannonMesh)
	USceneComponent CannonShootFromPosition;

	UPROPERTY(DefaultComponent, Attach = CannonMesh)
	UArrowComponent CannonForward;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent AkComponent;

	UPROPERTY(DefaultComponent)
	UPirateEnemyComponent EnemyComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent DetectionCollider;
	default DetectionCollider.bGenerateOverlapEvents = false;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StaticCannonEnemyFireEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StaticCannonEnemyDestroyEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OctopusScreamAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ExplosionAudioEvent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase OctopusMesh;

	UPROPERTY(DefaultComponent)
	UCannonBallDamageableComponent CannonBallDamageableComponent;

	UPROPERTY(DefaultComponent)
	UShootPirateCannonBallsComponent ShootPirateCannonBallsComponent;

	UPROPERTY(DefaultComponent)
	UOctopusBabyComponent OctopusBabyComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000.f;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem OctopusExplodeEffect;

	UPROPERTY()
	float CannonRotationSpeed = 4.f;

	UPROPERTY(EditInstanceOnly)
	AHazeActor LinkedPlatform;

	bool bExploded = false;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		EnemyComponent.Shapes.Reset(1);
		EnemyComponent.AddBeginOverlap(DetectionCollider, this, n"EnterDetection");
		EnemyComponent.AddEndOverlap(DetectionCollider, this, n"ExitDetection");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"ShootPirateCannonBallsCapability");

		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"PlayDestroyAudioEvent");
		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"OnStaticCannonEnemyExploded");
		ShootPirateCannonBallsComponent.OnCannonBallsLaunched.AddUFunction(this, n"PlayAttackAnimation");
		ShootPirateCannonBallsComponent.OnCannonBallsLaunched.AddUFunction(this, n"PlayFireAudioEvent");
		ShootPirateCannonBallsComponent.SpawnLocationComponent = CannonShootFromPosition;

		OctopusBabyComp.SkeletalMesh = OctopusMesh;
		OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::MH);

		EnemyComponent.RotationRoot = OctopusMesh;

		AkComponent.SetStopWhenOwnerDestroyed(false);

		AddCapability(n"PirateEnemyFaceWheelBoatCapability");
	}

	UFUNCTION(NotBlueprintCallable)
	protected void EnterDetection(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		if(!Boat.HasControl())
			return;

		if(EnemyComponent.bAlerted)
			return;
			
		NetBoatEnteredDetection(Boat);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void ExitDetection(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		if(!HasControl())
			return;

		if(!EnemyComponent.bAlerted)
			return;
					
		NetBoatLeftDetection();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		OctopusBabyComp.UpdateAnimation(DeltaTime);
		if(ShootPirateCannonBallsComponent.bShooting && EnemyComponent.bAlerted && !bExploded)
		{
			FVector DirectionToBoat =  EnemyComponent.WheelBoat.ActorLocation - CannonMesh.WorldLocation;
			DirectionToBoat.Normalize();

			FRotator NewRotation = FMath::RInterpTo(CannonMesh.WorldRotation, DirectionToBoat.Rotation(), DeltaTime, CannonRotationSpeed);

			CannonMesh.SetWorldRotation(FRotator(0, NewRotation.Yaw, 0));
		}
	}
	
	UFUNCTION(NetFunction)
    void NetBoatEnteredDetection(AWheelBoatActor Boat)
    {
		OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::Alerted);
		EnemyComponent.bAlerted = true;
		EnemyComponent.bFacePlayer = true;
    }

	UFUNCTION(NetFunction)
    void NetBoatLeftDetection()
    {
		OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::MH);
		EnemyComponent.bAlerted = false;
		EnemyComponent.bFacePlayer = false;
	}

	UFUNCTION(BlueprintCallable)
    void PlayAttackAnimation(FVector SpawnLocation,  FRotator SpawnRotation, APirateCannonBallActor CannonBall)
    {
		OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::Attack);
    }

	UFUNCTION(BlueprintCallable)
    void OnStaticCannonEnemyExploded()
    {
		Niagara::SpawnSystemAtLocation(OctopusExplodeEffect, OctopusMesh.WorldLocation);
		this.BlockCapabilities(n"PirateEnemy", this);
		CannonMesh.SetVisibility(false);
		OctopusMesh.SetVisibility(false);
       	bExploded = true;
		AkComponent.HazePostEvent(OctopusScreamAudioEvent);
		AkComponent.HazePostEvent(ExplosionAudioEvent);
    }

	UFUNCTION(BlueprintCallable)
    void PlayDestroyAudioEvent()
    {
		AkComponent.HazePostEvent(StaticCannonEnemyDestroyEvent);
    }

	UFUNCTION(BlueprintCallable)
    void PlayFireAudioEvent(FVector SpawnLocation,  FRotator SpawnRotation, APirateCannonBallActor CannonBall)
    {
		AkComponent.HazePostEvent(StaticCannonEnemyFireEvent);
	}
}
