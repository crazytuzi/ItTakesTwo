import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

UCLASS(Abstract)
class ACollapsingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	float TimeUntilCollapse = 2.f;

	bool bCollapsing = false;

	UPROPERTY(NotEditable, NotVisible)
	TArray<UStaticMeshComponent> PlatformShards;

	UPROPERTY(NotEditable, NotVisible)
	TArray<FTransform> DefaultTransforms;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"SteppedOn");
		BindOnDownImpacted(this, ImpactDelegate);

		GetComponentsByClass(PlatformShards);

		for (UStaticMeshComponent CurMeshComp : PlatformShards)
		{
			DefaultTransforms.Add(CurMeshComp.WorldTransform);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void SteppedOn(AHazeActor Actor, FHitResult Hit)
	{
		if (bCollapsing)
			return;

		bCollapsing = true;

		System::SetTimer(this, n"Collapse", TimeUntilCollapse, false);

		BP_SteppedOn();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SteppedOn() {}

	UFUNCTION(NotBlueprintCallable)
	void Collapse()
	{	
		for (UStaticMeshComponent CurMeshComp : PlatformShards)
		{
			CurMeshComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
			CurMeshComp.SetSimulatePhysics(true);
			CurMeshComp.AddRadialImpulse(ActorLocation + FVector(0.f, 0.f, 500.f), 1000.f, 1000.f, ERadialImpulseFalloff::RIF_Constant, true);
		}

		System::SetTimer(this, n"Reset", 3.f, false);

		BP_Collapse();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Collapse() {}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		int i = 0;
		for (UStaticMeshComponent CurMeshComp : PlatformShards)
		{
			CurMeshComp.AttachToComponent(PlatformRoot);
			CurMeshComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
			CurMeshComp.SetSimulatePhysics(false);
			CurMeshComp.SetWorldTransform(DefaultTransforms[i]);
			i++;
		}

		bCollapsing = false;

		BP_Reset();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Reset() {}
}