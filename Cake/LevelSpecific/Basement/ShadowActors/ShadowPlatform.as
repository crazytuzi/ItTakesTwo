import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

UCLASS(Abstract)
class AShadowPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	float DespawnTime = 2.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"Impacted");
		BindOnDownImpacted(this, ImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void Impacted(AHazeActor Actor, FHitResult Hit)
	{
		// System::SetTimer(this, n"DespawnPlatform", DespawnTime, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void DespawnPlatform()
	{
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
	}
}