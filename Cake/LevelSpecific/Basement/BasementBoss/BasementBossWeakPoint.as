import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonMash.ParentBlobButtonMashComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonMash.ParentBlobButtonMashStatics;

event void FOnBasementBossWeakPointDestroyed(ABasementBossWeakPoint WeakPoint);

UCLASS(Abstract)
class ABasementBossWeakPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WeakPointRoot;

	UPROPERTY(DefaultComponent, Attach = WeakPointRoot)
	UStaticMeshComponent WeakPointMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USpotLightComponent SpotLight;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent PlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = WeakPointRoot)
	UNiagaraComponent ExplosionEffectComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent LightTrailEffectComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent MashStandTransform;

	UPROPERTY()
	AActor Target;

	UPROPERTY()
	FOnBasementBossWeakPointDestroyed OnWeakPointDestroyed;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike HoverTimeLike;

	UPROPERTY()
	bool bActiveFromStart = false;
	bool bActive = false;

	bool bWeakPointDestroyed = false;
	bool bLightTrailReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		PlayerTrigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");

		HoverTimeLike.BindUpdate(this, n"UpdateHover");
		HoverTimeLike.PlayFromStart();

		if (!bActiveFromStart)
			SetActorHiddenInGame(true);
		else
			bActive = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateHover(float CurValue)
	{
		float CurOffset = FMath::Lerp(50.f, 100.f, CurValue);
		WeakPointRoot.SetRelativeLocation(FVector(0.f, 0.f, CurOffset));
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (bWeakPointDestroyed)
			return;

		if (!bActive)
			return;

		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		StartParentBlobButtonMashInteraction(MashStandTransform.WorldTransform);

		FParentBlobButtonMashCompletedDelegate ButtonMashCompletedDelegate;
		ButtonMashCompletedDelegate.BindUFunction(this, n"DestroyWeakPoint");
		BindOnParentBlobButtonMashCompleted(this, ButtonMashCompletedDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (bWeakPointDestroyed)
			return;

		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		StopParentBlobButtonMash();
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bLightTrailReachedEnd)
			return;

		if (bWeakPointDestroyed)
		{
			if (Target != nullptr)
			{
				FVector LightTrailLoc = FMath::VInterpConstantTo(LightTrailEffectComp.WorldLocation, Target.ActorLocation, DeltaTime, 9000.f);
				LightTrailEffectComp.SetWorldLocation(LightTrailLoc);
				if (LightTrailLoc == Target.ActorLocation)
				{
					LightTrailEffectComp.Deactivate();
					bLightTrailReachedEnd = true;
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void DestroyWeakPoint()
	{
		StopParentBlobButtonMash();
		bWeakPointDestroyed = true;
		WeakPointMesh.SetHiddenInGame(true);
		ExplosionEffectComp.Activate(true);
		LightTrailEffectComp.Activate();
		OnWeakPointDestroyed.Broadcast(this);
		SetActorEnableCollision(false);
	}

	UFUNCTION()
	void ActivateWeakPoint()
	{
		bActive = true;
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void DeactivateWeakPoint()
	{
		bActive = false;
		SetActorHiddenInGame(true);
	}
}