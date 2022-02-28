import Vino.Camera.Components.WorldCameraShakeComponent;
event void FOnDisableIceBall(AIceCannonBall IceBall);
event void FOnIceBallExploded();

UCLASS(Abstract)
class AIceCannonBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExplodeAudioEvent;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SnowExplosionSystemComp;
	default SnowExplosionSystemComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UWorldCameraShakeComponent CamShakeComp;

	FOnDisableIceBall OnDisableIceBallEvent;

	FOnIceBallExploded OnIceBallExplodedEvent;

	private FVector ShootDirection;
	private FVector ShootDistance = 6500.f;

	private FVector A;
	private FVector B;
	private FVector ControlPoint;

	bool bInitiated;

	float MoveAlphaSpeed;
	float DefaultMoveAlphaSpeed = 1.1f;
	float Drag = 0.2f;
	float MoveAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SnowExplosionSystemComp.SetActive(false);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bInitiated)
			return;

		if (MoveAlpha < 1.f)
		{
			MoveAlpha += MoveAlphaSpeed * DeltaTime;
			MoveAlphaSpeed -= MoveAlphaSpeed * Drag * DeltaTime;
			FVector NextLoc = Math::GetPointOnQuadraticBezierCurve(A, ControlPoint, B, MoveAlpha);
			SetActorLocation(NextLoc);
		}
		else
		{
			SetActorLocation(B);
			Explode();
		}
	}

	void InitiateIceCannonBall(FVector Origin, FVector Direction)
	{
		ShootDirection = Direction;
		SetActorLocation(Origin);

		A = ActorLocation;
		B = ActorLocation + (ShootDirection * ShootDistance) + FVector(0.f, 0.f, -1450.f);
		ControlPoint = (A + B) * 0.5f;
		ControlPoint += ShootDirection * 200.f;
		ControlPoint += FVector (0.f, 0.f, 1850.f);
		bInitiated = true;
		MoveAlpha = 0.f;
		SetActorLocation(A);

		MeshComp.SetHiddenInGame(false);

		MoveAlphaSpeed = DefaultMoveAlphaSpeed;
	}

	void Explode()
	{
		SnowExplosionSystemComp.SetActive(true);
		SnowExplosionSystemComp.SetNiagaraVariableLinearColor("Color", FLinearColor::White);
		SnowExplosionSystemComp.Activate(true);

		bInitiated = false;
		OnIceBallExplodedEvent.Broadcast();
		MeshComp.SetHiddenInGame(true);

		System::SetTimer(this, n"DelayedDisable", 10.f, false);

		UHazeAkComponent::HazePostEventFireForget(ExplodeAudioEvent, GetActorTransform());

		CamShakeComp.Play();
		ForceFeedbackComp.Play();
	}

	UFUNCTION()
	void DelayedDisable()
	{
		OnDisableIceBallEvent.Broadcast(this);
	}
}