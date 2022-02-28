import Cake.Environment.Breakable;
import Cake.Environment.BreakableStatics;
class ABreakableSoundFoam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;
	default Mesh01.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh02;
	default Mesh02.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	ABreakableActor BreakableActor01;

	UPROPERTY()
	ABreakableActor BreakableActor02;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BreakableActor01.SetActorHiddenInGame(true);
		BreakableActor02.SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void BreakActor()
	{
		BreakableActor01.SetActorHiddenInGame(false);
		BreakableActor02.SetActorHiddenInGame(false);
		Mesh01.SetHiddenInGame(true);
		Mesh02.SetHiddenInGame(true);
		FBreakableHitData HitData;
		HitData.DirectionalForce = FVector(0.f, 0.f, 10.f);
		HitData.HitLocation = GetActorLocation();
		HitData.ScatterForce = 35.f;
		BreakBreakableActor(BreakableActor01, HitData);
		BreakBreakableActor(BreakableActor02, HitData);
	}
}