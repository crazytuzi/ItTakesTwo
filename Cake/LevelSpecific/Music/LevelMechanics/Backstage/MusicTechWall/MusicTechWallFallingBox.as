import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

class AMusicTechWallFallingBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BoxMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CableMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CymbalTargetMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent CymbalTargetComp;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	UAutoAimComponent AutoAimComp;

	UPROPERTY()
	FHazeTimeLike DropBoxTimeline;

	bool bHasBeenDropped = false;
	
	FVector StartLocation = FVector::ZeroVector;
	FVector TargetLocation = FVector(0.f, 0.f, -1700.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");
		DropBoxTimeline.BindUpdate(this, n"DropBoxTimelineUpdate");
	}

	UFUNCTION()
	void DropBox()
	{
		if (bHasBeenDropped)
			return;

		bHasBeenDropped = true;
		CableMesh.SetHiddenInGame(true);
		CymbalTargetMesh.SetHiddenInGame(true);
		DropBoxTimeline.Play(); 
	}

	UFUNCTION()
	void DropBoxTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLocation, TargetLocation, CurrentValue));
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		if (HitInfo.HitComponent == CymbalTargetComp)
		{
			DropBox();
		}
	}
}