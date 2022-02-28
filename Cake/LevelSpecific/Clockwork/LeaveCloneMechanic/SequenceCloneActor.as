import Vino.Trajectory.TrajectoryDrawer;

struct FVelocityClone
{
	UHazeSkeletalMeshComponentBase Mesh;
	UMaterialInstanceDynamic Material;
	float Position = -1.f;
	FVector FromVelocity;
};

class ASequenceCloneActor : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ActiveEffectComp;
	default ActiveEffectComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent)
    UStaticMeshComponent ArrowMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UMaterialInterface CloneMaterial;

	UPROPERTY()
	UNiagaraSystem SpawnEffect;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		for (int i = 0, MaterialCount = Mesh.GetNumMaterials(); i < MaterialCount; ++i)
			Mesh.SetMaterial(i, CloneMaterial);
		Mesh.bNoSkeletonUpdate = true;
    }

    UFUNCTION()
    void InitializeSequenceClone(USkeletalMeshComponent NewMesh)
    {
		Mesh.SetHiddenInGame(false);
		ActiveEffectComp.Activate(true);
		Niagara::SpawnSystemAtLocation(SpawnEffect, ActorLocation + FVector(0.f, 0.f, 88.f));
    }
}