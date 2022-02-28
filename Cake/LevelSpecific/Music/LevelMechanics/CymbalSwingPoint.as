import Vino.Movement.Swinging.SwingComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

UCLASS(Abstract)
class ACymbalSwingPoint : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SwingPointMesh;
	default SwingPointMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USwingPointComponent SwingComp;
	default SwingComp.ValidationType = EHazeActivationPointActivatorType::None;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShieldRoot1;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShieldRoot2;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShieldRoot3;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShieldRoot4;

	UPROPERTY(DefaultComponent, Attach = ShieldRoot1)
	UStaticMeshComponent Shield1;
	default Shield1.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = ShieldRoot2)
	UStaticMeshComponent Shield2;
	default Shield2.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = ShieldRoot3)
	UStaticMeshComponent Shield3;
	default Shield3.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = ShieldRoot4)
	UStaticMeshComponent Shield4;
	default Shield4.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	UAutoAimTargetComponent AutoAimTarget;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	USphereComponent SphereCollision;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 128.0f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CymbalHitAudioEvent;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation = FVector(0.f, 0.f, 500.f);

	UPROPERTY()
	float ActiveTime = 4.f;
	
	bool bActive = false;
	float CurTime = 0.f;

	float CurShieldRot = 0.f;
	float TargetShieldRot = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		SwingComp.ChangeValidActivator(EHazeActivationPointActivatorType::Both);
		TargetShieldRot = 90.f;
		bActive = true;
		UHazeAkComponent::HazePostEventFireForget(CymbalHitAudioEvent, this.GetActorTransform());
		CymbalImpactComp.SetCymbalImpactEnabled(false);
	}

	void DeactivateSwingPoint()
	{
		SwingComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		TargetShieldRot = 0.f;
		bActive = false;
		CurTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
			CurTime += DeltaTime;
			if (CurTime >= ActiveTime)
				DeactivateSwingPoint();
		}

		CurShieldRot = FMath::FInterpConstantTo(CurShieldRot, TargetShieldRot, DeltaTime, 300.f);
		ShieldRoot1.SetRelativeRotation(FRotator(CurShieldRot, 0.f, 0.f));
		ShieldRoot2.SetRelativeRotation(FRotator(0.f, 0.f, -CurShieldRot));
		ShieldRoot3.SetRelativeRotation(FRotator(-CurShieldRot, 0.f, 0.f));
		ShieldRoot4.SetRelativeRotation(FRotator(0.f, 0.f, CurShieldRot));
	}
}