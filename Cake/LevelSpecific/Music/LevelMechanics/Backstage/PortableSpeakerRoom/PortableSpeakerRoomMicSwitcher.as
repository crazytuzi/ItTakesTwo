import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

class PortableSpeakerRoomMicSwitcher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LampMesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LampMesh02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	bool bHasBeenSwitched = false;

	FVector GreenColor = FVector(0.999f, 30.f, 0.f);
	FVector RedColor = FVector(30.f, 0.999f, 0.f);

	FHazeTimeLike Time;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"OnCymbalHit");
		
		LampMesh01.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", GreenColor);
		LampMesh02.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", RedColor);
	}

	UFUNCTION()
	void OnCymbalHit(FCymbalHitInfo HitInfo)
	{
		bHasBeenSwitched = !bHasBeenSwitched;

		LampMesh01.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", bHasBeenSwitched ? RedColor : GreenColor);
		LampMesh02.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", bHasBeenSwitched ? GreenColor : RedColor);
	}
}