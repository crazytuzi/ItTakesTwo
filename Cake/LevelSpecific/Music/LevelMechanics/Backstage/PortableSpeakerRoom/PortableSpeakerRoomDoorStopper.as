import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

class APortableSpeakerRoomDoorStopper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	bool bHasBeenHit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");
		CymbalImpactComp.OnCymbalRemoved.AddUFunction(this, n"CymbalRemoved");
	}	

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		bHasBeenHit = true;
	}

	UFUNCTION()
	void CymbalRemoved()
	{
		bHasBeenHit = false;
	}
}