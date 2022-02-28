import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

event void FOnCymbalAttached();
event void FOnCymbalDetached();

UCLASS(Abstract)
class ACymbalReceptacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ReceptacleMesh;
	default ReceptacleMesh.bGenerateOverlapEvents = false;
	default ReceptacleMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	USphereComponent SphereCollision;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 128.0f;

	UPROPERTY()
	FOnCymbalAttached OnCymbalAttached;

	UPROPERTY()
	FOnCymbalDetached OnCymbalDetached;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalImpact");
	}

	UFUNCTION(NotBlueprintCallable)
	void CymbalImpact(FCymbalHitInfo HitInfo)
	{
		BP_CymbalImpact();
		OnCymbalAttached.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_CymbalImpact()
	{}

	UFUNCTION(NotBlueprintCallable)
	void CymbalRemoved()
	{
		BP_CymbalRemoved();
		OnCymbalDetached.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_CymbalRemoved()
	{}
}